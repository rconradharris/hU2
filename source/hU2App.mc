using Toybox.Application;
using Toybox.Attention;
using Toybox.Timer;
using Toybox.WatchUi as Ui;

using Hue;

class hU2App extends Application.AppBase {
    enum {
        AS_INIT,
        AS_DISCOVERING_BRIDGE,
        AS_NO_BRIDGE,
        AS_NO_USERNAME,
        AS_REGISTERING,
        AS_PHONE_NOT_CONNECTED,
        AS_SYNCING,
        AS_READY
    }

    hidden const BLINKER_TIMER_MS = 100;
    hidden const STATE_TIMER_MS = 3000;

    // === START OF RESET NEEDED ===
    //
    // These fields need to be re-initialized in reset()

    hidden var mState =  AS_INIT;
    hidden var mBridge = null;
    hidden var mUsername = null;
    hidden var mHueClient = null;
    hidden var mSynced = false;
    hidden var mDiscoverAttemptsLeft = 5;
    hidden var mBlinkerSemaphore = 0;

    // === END OF RESET NEEDED ===

    hidden var mBlinkerTimer = null;
    hidden var mStateTimer = null;

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
            mBlinkerTimer.start(method(:onBlink), BLINKER_TIMER_MS, true);
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

    hidden function sync() {
        blinkerUp();
        setState(AS_SYNCING);
        mHueClient.sync(method(:onSync));
    }

    function onSettingsChanged() {
        var sBridgeIP = PropertyStore.get("sBridgeIP");
        var bridgeIP = PropertyStore.get("bridgeIP");
        if (!sBridgeIP.equals(bridgeIP)) {
            reset();
        }
    }

    hidden function tryInitBridge() {
        var bridgeIP = null;

        // Use bridgeIP if available (allows overriding if necessary)
        var sBridgeIP = PropertyStore.get("sBridgeIP");
        if (sBridgeIP.length() > 0) {
            bridgeIP = sBridgeIP;
        }

        // Otherwise use any previously detected bridges
        if (bridgeIP == null) {
            bridgeIP = PropertyStore.get("bridgeIP");
        }

        if (bridgeIP != null) {
            setState(AS_NO_USERNAME);
            mBridge = new Hue.Bridge(bridgeIP);
            var username = PropertyStore.get("username");
            if (username != null) {
                mHueClient = new Hue.Client(mBridge, username);
                if (System.getDeviceSettings().phoneConnected) {
                    sync();
                } else {
                    setState(AS_PHONE_NOT_CONNECTED);
                }
            }
        }
    }

    // onStart() is called on application start up
    function onStart(state) {
        mBlinkerTimer = new Timer.Timer();
        mStateTimer = new Timer.Timer();

        tryInitBridge();

        // Start the state timer...
        mStateTimer.start(method(:onStateTick), STATE_TIMER_MS, true);
        onStateTick();
    }

    function onDiscoverBridgeIP(bridgeIP) {
        if (bridgeIP == null) {
            mDiscoverAttemptsLeft--;
            if (mDiscoverAttemptsLeft > 0) {
                Hue.discoverBridgeIP(method(:onDiscoverBridgeIP));
            } else {
                blinkerDown();
                setState(AS_NO_BRIDGE);
            }
        } else {
            blinkerDown();
            setState(AS_NO_USERNAME);
            PropertyStore.set("bridgeIP", bridgeIP);
            mBridge = new Hue.Bridge(bridgeIP);
        }
    }

    function onRegister(status, username) {
        if (status == Hue.REGISTRATION_SUCCESS) {
            PropertyStore.set("username", username);
            mHueClient = new Hue.Client(mBridge, username);
            if (System.getDeviceSettings().phoneConnected) {
                sync();
            } else {
                setState(AS_PHONE_NOT_CONNECTED);
            }
        } else if (status == Hue.REGISTRATION_WAITING) {
            setState(AS_NO_USERNAME);
        } else if (status == Hue.REGISTRATION_FAILED) {
            setState(AS_NO_BRIDGE);
        }
    }

    function onSync(success) {
        if (success) {
            blinkerDown();
            setState(AS_READY);
            mSynced = true;
        }
    }

    function onStateTick() {
        var state = mState;

        var phoneConnected = System.getDeviceSettings().phoneConnected;

        if (state == AS_INIT) {
            setState(AS_DISCOVERING_BRIDGE);
            blinkerUp();
            Hue.discoverBridgeIP(method(:onDiscoverBridgeIP));
        } else if (state == AS_NO_USERNAME) {
            setState(AS_REGISTERING);
            mBridge.register(method(:onRegister));
        } else if (state == AS_PHONE_NOT_CONNECTED) {
            if (phoneConnected) {
                if (mSynced) {
                    setState(AS_READY);
                } else {
                    setState(AS_SYNCING);
                    mHueClient.sync(method(:onSync));
                }
            }
        } else {
            if (!phoneConnected) {
                setState(AS_PHONE_NOT_CONNECTED);
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

        // === START OF RESET NEEDED ===
        //
        // These fields need to be re-initialized in reset()

        mState =  AS_INIT;
        mBridge = null;
        mUsername = null;
        mHueClient = null;
        mSynced = false;
        mDiscoverAttemptsLeft = 5;
        mBlinkerSemaphore = 0;

        // === END OF RESET NEEDED ===

        // Make sure blinker is zero'd and stopped when we begin
        mBlinkerTimer.stop();

        tryInitBridge();
    }
}