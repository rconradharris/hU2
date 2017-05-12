using Toybox.Application;
using Toybox.System;

module HueCommand {
    enum {
        CMD_TURN_ON_ALL_LIGHTS,
        CMD_TOGGLE_LIGHT,
        CMD_SET_BRIGHTNESS
    }

    hidden var mQueue = null;

    function run(cmd, options) {
        var app = Application.getApp();
        if (app.getState() == app.AS_READY) {
            runImmediately(cmd, options);
        } else {
            enqueue(cmd, options);
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
            client.toggleLight(light);
        } else if (cmd == CMD_SET_BRIGHTNESS) {
            client.setBrightness(options[:light], option[:brightness]);
        }
    }

}