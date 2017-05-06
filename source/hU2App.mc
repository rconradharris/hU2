using Toybox.Application;

using Hue;

class hU2App extends Application.AppBase {
    // This is an attribute of hU2App and not Hue.App in order to avoid
    // circular references
    var mLightCache = {};

    hidden var mHueApp;

    hidden var mHueClient;

    function initialize() {
        AppBase.initialize();
    }

    function getHueApp() {
        return mHueApp;
    }

    function getHueClient() {
        return mHueClient;
    }

    // onStart() is called on application start up
    function onStart(state) {
        mHueClient = new Hue.Client("10.0.1.2", "AREVe-BgAjf8GdoFvuefnPP-ocu0IDVWa1-kNlr-");
        mHueClient.sync();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new hU2View(), new hU2Delegate() ];
    }

    function reset() {
        // TODO: properly reset state
    }
}