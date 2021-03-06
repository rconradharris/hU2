using Toybox.Application;
using Toybox.System;

using PropertyStore;

module HueCommand {
    enum {
        CMD_TURN_ON_ALL_LIGHTS,
        CMD_TOGGLE_LIGHT,
        CMD_SET_BRIGHTNESS,
        CMD_SET_XY,
        CMD_SET_EFFECT
    }

    hidden var mQueue = null;

    // NOTE: THIS IS ABSOLUTELY INSANE BUT THIS FUNCTION HAS TO BE IN THIS
    // LOCATION IN THE SOURCE FILE!!!
    //
    // On a Fenix5X if you were to move this function below the `run` method
    // it would fail with this error:
    //
    // UnexpectedTypeException: Expected Method, given null
    //
    // After hours of debugging, I can't figure this out, but it seems to have
    // these clues:
    //
    // 1. Location in the file matters
    // 2. Seems to have to do with the `hidden` keyword
    // 3. Affects the Fenix 5X but not the Vivoactive
    // 4. Seems to be related to a race where one thread is running the
    //    `runImmediately` function in the module while another thread tires to
    //     as well
    hidden function runImmediately(cmd, options) {
        var client = Application.getApp().getHueClient();
        var light = (options == null) ? null : options[:light];

        if (cmd == CMD_TURN_ON_ALL_LIGHTS) {
            client.turnOnAllLights(options[:on]);
        } else if (cmd == CMD_TOGGLE_LIGHT) {
            var callback = new _LightCommandDoneCallback(light);
            client.toggleLight(light, callback.method(:onDone));
        } else if (cmd == CMD_SET_BRIGHTNESS) {
            var callback = new _LightCommandDoneCallback(light);
            client.setBrightness(light, options[:brightness], callback.method(:onDone));
        } else if (cmd == CMD_SET_XY) {
            var callback = new _LightCommandDoneCallback(light);
            client.setXY(light, options[:xy], callback.method(:onDone));
        } else if (cmd == CMD_SET_EFFECT) {
            var callback = new _LightCommandDoneCallback(light);
            client.setEffect(light, options[:effect], callback.method(:onDone));
        }

        if (light != null) {
            var lightId = light.getId();
            PropertyStore.set("lastLightId", lightId);
        }
    }


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

    function clear() {
        if (mQueue == null) {
            return;
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