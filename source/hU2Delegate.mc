using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi as Ui;

using HueCommand;
using PropertyStore;

class SettingsMenuInputDelegate extends Ui.MenuInputDelegate {
    function initialize() {
        Ui.MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        var app = Application.getApp();
        app.hapticFeedback();
        if (item == :all_off) {
            if (app.areActionsAllowed()) {
                HueCommand.run(HueCommand.CMD_TURN_ON_ALL_LIGHTS, { :on => false });
            }
        } else if (item == :all_on) {
            if (app.areActionsAllowed()) {
                HueCommand.run(HueCommand.CMD_TURN_ON_ALL_LIGHTS, { :on => true });
            }
        } else if (item == :reset) {
            Ui.pushView(new Ui.Confirmation(Ui.loadResource(Rez.Strings.reset) + "?"),
                        new ResetConfirmationDelegate(),
                        Ui.SLIDE_IMMEDIATE);

        }
    }
}


class ResetConfirmationDelegate extends Ui.ConfirmationDelegate {
    function initialize() {
        Ui.ConfirmationDelegate.initialize();
    }

    function onResponse(response) {
        var app = Application.getApp();
        app.hapticFeedback();
        if (response == Ui.CONFIRM_YES) {
            app.reset();
            Ui.popView(Ui.SLIDE_IMMEDIATE);
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

        if (app.areActionsAllowed()) {
            menu.addItem(Ui.loadResource(Rez.Strings.all_off), :all_off);
            menu.addItem(Ui.loadResource(Rez.Strings.all_on), :all_on);
        }

        menu.addItem(Ui.loadResource(Rez.Strings.reset), :reset);

        Ui.pushView(menu, new SettingsMenuInputDelegate(), Ui.SLIDE_UP);
        return true;
    }

    hidden function getLastLightIndex() {
        var lightId = PropertyStore.get("lastLightId");
        if (lightId != null) {
            var client = Application.getApp().getHueClient();
            var lights = client.getLights();
            for (var i=0; i < lights.size(); i++) {
                if (lights[i].getId() == lightId) {
                    return i;
                }
            }
        }
        return 0;
    }

    function onSelect() {
        var app = Application.getApp();
        if (app.areActionsAllowed()) {
            app.hapticFeedback();
            var idx = getLastLightIndex();
            Ui.pushView(new LightView(idx), new LightDelegate(idx), Ui.SLIDE_UP);
        }
    }
 }
