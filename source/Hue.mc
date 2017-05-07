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
            System.println(responseCode);
            if (responseCode == 200) {
                System.println(data);
                if (data has :size && data.size() > 0) {
                    System.println(data[0]);
                    if (data[0] has :hasKey && data[0].hasKey("internalipaddress")) {
                        System.println(data[0]["internalipaddress"]);
                        bridgeIP = data[0]["internalipaddress"];
                    }
                }
            }
            System.println("invoking with bridgeIP " + bridgeIP);
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
                    var st = ld["state"];
                    var light = new Light(lightId, ld["name"], st["on"], st["reachable"]);
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
            System.println(url);
            var callbackWrapper = new _DiscoverBridgeCallback(callback);
            Communications.makeWebRequest(url, null, options, callbackWrapper.method(:onResponse));
    }


    class Light {
        hidden var mId = null;
        hidden var mName = null;
        hidden var mOn = null;
        hidden var mReachable = null;

        hidden var mBusy = false;

        function initialize(id, name, on, reachable) {
            mId = id;
            mName = name;
            mOn = on;
            mReachable = reachable;
        }

        function getId() {
            return mId;
        }

        function getName() {
            return mName;
        }

        function getOn() {
            return mOn;
        }

        function getReachable() {
            return mReachable();
        }

        function setBusy(busy) {
            mBusy = busy;
        }

        function getBusy() {
            return mBusy;
        }

        hidden function onTurnOnOff(responseCode, data, on) {
            if (responseCode != 200) {
                // TODO: alert that an error occured
                return;
            }
            Application.getApp().blinkerDown();
            setBusy(false);
            System.println(data);
            if (data[0].hasKey("success")) {
                mOn = on;
            }
            Ui.requestUpdate();
        }

        function onTurnOn(responseCode, data) {
            onTurnOnOff(responseCode, data, true);
        }

        function onTurnOff(responseCode, data) {
            onTurnOnOff(responseCode, data, false);
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
        enum {
            STATE_NONE,
            STATE_SYNCING,
            STATE_READY
        }

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
            // FIXME: Re-work this to use a single Group 0 PUT
            var lights = getLights();
            for (var i=0; i < lights.size(); i++) {
                var light = lights[i];
                turnOnLight(light, on);
            }
        }

        function turnOnLight(light, on) {
            Application.getApp().blinkerUp();
            light.setBusy(true);
            var callback = on ? light.method(:onTurnOn) : light.method(:onTurnOff);
            var url = Lang.format("/lights/$1$/state", [light.getId()]);
            doRequest(Communications.HTTP_REQUEST_METHOD_PUT, url, { "on" => on }, callback);
        }

        function toggleLight(light) {
            turnOnLight(light, !light.getOn());
        }
    }


}