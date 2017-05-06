using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi as Ui;

using DynamicMenu;

class SettingsMenuInputDelegate extends Ui.MenuInputDelegate {
    function initialize() {
        Ui.MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        var app = Application.getApp();
        if (item == :reset) {
            app.reset();
        }
    }
}
class LightMenuInputDelegate extends Ui.MenuInputDelegate {
    function initialize() {
        Ui.MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        var client = Application.getApp().getHueClient();
        if (item == :all_off) {
            client.turnOnAllLights(false);
        } else if (item == :all_on) {
            client.turnOnAllLights(true);
        } else {
            var lightId = DynamicMenu.get(item);
            DynamicMenu.free();
            if (lightId != null) {
                var light = client.getLight(lightId);
                if (light != null) {
                    client.toggleLight(light);
                }
            }
        }
    }
}


class hU2Delegate extends Ui.BehaviorDelegate {
    function initialize() {
        Ui.BehaviorDelegate.initialize();
    }

    function onMenu() {
        var menu = new Ui.Menu();
        menu.setTitle(getMenuTitle("Settings"));
        menu.addItem(Ui.loadResource(Rez.Strings.reset), :reset);
        Ui.pushView(menu, new SettingsMenuInputDelegate(), Ui.SLIDE_UP);
        return true;
    }

    hidden function getMenuTitle(extra) {
        return Lang.format("$1$ $2$ $3$",
             [Ui.loadResource(Rez.Strings.AppName),
              Ui.loadResource(Rez.Strings.AppVersion),
              extra]);
    }

    function onSelect() {
        var client = Application.getApp().getHueClient();
        var lights = client.getLights();
        if (lights == null) {
            return true;
        }

        var menu = new Ui.Menu();

        menu.setTitle(getMenuTitle("Lights"));

        menu.addItem(Ui.loadResource(Rez.Strings.all_off), :all_off);
        menu.addItem(Ui.loadResource(Rez.Strings.all_on), :all_on);

        DynamicMenu.allocate();
        for (var i=0; i < lights.size(); i++) {
            var light = lights[i];
            var item = DynamicMenu.set(light.getId());
            menu.addItem(light.getName(), item);
        }
        Ui.pushView(menu, new LightMenuInputDelegate(), Ui.SLIDE_UP);
        return true;
    }
 }