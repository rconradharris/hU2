using Toybox.Communications;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi as Ui;

module Hue {

    class Light {
        hidden var mId = null;
        hidden var mName = null;
        hidden var mOn = null;
        hidden var mReachable = null;

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


        hidden function onTurnOnOff(responseCode, data, on) {
            if (responseCode != 200) {
                // TODO: alert that an error occured
                return;
            }
            System.println(data);
            if (data[0].hasKey("success")) {
                mOn = on;
                Ui.requestUpdate();
            }
        }

        function onTurnOn(responseCode, data) {
            onTurnOnOff(responseCode, data, true);
        }

        function onTurnOff(responseCode, data) {
            onTurnOnOff(responseCode, data, false);
        }
    }

    class Client {
        enum {
            STATE_NONE,
            STATE_SYNCING,
            STATE_READY
        }

        hidden var mBridgeIP = null;
        hidden var mUsername = null;
        hidden var mLights = {};
        hidden var mState = STATE_NONE;

        function initialize(bridgeIP, username) {
            mBridgeIP = bridgeIP;
            mUsername = username;
        }

        hidden function doRequest(method, url, params, callback) {
            var options = { :method => method,
                            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
                            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON };
            var fullUrl = Lang.format("http://$1$/api/$2$$3$", [mBridgeIP, mUsername, url]);
            System.println(fullUrl);
            Communications.makeWebRequest(fullUrl, params, options, callback);
        }

        function onFetchLights(responseCode, data) {
            if (!validateState([STATE_SYNCING], "onFetchLights")) {
                return;
            }
            mState = STATE_READY;
            if (responseCode != 200) {
                // TODO: alert that an error occured
                return;
            }
            var lightIds = data.keys();
            for (var i=0; i < lightIds.size(); i++) {
                var lightId = lightIds[i];
                var ld = data[lightId];
                var st = ld["state"];
                var light = new Light(lightId, ld["name"], st["on"], st["reachable"]);
                mLights[lightId] = light;
            }
        }

        function sync() {
            if (!validateState([STATE_NONE, STATE_READY], "sync")) {
                return;
            }
            mState = STATE_SYNCING;
            doRequest(Communications.HTTP_REQUEST_METHOD_GET, "/lights", {}, method(:onFetchLights));
        }

        function getLights() {
            return mLights.values();
        }

        function getLight(lightId) {
            return mLights[lightId];
        }

        hidden function validateState(allowedStates, funcName) {
            var allowed = allowedStates.indexOf(mState) >= 0;
            if (!allowed) {
                var msg = Lang.format("$1$: state validation failed current=$2$ allowed=$3$",
                                      [funcName, mState, allowedStates]);
                System.println(msg);
            }
            return allowed;
        }

        function turnOnAllLights(on) {
            // FIXME: Re-work this to use a single Group 0 PUT
            if (!validateState([STATE_READY], "turnOnAllLights")) {
                return;
            }
            var lights = getLights();
            for (var i=0; i < lights.size(); i++) {
                var light = lights[i];
                turnOnLight(light, on);
            }
        }

        function turnOnLight(light, on) {
            if (!validateState([STATE_READY], "turnOnLight")) {
                return;
            }
            var callback = on ? light.method(:onTurnOn) : light.method(:onTurnOff);
            var url = Lang.format("/lights/$1$/state", [light.getId()]);
            doRequest(Communications.HTTP_REQUEST_METHOD_PUT, url, { "on" => on }, callback);
        }

        function toggleLight(light) {
            turnOnLight(light, !light.getOn());
        }
    }


}