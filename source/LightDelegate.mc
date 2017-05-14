using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi as Ui;

using HueCommand;


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
        // HACK: The firmware on FR230 and 235 will generate an onPreviousPage
        // when an onMenu event is emitted. To work around this, we disable
        // the up button so that spruious onPrevious has no effect
        var ds = System.getDeviceSettings();
        if (ds.screenShape == System.SCREEN_SHAPE_SEMI_ROUND && !ds.isTouchScreen) {
            return false;
        }
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
        HueCommand.run(HueCommand.CMD_TOGGLE_LIGHT, { :light => light });
        return true;
    }

    function onMenu() {
        var app = Application.getApp();
        var client = app.getHueClient();
        var lights = client.getLights();
        var light = lights[mIndex];

        app.hapticFeedback();

        var menu = new Ui.Menu();
        menu.setTitle(light.getName());
        menu.addItem(Ui.loadResource(Rez.Strings.brightness), :brightness);
        if (light.hasColorSupport()) {
            menu.addItem(Ui.loadResource(Rez.Strings.color), :color);
        }
        Application.getApp().hapticFeedback();
        Ui.pushView(menu, new LightMenuInputDelegate(light), Ui.SLIDE_UP);

        return true;
    }
 }

class LightMenuInputDelegate extends Ui.MenuInputDelegate {
    hidden var mLight = null;

    function initialize(light) {
        Ui.MenuInputDelegate.initialize();
        mLight = light;
    }

    function onMenuItem(item) {
        var app = Application.getApp();
        app.hapticFeedback();
        var menu = new Ui.Menu();
        if (item == :brightness) {
            menu.setTitle(Ui.loadResource(Rez.Strings.brightness));
            menu.addItem("10%", :pct_10);
            menu.addItem("25%", :pct_25);
            menu.addItem("50%", :pct_50);
            menu.addItem("100%", :pct_100);
            Ui.pushView(menu, new BrightnessMenuInputDelegate(mLight), Ui.SLIDE_UP);
        } else if (item == :color) {
            menu.setTitle(Ui.loadResource(Rez.Strings.color));
            menu.addItem(Ui.loadResource(Rez.Strings.warm_white), :warm_white);
            menu.addItem(Ui.loadResource(Rez.Strings.cool_white), :cool_white);
            menu.addItem(Ui.loadResource(Rez.Strings.red), :red);
            menu.addItem(Ui.loadResource(Rez.Strings.blue), :blue);
            menu.addItem(Ui.loadResource(Rez.Strings.color_loop), :color_loop);
            Ui.pushView(menu, new ColorMenuInputDelegate(mLight), Ui.SLIDE_UP);
        }
    }
}

class ColorMenuInputDelegate extends Ui.MenuInputDelegate {
    hidden var mLight = null;

    function initialize(light) {
        Ui.MenuInputDelegate.initialize();
        mLight = light;
    }

    function onMenuItem(item) {
        var app = Application.getApp();
        if (!app.areActionsAllowed()) {
            return;
        }
        app.hapticFeedback();
        var xy = null;
        if (item == :color_loop) {
            HueCommand.run(HueCommand.CMD_SET_EFFECT,
                           { :light => mLight, :effect => "colorloop" });
        } else if (item == :warm_white) {
            xy = [0.475800, 0.413200];
        } else if (item == :cool_white) {
            xy = [0.3227,0.329];
        } else if (item == :red) {
            xy = [0.674,0.322];
        } else if (item == :blue) {
            xy = [0.1825,0.0697];
        }
        if (xy != null) {
            HueCommand.run(HueCommand.CMD_SET_XY, { :light => mLight, :xy => xy });
        }
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
        var pct = 1.0;
        if (item == :pct_10) {
            pct = 0.10;
        } else if (item == :pct_25) {
            pct = 0.25;
        } else if (item == :pct_50) {
            pct = 0.50;
        }
        if (app.areActionsAllowed()) {
            app.hapticFeedback();
            var brightness = (pct * 254).toNumber();
            HueCommand.run(HueCommand.CMD_SET_BRIGHTNESS, { :light => mLight,
                                                            :brightness => brightness });
        }
    }
}
