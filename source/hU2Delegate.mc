using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi as Ui;

class SettingsMenuInputDelegate extends Ui.MenuInputDelegate {
    function initialize() {
        Ui.MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        var app = Application.getApp();
        app.hapticFeedback();
        if (item == :all_off) {
            if (app.getState() == app.AS_READY) {
                app.getHueClient().turnOnAllLights(false);
            }
        } else if (item == :all_on) {
            if (app.getState() == app.AS_READY) {
                app.getHueClient().turnOnAllLights(true);
            }
        } else if (item == :reset) {
            app.reset();
        }
    }
}

class hU2Delegate extends Ui.BehaviorDelegate {
    function initialize() {
        Ui.BehaviorDelegate.initialize();
    }

    function onMenu() {
        var app = Application.getApp();
        app.hapticFeedback();

        var menu = new Ui.Menu();
        var title =  Lang.format("$1$ $2$", [Ui.loadResource(Rez.Strings.AppName), Ui.loadResource(Rez.Strings.AppVersion)]);
        menu.setTitle(title);

        if (app.getState() == app.AS_READY) {
            menu.addItem(Ui.loadResource(Rez.Strings.all_off), :all_off);
            menu.addItem(Ui.loadResource(Rez.Strings.all_on), :all_on);
        }

        menu.addItem(Ui.loadResource(Rez.Strings.reset), :reset);

        Ui.pushView(menu, new SettingsMenuInputDelegate(), Ui.SLIDE_UP);
        return true;
    }

    function onSelect() {
        var app = Application.getApp();
        if (app.getState() == app.AS_READY) {
            app.hapticFeedback();
            Ui.pushView(new LightView(0), new LightDelegate(0), Ui.SLIDE_UP);
        }
    }
 }