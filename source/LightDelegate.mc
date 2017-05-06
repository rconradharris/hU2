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

    function onNextPage() {
        return switchPage(+1, Ui.SLIDE_LEFT);
    }

    function onPreviousPage() {
        return switchPage(-1, Ui.SLIDE_RIGHT);
    }

    function onSelect() {
        var client = Application.getApp().getHueClient();
        var lights = client.getLights();
        var count = lights.size();
        if (count == 0) {
            // TODO: transition to NoLightsView
        }
        if (mIndex > count - 1) {
            mIndex = count - 1;
        }
        var light = lights[mIndex];
        client.toggleLight(light);
        return true;
    }
 }