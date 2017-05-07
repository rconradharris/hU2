using Toybox.Application;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;

class LightView extends Ui.View {
    hidden var mIndex = null;
    hidden var mBlinkerOn = false;

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
        if (count <= 0) {
            return;
        }
        var light = lights[mIndex];
        if (light == null) {
            return;
        }

        // Draw light name
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.clear();

        var text = light.getName();
        var font = Gfx.FONT_MEDIUM;

        var textDim = dc.getTextDimensions(text, font);
        var x = (dc.getWidth() - textDim[0]) / 2;
        var y = 15;
        dc.drawText(x, y, font, text, Gfx.TEXT_JUSTIFY_LEFT);

        if (light.getBusy()) {
            // If we're busy then blink the light...
            mBlinkerOn = !mBlinkerOn;
        } else if (light.getOn()) {
            mBlinkerOn = true;
        } else {
            mBlinkerOn = false;
        }

        if (mBlinkerOn) {
            dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(dc.getWidth() / 2, dc.getHeight() / 2 + 10, 30);
        } else {
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawCircle(dc.getWidth() / 2, dc.getHeight() / 2 + 10, 30);
        }

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
}