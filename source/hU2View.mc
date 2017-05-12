using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;

class hU2View extends Ui.View {
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

    hidden function drawBoxText(dc, x, y, font, lines, textColor, boxColor, margin, radius) {
        var textHeight = 0;
        var textMaxWidth = 0;
        for (var i=0; i < lines.size(); i++) {
            var dim = dc.getTextDimensions(lines[i], font);
            if (dim[0] > textMaxWidth) {
                textMaxWidth = dim[0];
            }
            textHeight += dim[1];
        }

        var width = textMaxWidth + 2 * margin;
        var height = textHeight + 2 * margin;

        var boxX = x - (width / 2);
        var boxY = y - (height / 2);

        // Draw box
        dc.setColor(boxColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(boxX, boxY, width, height, radius);

        // Draw text
        dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);

        y -= textHeight / 2;
        for (var i=0; i < lines.size(); i++) {
            var dim = dc.getTextDimensions(lines[i], font);
            dc.drawText(x, y, font, lines[i], Gfx.TEXT_JUSTIFY_CENTER);
            y += dim[1];
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

    hidden function drawSyncing(dc, y) {
        var textColor = Gfx.COLOR_WHITE;
        if (mBlinkCount > 10) {
            textColor = Gfx.COLOR_BLUE;
        }
        // 20 means 10 ticks on, 10 ticks off
        mBlinkCount = (mBlinkCount + 1) % 20;
        var lines = [Ui.loadResource(Rez.Strings.syncing)];
        drawBoxText(dc, dc.getWidth() / 2, y, Gfx.FONT_MEDIUM,
                                     lines, textColor, Gfx.COLOR_BLUE,
                                     BOX_MARGIN, BOX_RADIUS);
    }

    hidden function drawReady(dc, y) {
        var lines = [Ui.loadResource(Rez.Strings.ready)];
        drawBoxText(dc, dc.getWidth() / 2, y, Gfx.FONT_MEDIUM,
                                     lines, Gfx.COLOR_WHITE, Gfx.COLOR_GREEN,
                                     BOX_MARGIN, BOX_RADIUS);


    }

    hidden function drawPhoneNotConnected(dc, y) {
        var lines = [Ui.loadResource(Rez.Strings.phone_not_connected0),
                     Ui.loadResource(Rez.Strings.phone_not_connected1)];
        drawBoxText(dc, dc.getWidth() / 2, y, Gfx.FONT_MEDIUM,
                                     lines, Gfx.COLOR_WHITE, Gfx.COLOR_RED,
                                     BOX_MARGIN, BOX_RADIUS);
    }

    hidden function drawPressButtonOnHue(dc, y) {
        var lines = [Ui.loadResource(Rez.Strings.press_button0),
                     Ui.loadResource(Rez.Strings.press_button1)];
        drawBoxText(dc, dc.getWidth() / 2, y, Gfx.FONT_MEDIUM,
                                     lines, Gfx.COLOR_WHITE, Gfx.COLOR_BLUE,
                                     BOX_MARGIN, BOX_RADIUS);

    }

    hidden function drawDiscoveringBridge(dc, y) {
        var textColor = Gfx.COLOR_WHITE;
        if (mBlinkCount > 10) {
            textColor = Gfx.COLOR_BLUE;
        }
        // 20 means 10 ticks on, 10 ticks off
        mBlinkCount = (mBlinkCount + 1) % 20;
        var lines = [Ui.loadResource(Rez.Strings.discovering_bridge0),
                     Ui.loadResource(Rez.Strings.discovering_bridge1)];
        drawBoxText(dc, dc.getWidth() / 2, y, Gfx.FONT_MEDIUM,
                                     lines, textColor, Gfx.COLOR_BLUE,
                                     BOX_MARGIN, BOX_RADIUS);
    }

    hidden function drawNoBridge(dc, y) {
        var lines = [Ui.loadResource(Rez.Strings.no_bridge0),
                     Ui.loadResource(Rez.Strings.no_bridge1)];
        drawBoxText(dc, dc.getWidth() / 2, y, Gfx.FONT_MEDIUM,
                                     lines, Gfx.COLOR_WHITE, Gfx.COLOR_RED,
                                     BOX_MARGIN, BOX_RADIUS);
    }

    hidden function drawInit(dc, y) {
        var lines = [Ui.loadResource(Rez.Strings.init)];
        drawBoxText(dc, dc.getWidth() / 2, y, Gfx.FONT_MEDIUM,
                                     lines, Gfx.COLOR_WHITE, Gfx.COLOR_BLUE,
                                     BOX_MARGIN, BOX_RADIUS);
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
            drawInit(dc, boxY);
        } else if (state == app.AS_NO_BRIDGE) {
            drawNoBridge(dc, boxY);
        } else if (state == app.AS_DISCOVERING_BRIDGE) {
            drawDiscoveringBridge(dc, boxY);
        } else if (state == app.AS_NO_USERNAME || state == app.AS_REGISTERING) {
            drawPressButtonOnHue(dc, boxY);
        } else if (state == app.AS_PHONE_NOT_CONNECTED) {
            drawPhoneNotConnected(dc, boxY);
        } else if (state == app.AS_FETCHING) {
            drawSyncing(dc, boxY);
        } else if (app.areActionsAllowed()) {
            drawReady(dc, boxY);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
