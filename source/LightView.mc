using Toybox.Application;
using Toybox.Graphics as Gfx;
using Toybox.Math;
using Toybox.WatchUi as Ui;
using Toybox.System;

class LightView extends Ui.View {
    hidden const MIN_BLINK_MS = 100;
    hidden const DROP_SHADOW_PX = 2;
    hidden const CIRCLE_PADDING_PX = 10;

    hidden var mIndex = null;
    hidden var mBlinkerOn = false;
    hidden var mBlinkedAt = 0;          // So we get a consistent blink regardless of requestUpdate calls
    hidden var mCircleRadius = null;

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

    hidden function getBrightnessFont() {
        return Gfx.FONT_NUMBER_MEDIUM;
    }

    hidden function getLightCircleRadius(dc) {
        if (mCircleRadius == null) {
            var dim = dc.getTextDimensions("100%", getBrightnessFont());
            var maxDim = (dim[0] > dim[1]) ? dim[0] : dim[1];
            mCircleRadius = (maxDim / 2).toNumber() + CIRCLE_PADDING_PX;
        }
        return mCircleRadius;
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

        // HACK: Nasty hack to make the unreachable label look okay on
        // Vivoactive
        if (dc.getWidth() == 205 && dc.getHeight() == 148) {
            y = 0;
        }

        dc.drawText(x, y, font, text, Gfx.TEXT_JUSTIFY_LEFT);


        if (light.getBusy()) {
            // If we're busy then blink the light, but use MIN_BLINK_MS to
            // isolate us from too many requestUpdate calls
            var now = System.getTimer();
            if ((now - mBlinkedAt) > MIN_BLINK_MS) {
                mBlinkerOn = !mBlinkerOn;
                mBlinkedAt = now;
            }
        } else if (light.getOn()) {
            mBlinkerOn = true;
        } else {
            mBlinkerOn = false;
        }

        var radius = getLightCircleRadius(dc);

        var reachable = light.getReachable();
        if (reachable != null && !reachable) {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawCircle(dc.getWidth() / 2, dc.getHeight() / 2 + 20, radius);

            var unreachableFont = Gfx.FONT_SMALL;
            var unreachableText = Ui.loadResource(Rez.Strings.unreachable);
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, y + textDim[1],
                        unreachableFont, unreachableText, Gfx.TEXT_JUSTIFY_CENTER);
        } else if (mBlinkerOn) {
            dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(dc.getWidth() / 2, dc.getHeight() / 2 + 20, radius);

            if (!light.getBusy()) {
                var pctFont = getBrightnessFont();
                var pctBrightness = Math.round((light.getBrightness().toFloat() / 254) * 100).toNumber();
                var pctText = pctBrightness.toString() + "%";
                var pctDim = dc.getTextDimensions(pctText, pctFont);

                // Draw text with drop shadow
                dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
                dc.drawText(dc.getWidth() / 2 + DROP_SHADOW_PX,
                            (dc.getHeight() - pctDim[1]) / 2 + 20 + DROP_SHADOW_PX,
                            pctFont, pctText, Gfx.TEXT_JUSTIFY_CENTER);

                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                dc.drawText(dc.getWidth() / 2,
                            (dc.getHeight() - pctDim[1]) / 2 + 20,
                            pctFont, pctText, Gfx.TEXT_JUSTIFY_CENTER);
            }
        } else {
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawCircle(dc.getWidth() / 2, dc.getHeight() / 2 + 20, radius);
        }

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
}
