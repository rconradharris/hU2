using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi as Ui;

class LightDelegate extends Ui.BehaviorDelegate {
    hidden var mIndex = null;

    function initialize(index) {
        Ui.BehaviorDelegate.initialize();
        mIndex = index;
    }

    hidden function switchPage(delta, transition) {
        var client = Application.getApp().getHueClient();
        var lights = client.getLights();
        var count = lights.size();

        if (count <= 1) {
            return false;
        }

        var index = (mIndex + delta) % count;
        if (index < 0) {
            index += count;
        }
        Ui.switchToView(new LightView(index), new LightDelegate(index), transition);
        return true;
    }

    function onBack() {
        Application.getApp().hapticFeedback();
        return false;
    }

    function onNextPage() {
        return switchPage(+1, Ui.SLIDE_LEFT);
    }

    function onPreviousPage() {
        return switchPage(-1, Ui.SLIDE_RIGHT);
    }

    function onSelect() {
        var app = Application.getApp();
        var client = app.getHueClient();
        var lights = client.getLights();

        var count = lights.size();
        if (count == 0) {
            return false;
        }
        if (mIndex > count - 1) {
            mIndex = count - 1;
        }

        Application.getApp().hapticFeedback();

        var light = lights[mIndex];
        client.toggleLight(light);
        return true;
    }

    function onMenu() {
        var app = Application.getApp();
        var client = app.getHueClient();
        var lights = client.getLights();

        app.hapticFeedback();

        var menu = new Ui.Menu();
        menu.setTitle(Ui.loadResource(Rez.Strings.brightness));
        menu.addItem("10%", :pct_10);
        menu.addItem("25%", :pct_25);
        menu.addItem("50%", :pct_50);
        menu.addItem("100%", :pct_100);

        Application.getApp().hapticFeedback();

        var light = lights[mIndex];
        Ui.pushView(menu, new BrightnessMenuInputDelegate(light), Ui.SLIDE_UP);
        return true;
    }
 }

class BrightnessMenuInputDelegate extends Ui.MenuInputDelegate {
    hidden var mLight = null;

    function initialize(light) {
        Ui.MenuInputDelegate.initialize();
        mLight = light;
    }

    function onMenuItem(item) {
        var app = Application.getApp();
        app.hapticFeedback();
        var pct = 1.0;
        if (item == :pct_10) {
            pct = 0.10;
        } else if (item == :pct_25) {
            pct = 0.25;
        } else if (item == :pct_50) {
            pct = 0.50;
        }
        if (app.getState() == app.AS_READY) {
            app.getHueClient().setBrightness(mLight, (pct * 254).toNumber());
        }
    }
}
