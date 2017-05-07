using Toybox.Application;
using Toybox.Attention;
using Toybox.Timer;
using Toybox.WatchUi as Ui;

using Hue;

class hU2App extends Application.AppBase {
    enum {
        AS_NO_BRIDGE,
        AS_DISCOVERING_BRIDGE,
        AS_NO_USERNAME,
        AS_REGISTERING,
        AS_PHONE_NOT_CONNECTED,
        AS_SYNCING,
        AS_READY
    }

    hidden var mState =  AS_NO_BRIDGE;
    hidden var mBridge = null;
    hidden var mUsername = null;
    hidden var mHueClient = null;

    hidden var mBlinkerTimer = null;
    hidden var mStateTimer = null;
    hidden var mBlinkerSemaphore = 0;

    function initialize() {
        AppBase.initialize();
    }

    function getState() {
        return mState;
    }

    function setState(state) {
        mState = state;
        Ui.requestUpdate();
    }

    function getHueClient() {
        return mHueClient;
    }

    function onBlink() {
        Ui.requestUpdate();
    }

    function blinkerUp() {
        if (mBlinkerSemaphore == 0) {
            mBlinkerTimer.start(method(:onBlink), 100, true);
        }
        mBlinkerSemaphore++;
    }

    function blinkerDown() {
        mBlinkerSemaphore--;
        if (mBlinkerSemaphore < 0) {
            mBlinkerSemaphore = 0;
        }
        if (mBlinkerSemaphore == 0) {
            mBlinkerTimer.stop();
        }
    }

    function hapticFeedback() {
        var ds = System.getDeviceSettings();
        if ((Attention has :vibrate) && ds.vibrateOn && ds.isTouchScreen) {
            Attention.vibrate([new Attention.VibeProfile(50, 30)]);
        }
    }

    // onStart() is called on application start up
    function onStart(state) {
        var bridgeIP = PropertyStore.get("bridgeIP");
        if (bridgeIP != null) {
            setState(AS_NO_USERNAME);
            mBridge = new Hue.Bridge(bridgeIP);
            var username = PropertyStore.get("username");
            if (username != null) {
                mHueClient = new Hue.Client(mBridge, username);
                if (System.getDeviceSettings().phoneConnected) {
                    setState(AS_SYNCING);
                    mHueClient.sync(method(:onSync));
                } else {
                    setState(AS_PHONE_NOT_CONNECTED);
                }
            }
        }
        mBlinkerTimer = new Timer.Timer();
        mStateTimer = new Timer.Timer();
        mStateTimer.start(method(:onStateTick), 3000, true);
        onStateTick();
    }

    function onDiscoverBridgeIP(bridgeIP) {
        if (bridgeIP == null) {
            setState(AS_NO_BRIDGE);
        } else {
            setState(AS_NO_USERNAME);
            PropertyStore.set("bridgeIP", bridgeIP);
            mBridge = new Hue.Bridge(bridgeIP);
        }
    }

    function onRegister(username) {
        if (username == null) {
            setState(AS_NO_USERNAME);
        } else {
            PropertyStore.set("username", username);
            mHueClient = new Hue.Client(mBridge, username);
            if (System.getDeviceSettings().phoneConnected) {
                setState(AS_SYNCING);
                mHueClient.sync(method(:onSync));
            } else {
                setState(AS_PHONE_NOT_CONNECTED);
            }
        }
    }

    function onSync(success) {
        if (success) {
            setState(AS_READY);
        }
    }

    function onStateTick() {
        var state = mState;
        if (state == AS_NO_BRIDGE) {
            setState(AS_DISCOVERING_BRIDGE);
            Hue.discoverBridgeIP(method(:onDiscoverBridgeIP));
        } else if (state == AS_NO_USERNAME) {
            setState(AS_REGISTERING);
            mBridge.register(method(:onRegister));
        } else if (state == AS_PHONE_NOT_CONNECTED) {
            if (System.getDeviceSettings().phoneConnected) {
                setState(AS_SYNCING);
                mHueClient.sync(method(:onSync));
            }
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        if (mBlinkerTimer != null) {
            mBlinkerTimer.stop();
            mBlinkerTimer = null;
        }
        if (mStateTimer != null) {
            mStateTimer.stop();
            mStateTimer = null;
        }
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new hU2View(), new hU2Delegate() ];
    }

    function reset() {
        PropertyStore.clear();
        mState =  AS_NO_BRIDGE;
        mBridge = null;
        mUsername = null;
        mHueClient = null;

    }
}