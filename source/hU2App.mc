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
        AS_BRIDGE_NEEDS_UPDATE,
        AS_NO_USERNAME,
        AS_REGISTERING,
        AS_FETCHING,                // First sync, we don't have stored lights we can show
        AS_UPDATING,                // Subsequent sync, we have cached lights, so show them
        AS_NO_LIGHTS,
        AS_READY
    }

    hidden const BLINKER_TIMER_MS = 50;
    hidden const STATE_TIMER_MS = 3000;
    hidden const MIN_API_VERSION = [1, 3, 0];

    // === START OF RESET NEEDED ===
    //
    // These fields need to be re-initialized in reset()

    hidden var mState =  AS_INIT;
    hidden var mBridge = null;
    hidden var mUsername = null;
    hidden var mHueClient = null;
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

    function getPixelsBelowCenter() {
        // Things look slightly better when not aligned directly on center
        return 20;
    }

    function hapticFeedback() {
        var ds = System.getDeviceSettings();
        if ((Attention has :vibrate) && ds.vibrateOn && ds.isTouchScreen) {
            Attention.vibrate([new Attention.VibeProfile(50, 30)]);
        }
    }

    hidden function sync(username) {
        if (!System.getDeviceSettings().phoneConnected) {
            return;
        }
        mHueClient = new Hue.Client(mBridge, username);
        var count = mHueClient.getLights().size();
        if (count > 0) {
            setState(AS_UPDATING);
        } else {
            setState(AS_FETCHING);
        }
        blinkerUp();
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
        // Make sure all timers are stopped to avoid races, especially if we're resetting...
        mBlinkerTimer.stop();
        mStateTimer.stop();

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

        var apiVersion = PropertyStore.get("apiVersion");

        if (bridgeIP != null && apiVersion != null) {
            mBridge = new Hue.Bridge(bridgeIP, apiVersion);
            setState(AS_NO_USERNAME);
            var username = PropertyStore.get("username");
            if (username != null) {
                sync(username);
            }
        }

        // Start the state timer...
        mStateTimer.start(method(:onStateTick), STATE_TIMER_MS, true);
        onStateTick();
    }

    function areActionsAllowed() {
        return (mState == AS_UPDATING || mState == AS_READY);
    }

    // onStart() is called on application start up
    function onStart(state) {
        mBlinkerTimer = new Timer.Timer();
        mStateTimer = new Timer.Timer();

        tryInitBridge();
    }

    function onDiscoverBridgeIP(status) {
        if (status == null) {
            mDiscoverAttemptsLeft--;
            if (mDiscoverAttemptsLeft > 0) {
                Hue.discoverBridgeIP(method(:onDiscoverBridgeIP));
            } else {
                blinkerDown();
                setState(AS_NO_BRIDGE);
            }
        } else {
            blinkerDown();
            var apiVersion = status[:apiVersion];
            if (Utils.versionLt(apiVersion, MIN_API_VERSION)) {
                // We rely on light data being returned in light list API call
                // which only happens in 1.3+
                setState(AS_BRIDGE_NEEDS_UPDATE);
            } else {
                var bridgeIP = status[:bridgeIP];
                PropertyStore.set("bridgeIP", bridgeIP);
                PropertyStore.set("apiVersion", apiVersion);
                mBridge = new Hue.Bridge(bridgeIP, apiVersion);
                setState(AS_NO_USERNAME);
            }
        }
    }

    function onRegister(status, username) {
        if (status == Hue.REGISTRATION_SUCCESS) {
            PropertyStore.set("username", username);
            sync(username);
        } else if (status == Hue.REGISTRATION_WAITING) {
            setState(AS_NO_USERNAME);
        } else if (status == Hue.REGISTRATION_FAILED) {
            setState(AS_NO_BRIDGE);
        }
    }

    function onSync(status) {
        blinkerDown();
        if (status == Hue.SYNC_SUCCESS) {
            setState(AS_READY);
            // Run any enqueued commands now that we're synced up
            HueCommand.flush();
        } else if (status == Hue.SYNC_NO_LIGHTS) {
            HueCommand.clear();
            setState(AS_NO_LIGHTS);
        } else {
            // Commands won't complete in a reasonable period of time, so just
            // toss them out...
            HueCommand.clear();
            setState(AS_NO_BRIDGE);
        }
        Ui.requestUpdate();
    }

    function onStateTick() {
        if (!System.getDeviceSettings().phoneConnected) {
            // Do nothing...
        } else if (mState == AS_INIT) {
            setState(AS_DISCOVERING_BRIDGE);
            blinkerUp();
            Hue.discoverBridgeIP(method(:onDiscoverBridgeIP));
        } else if (mState == AS_NO_USERNAME) {
            setState(AS_REGISTERING);
            mBridge.register(method(:onRegister));
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
        mDiscoverAttemptsLeft = 5;
        mBlinkerSemaphore = 0;

        // === END OF RESET NEEDED ===

        tryInitBridge();
    }
}