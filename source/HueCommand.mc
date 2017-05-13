using Toybox.Application;
using Toybox.System;

module HueCommand {
    enum {
        CMD_TURN_ON_ALL_LIGHTS,
        CMD_TOGGLE_LIGHT,
        CMD_SET_BRIGHTNESS,
        CMD_SET_XY
    }

    hidden var mQueue = null;

    function run(cmd, options) {
        var app = Application.getApp();
        if (app.getState() == app.AS_READY) {
            runImmediately(cmd, options);
        } else {
            enqueue(cmd, options);
        }
        // Start the light blinking even if the command is enqueued
        var light = options[:light];
        if (light != null) {
            app.blinkerUp();
            light.setBusy(true);
        }
    }

    function flush() {
        if (mQueue == null) {
            return;
        }
        for (var i=0; i < mQueue.size(); i++) {
            var packed = mQueue[i];
            runImmediately(packed[:cmd], packed);
        }
        mQueue = null;
    }

    hidden function enqueue(cmd, options) {
        options[:cmd] = cmd;
        if (mQueue == null) {
            mQueue = [options];
        } else {
            mQueue.add(options);
        }
    }

    hidden function runImmediately(cmd, options) {
        var client = Application.getApp().getHueClient();
        if (cmd == CMD_TURN_ON_ALL_LIGHTS) {
            client.turnOnAllLights(options[:on]);
        } else if (cmd == CMD_TOGGLE_LIGHT) {
            var light = options[:light];
            var callback = new _LightCommandDoneCallback(light);
            client.toggleLight(light, callback.method(:onDone));
        } else if (cmd == CMD_SET_BRIGHTNESS) {
            var light = options[:light];
            var callback = new _LightCommandDoneCallback(light);
            client.setBrightness(light, options[:brightness], callback.method(:onDone));
        } else if (cmd == CMD_SET_XY) {
            var light = options[:light];
            var callback = new _LightCommandDoneCallback(light);
            client.setXY(light, options[:xy], callback.method(:onDone));
        }
    }

    class _LightCommandDoneCallback {
        hidden var mLight = null;

        function initialize(light) {
            mLight = light;
        }

        function onDone() {
            Application.getApp().blinkerDown();
            mLight.setBusy(false);
        }
    }
}