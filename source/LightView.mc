using Toybox.Application;
using Toybox.Graphics as Gfx;
using Toybox.Math;
using Toybox.WatchUi as Ui;
using Toybox.System;

using Utils;


class LightView extends Ui.View {
    hidden const MIN_BLINK_MS = 100;
    hidden const CIRCLE_PADDING_PX = 10;
    hidden const ARC_DELTA_DEGREES = -30;  // Minus means clockwise
    hidden const ARC_GAP_DEGREES = 90;

    hidden var mIndex = null;
    hidden var mBlinkerOn = false;
    hidden var mBlinkedAt = 0;          // So we get a consistent blink regardless of requestUpdate calls
    hidden var mCircleRadius = null;
    hidden var mArcStartDegree = 0;

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
        var app = Application.getApp();

        // Make sure we're still in a show where we should show lights...
        var state = app.getState();
        if (state != app.AS_READY && state != app.AS_UPDATING) {
            Ui.popView(Ui.SLIDE_DOWN);
        }

        var client = app.getHueClient();
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
        var circleX = dc.getWidth() / 2;
        var circleY = dc.getHeight() / 2 + app.getPixelsBelowCenter();

        if (!light.isStateAvailable()) {
            var now = System.getTimer();
            if ((now - mBlinkedAt) > MIN_BLINK_MS) {
                mArcStartDegree = (mArcStartDegree + ARC_DELTA_DEGREES) % 360;
                mBlinkedAt = now;
            }
            dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            var endDegree = (mArcStartDegree + (360 - ARC_GAP_DEGREES)) % 360;
            dc.drawArc(circleX, circleY, radius, Gfx.ARC_COUNTER_CLOCKWISE,
                       mArcStartDegree, endDegree);
        } else if (!light.getReachable()) {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawCircle(circleX, circleY, radius);

            var unreachableFont = Gfx.FONT_SMALL;
            var unreachableText = Ui.loadResource(Rez.Strings.unreachable);
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(circleX, y + textDim[1],
                        unreachableFont, unreachableText, Gfx.TEXT_JUSTIFY_CENTER);
        } else if (mBlinkerOn) {
            dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(circleX, circleY, radius);

            if (!light.getBusy()) {
                var pctFont = getBrightnessFont();
                var bri = light.getBrightness().toFloat();
                var pctBrightness = Math.round((bri / 254) * 100).toNumber();
                // HACK: If bri=1, then we'd show 0% which won't look right,
                // so manually fix that up to be 1%
                if (pctBrightness == 0 && bri > 0.0) {
                    pctBrightness = 1;
                }
                var pctText = pctBrightness.toString() + "%";
                var pctDim = dc.getTextDimensions(pctText, pctFont);
                Utils.drawTextWithDropShadow(dc,
                            circleX,
                            circleY - (pctDim[1] / 2),
                            pctFont, pctText, Gfx.TEXT_JUSTIFY_CENTER, Gfx.COLOR_WHITE);

                if (light.isColorLoop()) {
                    dc.setPenWidth(5);
                    var startDeg = 0;

                    dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
                    dc.drawArc(circleX, circleY, radius, Gfx.ARC_COUNTER_CLOCKWISE, startDeg, startDeg + 90);
                    startDeg += 90;

                    dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
                    dc.drawArc(circleX, circleY, radius, Gfx.ARC_COUNTER_CLOCKWISE, startDeg, startDeg + 90);
                    startDeg += 90;

                    dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
                    dc.drawArc(circleX, circleY, radius, Gfx.ARC_COUNTER_CLOCKWISE, startDeg, startDeg + 90);
                    startDeg += 90;

                    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                    dc.drawArc(circleX, circleY, radius, Gfx.ARC_COUNTER_CLOCKWISE, startDeg, startDeg + 90);
                }
            }
        } else {
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(3);
            dc.drawCircle(circleX, circleY, radius);
        }

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
}
