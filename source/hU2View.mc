using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;

using Utils;

class hU2View extends Ui.View {
    hidden const BOX_FONT = Gfx.FONT_MEDIUM;
    hidden const BOX_TEXT_COLOR = Gfx.COLOR_WHITE;
    hidden const BOX_MARGIN = 15;
    hidden const BOX_RADIUS = 10;

    // Used to blink 1 out of every 10 timer ticks
    hidden var mBlinkCount = 0;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    hidden function drawBoxText(dc, y, lines, boxColor, textColor) {
        var x = dc.getWidth() / 2;
        var textHeight = 0;
        var textMaxWidth = 0;
        for (var i=0; i < lines.size(); i++) {
            var dim = dc.getTextDimensions(lines[i], BOX_FONT);
            if (dim[0] > textMaxWidth) {
                textMaxWidth = dim[0];
            }
            textHeight += dim[1];
        }

        var width = textMaxWidth + 2 * BOX_MARGIN;
        var height = textHeight + 2 * BOX_MARGIN;

        var boxX = x - (width / 2);
        var boxY = y - (height / 2);

        // Draw box
        dc.setColor(boxColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(boxX, boxY, width, height, BOX_RADIUS);

        // Draw text
        if (textColor != null) {
            y -= textHeight / 2;
            for (var i=0; i < lines.size(); i++) {
                var dim = dc.getTextDimensions(lines[i], BOX_FONT);
                Utils.drawTextWithDropShadow(dc, x, y, BOX_FONT, lines[i],
                                             Gfx.TEXT_JUSTIFY_CENTER, textColor);
                y += dim[1];
            }
        }
    }

    hidden function drawLogo(dc, y) {
        // Draw colorized logo
        var logoFont = Gfx.FONT_MEDIUM;
        var letters = ["h", "U", "2"];
        var letterWidths = new [letters.size()];
        var logoHeight = 0;
        var logoWidth = 0;

        // Compute width and height of logo
        for (var i=0; i < letters.size(); i++) {
            var letterDim = dc.getTextDimensions(letters[i], logoFont);
            if (letterDim[1] > logoHeight) {
                logoHeight = letterDim[1];
            }
            letterWidths[i] = letterDim[0];
            logoWidth += letterDim[0];
        }

        // Draw the logo
        var logoX = (dc.getWidth() - logoWidth) / 2;
        var fgColors = [Gfx.COLOR_BLACK, Gfx.COLOR_WHITE, Gfx.COLOR_BLACK];
        var bgColors = [Gfx.COLOR_BLUE, Gfx.COLOR_RED, Gfx.COLOR_GREEN];

        for (var i=0; i < letters.size(); i++) {

            dc.setColor(fgColors[i], bgColors[i]);
            dc.drawText(logoX, y, logoFont, letters[i], Gfx.TEXT_JUSTIFY_LEFT);

            logoX += letterWidths[i];
        }

        return logoHeight;
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.clear();

        var y = 5;

        y += drawLogo(dc, y);

        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK);
        var descFont = Gfx.FONT_TINY;
        var descText = Ui.loadResource(Rez.Strings.AppDescription);
        dc.drawText(dc.getWidth() / 2, y, descFont, descText,
                    Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        var text = "-";

        var boxY = dc.getHeight() / 2;

        // HACK: Nasty hack to make the description text visible on the
        // Vivoactive
        if (dc.getWidth() == 205 && dc.getHeight() == 148) {
            var descDim = dc.getTextDimensions(descText, descFont);
            boxY += descDim[1] + 5;
        }

        var app = Application.getApp();
        var state = app.getState();
        if (state == app.AS_INIT) {
            drawBoxText(dc, boxY, [Ui.loadResource(Rez.Strings.init)],
                        Gfx.COLOR_BLUE, BOX_TEXT_COLOR);
        } else if (state == app.AS_NO_BRIDGE) {
            var lines = [Ui.loadResource(Rez.Strings.no_bridge0),
                         Ui.loadResource(Rez.Strings.no_bridge1)];
            drawBoxText(dc, boxY, lines, Gfx.COLOR_RED, BOX_TEXT_COLOR);
        } else if (state == app.AS_DISCOVERING_BRIDGE) {
            var textColor = (mBlinkCount > 10) ? null : BOX_TEXT_COLOR;
            mBlinkCount = (mBlinkCount + 1) % 20;
            var lines = [Ui.loadResource(Rez.Strings.discovering_bridge0),
                         Ui.loadResource(Rez.Strings.discovering_bridge1)];
            drawBoxText(dc, boxY, lines, Gfx.COLOR_BLUE, textColor);
        } else if (state == app.AS_NO_USERNAME || state == app.AS_REGISTERING) {
            var lines = [Ui.loadResource(Rez.Strings.press_button0),
                         Ui.loadResource(Rez.Strings.press_button1)];
            drawBoxText(dc, boxY, lines, Gfx.COLOR_BLUE, BOX_TEXT_COLOR);
        } else if (state == app.AS_PHONE_NOT_CONNECTED) {
            var lines = [Ui.loadResource(Rez.Strings.phone_not_connected0),
                         Ui.loadResource(Rez.Strings.phone_not_connected1)];
            drawBoxText(dc, boxY, lines, Gfx.COLOR_RED, BOX_TEXT_COLOR);
        } else if (state == app.AS_FETCHING) {
            var textColor = (mBlinkCount > 10) ? null : BOX_TEXT_COLOR;
            mBlinkCount = (mBlinkCount + 1) % 20;
            drawBoxText(dc, boxY, [Ui.loadResource(Rez.Strings.syncing)], Gfx.COLOR_BLUE, textColor);
        } else if (app.areActionsAllowed()) {
            drawBoxText(dc, boxY, [Ui.loadResource(Rez.Strings.ready)],
                        Gfx.COLOR_GREEN, BOX_TEXT_COLOR);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
