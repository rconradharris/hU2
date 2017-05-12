using Toybox.Application;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi as Ui;

using PropertyStore;


module Hue {
    enum {
        REGISTRATION_FAILED,
        REGISTRATION_WAITING, // For button press
        REGISTRATION_SUCCESS
    }

    hidden const REQUEST_LOGGING = false;
    hidden var mRequestId = 0;

    class _RequestLoggingCallback {
        hidden var mCallback = null;
        hidden var mRequestId = null;

        function initialize(requestId, callback) {
            mRequestId = requestId;
            mCallback = callback;
        }

        function onResponse(responseCode, data) {
            var info = { "responseCode" => responseCode, "data" => data };
            System.println(Lang.format("response $1$: $2$", [mRequestId, info]));
            if (mCallback != null) {
                mCallback.invoke(responseCode, data);
            }
        }
    }

    // Wrapper to allow logging...
    function makeWebRequest(url, params, options, callback) {
        if (REQUEST_LOGGING) {
            var info = { "url" => url, "params" => params };
            System.println(Lang.format("request $1$: $2$", [mRequestId, info]));
            callback = new _RequestLoggingCallback(mRequestId, callback).method(:onResponse);
            mRequestId++;
        }
        Communications.makeWebRequest(url, params, options, callback);
    }

    // Hack to allow us to build a callback closure
    class _DiscoverBridgeCallback {
        hidden var mCallback = null;

        function initialize(callback) {
            mCallback = callback;
        }

        function onResponse(responseCode, data) {
            var bridgeIP = null;
            if (responseCode == 200) {
                if (data has :size && data.size() > 0) {
                    if (data[0] has :hasKey && data[0].hasKey("internalipaddress")) {
                        bridgeIP = data[0]["internalipaddress"];
                    }
                }
            }
            mCallback.invoke(bridgeIP);
        }
    }

    // Hack to allow us to build a callback closure
    class _RegisterCallback {
        hidden var mCallback = null;

        function onResponse(responseCode, data) {
            var status = REGISTRATION_FAILED;

            var username = null;
            if (responseCode == 200) {
                if (data has :size && data.size() > 0) {
                    var payload = data[0];
                    if (payload has :hasKey) {
                        if (payload.hasKey("success")) {
                            status = REGISTRATION_SUCCESS;
                            username = payload["success"]["username"];
                        } else if (payload.hasKey("error")) {
                            if (payload["error"].hasKey("type")) {
                                if (payload["error"]["type"] == 101) {
                                    // Hue responded back saying that button
                                    // was not pressed
                                    status = REGISTRATION_WAITING;
                                }
                            }
                        }
                    }
                }
            } else if (responseCode < 0 && responseCode > -400) {
                // Retry on errors like NETWORK TIMEOUT and various BLE errors
                status = REGISTRATION_WAITING;
            }

            mCallback.invoke(status, username);
        }


        function initialize(callback) {
            mCallback = callback;
        }
    }

    class _FetchCallback {
        hidden var mClient = null;
        hidden var mCallback = null;

        function initialize(client, callback) {
            mClient = client;
            mCallback = callback;
        }

        function onResponse(responseCode, data) {
            var success = false;
            if (responseCode == 200) {
                success = true;

                var lightIds = data.keys();
                var light;
                var keep = {};

                // Add/update lights that are still around
                for (var i=0; i < data.size(); i++) {
                    var lightId = lightIds[i];
                    var ld = data[lightId];

                    light = mClient.getLight(lightId);

                    if (light == null) {
                        light = new Light(lightId, ld["name"]);
                        mClient.addLight(light);
                    }

                    light.updateState(ld["state"]);
                    keep[lightId] = true;
                }

                // Remove any lights that are no longer present
                var lights = mClient.getLights();
                for (var i=0; i < lights.size(); i++) {
                    light = lights[i];
                    if (!keep.hasKey(light.getId())) {
                        mClient.removeLight(light);
                    }
                }

                mClient.saveLights();
            }
            if (mCallback != null) {
                mCallback.invoke(success);
            }
        }
    }

    function discoverBridgeIP(callback) {
            var options = { :method => Communications.HTTP_REQUEST_METHOD_GET,
                            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
                            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON };
            var url = "https://www.meethue.com/api/nupnp";
            var callbackWrapper = new _DiscoverBridgeCallback(callback);
            Hue.makeWebRequest(url, null, options, callbackWrapper.method(:onResponse));
    }


    class Light {
        // Loaded immediately from property store
        hidden var mId = null;
        hidden var mName = null;

        // Loaded sometime after initialization (whenever the Hue API responds back)
        hidden var mState = {};

        hidden var mBusy = false;

        function initialize(id, name) {
            mId = id;
            mName = name;
        }

        function getId() {
            return mId;
        }

        function getName() {
            return mName;
        }

        function toString() {
            return Lang.format("Light(id=$1$, name=$2$)", [mId, mName]);
        }

        function setBusy(busy) {
            mBusy = busy;
        }

        function getBusy() {
            return mBusy;
        }

        function updateState(state) {
            var keys = state.keys();
            for (var i=0; i < state.size(); i++) {
                var key = keys[i];
                var value = state[key];
                mState[key] = value;
            }
        }

        function isStateAvailable() {
            return mState.size() > 0;
        }

        function getOn() {
            return mState["on"];
        }

        function getBrightness() {
            return mState["bri"];
        }

        function getReachable() {
            return mState["reachable"];
        }

    }

    class Bridge {
        hidden var mIPAddress = null;

        function initialize(ipAddress) {
            mIPAddress = ipAddress;
        }

        function doRequest(method, url, params, callback) {
            var options = { :method => method,
                            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
                            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON };
            var fullUrl = Lang.format("http://$1$/api$2$", [mIPAddress, url]);
            Hue.makeWebRequest(fullUrl, params, options, callback);
        }

        function register(callback) {
            doRequest(Communications.HTTP_REQUEST_METHOD_POST, "/",
                      { "devicetype" => "hU2" },
                      new _RegisterCallback(callback).method(:onResponse));
        }

    }

    class Client {
        hidden var mBridge = null;
        hidden var mUsername = null;
        hidden var mLights = {};

        function initialize(bridge, username) {
            mBridge = bridge;
            mUsername = username;

            loadLights();
        }

        hidden function loadLights() {
            var lightIds = PropertyStore.get("lightIds");
            var lightNames = PropertyStore.get("lightNames");
            if (lightIds == null || lightNames == null) {
                return;
            }
            if (lightIds.size() != lightNames.size()) {
                return;
            }
            for (var i=0; i < lightIds.size(); i++) {
                var light = new Light(lightIds[i], lightNames[i]);
                mLights[lightIds[i]] = light;
            }
        }

        function addLight(light) {
            mLights[light.getId()] = light;
        }

        function removeLight(light) {
            mLights.remove(light.getId());
        }

        function getLights() {
            return mLights.values();
        }

        function getLight(lightId) {
            return mLights[lightId];
        }

        function saveLights() {
            var count = mLights.size();

            var lightIds = new [count];
            var lightNames = new [count];
            var lights = mLights.values();

            for (var i=0; i < count; i++) {
                var light = lights[i];
                lightIds[i] = light.getId();
                lightNames[i] = light.getName();
            }

            PropertyStore.set("lightIds", lightIds);
            PropertyStore.set("lightNames", lightNames);
        }

        hidden function doRequest(method, url, params, callback) {
            mBridge.doRequest(method, Lang.format("/$1$$2$", [mUsername, url]), params, callback);
        }

        function sync(callback) {
            var callbackWrapper = new _FetchCallback(self, callback);
            doRequest(Communications.HTTP_REQUEST_METHOD_GET,
                      "/lights", {}, callbackWrapper.method(:onResponse));
        }

        function turnOnAllLights(on) {
            var url = "/groups/0/action";
            var params = { "on" => on };
            doRequest(Communications.HTTP_REQUEST_METHOD_PUT, url, params, null);

            // NOTE: We have no idea whether a group action was successful for
            // any given light; so, just be optimistic and change the state
            var lights = getLights();
            for (var i=0; i < lights.size(); i++) {
                var light = lights[i];
                light.updateState(params);
            }
        }

        function turnOnLight(light, on, callback) {
            changeState(light, { "on" => on }, callback);
        }

        function toggleLight(light, callback) {
            turnOnLight(light, !light.getOn(), callback);
        }

        function setBrightness(light, brightness, callback) {
            if (brightness > 254) {
                brightness = 254;
            } else if (brightness < 0) {
                brightness = 0;
            }
            changeState(light, { "bri" => brightness, "on" => true }, callback);
        }

        // Params:
        //      "on"    : true|false
        //      "bri"   : 0..254
        hidden function changeState(light, params, callback) {
            var callbackWrapper = new _ChangeLightStateCallback(light, params, callback);
            var url = Lang.format("/lights/$1$/state", [light.getId()]);
            doRequest(Communications.HTTP_REQUEST_METHOD_PUT, url, params,
                      callbackWrapper.method(:onResponse));
        }

    }

    class _ChangeLightStateCallback {
        hidden var mLight = null;
        hidden var mParams = null;
        hidden var mCallback = null;

        function initialize(light, params, callback) {
            mLight = light;
            mParams = params;
            mCallback = callback;
        }

        function onResponse(responseCode, data) {
            if (responseCode == 200) {
                var updatedState = {};

                var lightId = mLight.getId();
                var keys = mParams.keys();
                for (var i=0; i < mParams.size(); i++) {
                    var param = keys[i];
                    var url = Lang.format("/lights/$1$/state/$2$", [lightId, param]);

                    for (var j=0; j < data.size(); j++) {
                        var responseItem = data[j];
                        if (responseItem.hasKey("success")) {
                            var stateDict = responseItem["success"];
                            if (stateDict.hasKey(url)) {
                                var updatedValue = stateDict[url];
                                updatedState[param] = updatedValue;
                            }
                        }
                    } // end for each response item
                } // end for each param
                mLight.updateState(updatedState);
            }
            if (mCallback != null) {
                mCallback.invoke();
            }
            Ui.requestUpdate();
        }
    }
}