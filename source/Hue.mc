using Toybox.Application;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi as Ui;

module Hue {

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
                    System.println(data[0]);
                    if (data[0] has :hasKey && data[0].hasKey("internalipaddress")) {
                        System.println(data[0]["internalipaddress"]);
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
            var username = null;
            System.println(responseCode);
            if (responseCode == 200) {
                System.println(data);
                if (data has :size && data.size() > 0) {
                    System.println(data[0]);
                    if (data[0] has :hasKey && data[0].hasKey("success")) {
                        System.println(data[0]["success"]);
                        username = data[0]["success"]["username"];
                    }
                }
            }
            System.println("invoking with username " + username);
            mCallback.invoke(username);
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
                for (var i=0; i < lightIds.size(); i++) {
                    var lightId = lightIds[i];
                    var ld = data[lightId];
                    var light = new Light(lightId, ld["name"], ld["state"]);
                    mClient.addLight(light);
                }
            }
            mCallback.invoke(success);
        }
    }

    function discoverBridgeIP(callback) {
            var options = { :method => Communications.HTTP_REQUEST_METHOD_GET,
                            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
                            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON };
            var url = "https://www.meethue.com/api/nupnp";
            var callbackWrapper = new _DiscoverBridgeCallback(callback);
            Communications.makeWebRequest(url, null, options, callbackWrapper.method(:onResponse));
    }


    class Light {
        hidden var mId = null;
        hidden var mName = null;
        hidden var mState = null;
        hidden var mBusy = false;

        function initialize(id, name, state) {
            mId = id;
            mName = name;
            mState = state;
        }

        function getId() {
            return mId;
        }

        function getName() {
            return mName;
        }

        function updateState(state) {
            var keys = state.keys();
            for (var i=0; i < state.size(); i++) {
                var key = keys[i];
                var value = state[key];
                mState[key] = value;
            }
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

        function setBusy(busy) {
            mBusy = busy;
        }

        function getBusy() {
            return mBusy;
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
            System.println(fullUrl);
            Communications.makeWebRequest(fullUrl, params, options, callback);
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
        }

        hidden function doRequest(method, url, params, callback) {
            mBridge.doRequest(method, Lang.format("/$1$$2$", [mUsername, url]), params, callback);
        }

        function addLight(light) {
            mLights[light.getId()] = light;
        }

        function sync(callback) {
            var callbackWrapper = new _FetchCallback(self, callback);
            doRequest(Communications.HTTP_REQUEST_METHOD_GET,
                      "/lights", {}, callbackWrapper.method(:onResponse));
        }

        function getLights() {
            return mLights.values();
        }

        function getLight(lightId) {
            return mLights[lightId];
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

        function turnOnLight(light, on) {
            changeState(light, null, { "on" => on });
        }

        function toggleLight(light) {
            turnOnLight(light, !light.getOn());
        }

        function setBrightness(light, brightness) {
            if (brightness > 254) {
                brightness = 254;
            } else if (brightness < 0) {
                brightness = 0;
            }
            changeState(light, null, { "bri" => brightness, "on" => true });
        }

        // Params:
        //      "on"    : true|false
        //      "bri"   : 0..254
        hidden function changeState(light, callback, params) {
            Application.getApp().blinkerUp();
            light.setBusy(true);
            var callbackWrapper = new _ChangeLightStateCallback(light, callback, params);
            var url = Lang.format("/lights/$1$/state", [light.getId()]);
            doRequest(Communications.HTTP_REQUEST_METHOD_PUT, url, params,
                      callbackWrapper.method(:onResponse));
        }

    }

    class _ChangeLightStateCallback {
        hidden var mLight = null;
        hidden var mCallback = null;
        hidden var mParams = null;

        function initialize(light, callback, params) {
            mLight = light;
            mCallback = callback;
            mParams = params;
        }

        function onResponse(responseCode, data) {
            Application.getApp().blinkerDown();
            mLight.setBusy(false);
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