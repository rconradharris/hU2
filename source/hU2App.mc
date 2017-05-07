using Toybox.Application;
using Toybox.Timer;
using Toybox.WatchUi as Ui;

using Hue;

class hU2App extends Application.AppBase {
    hidden var mHueClient;

    hidden var mBlinkerTimer = null;
    hidden var mBlinkerSemaphore = 0;

    function initialize() {
        AppBase.initialize();
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

    // onStart() is called on application start up
    function onStart(state) {
        mHueClient = new Hue.Client("10.0.1.2", "AREVe-BgAjf8GdoFvuefnPP-ocu0IDVWa1-kNlr-");
        mHueClient.sync();
        mBlinkerTimer = new Timer.Timer();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        if (mBlinkerTimer != null) {
            mBlinkerTimer.stop();
            mBlinkerTimer = null;
        }
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new hU2View(), new hU2Delegate() ];
    }

    function reset() {
        // TODO: properly reset state
    }
}