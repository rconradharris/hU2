using Toybox.Application;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;

class LightView extends Ui.View {
    hidden var mIndex = null;

    function initialize(index) {
        View.initialize();
        mIndex = index;
    }

    // Load your resources here
    function onLayout(dc) {

    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {

    }

    // Update the view
    function onUpdate(dc) {
        var client = Application.getApp().getHueClient();
        var lights = client.getLights();
        var count = lights.size();
        if (count == 0) {
            // TODO: transition to NoLightsView
            return;
        }
        var light = lights[mIndex];

        var fgColor = light.getOn() ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE;
        var bgColor = light.getOn() ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;

        dc.setColor(fgColor, bgColor);
        dc.clear();

        var text = light.getName();
        var font = Gfx.FONT_LARGE;

        var textDim = dc.getTextDimensions(text, font);
        var x = (dc.getWidth() - textDim[0]) / 2;
        var y = (dc.getHeight() - textDim[1]) / 2;
        dc.drawText(x, y, font, text, Gfx.TEXT_JUSTIFY_LEFT);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
}
