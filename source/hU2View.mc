using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;

class hU2View extends Ui.View {
    hidden const BOX_MARGIN = 30;
    hidden const BOX_RADIUS = 10;

    // Used to blink 1 out of every 10 timer ticks
    hidden var mSyncBlinkerCount = 0;

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

    hidden function drawCenteredText(dc, y, font, text) {
        var dim = dc.getTextDimensions(text, font);
        dc.drawText(dc.getWidth() / 2, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
        return dim[1];
    }

    hidden function drawCenteredTextInRoundedBox(dc, y, font, text, textColor, boxColor, margin, radius) {
        var dim = dc.getTextDimensions(text, font);
        var width = dim[0] + margin;
        var height = dim[1] + margin;
        var boxX = (dc.getWidth() - width) / 2;
        var boxY = y - (margin / 2);

        // Draw box
        dc.setColor(boxColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(boxX, boxY, width, height, radius);

        // Draw text
        dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, font, text, Gfx.TEXT_JUSTIFY_CENTER);
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

    hidden function drawSyncing(dc) {
        var text = Ui.loadResource(Rez.Strings.syncing);
        var textColor = Gfx.COLOR_WHITE;
        if (mSyncBlinkerCount > 10) {
            textColor = Gfx.COLOR_BLUE;
        }
        mSyncBlinkerCount = (mSyncBlinkerCount + 1) % 20;
        drawCenteredTextInRoundedBox(dc, dc.getHeight() / 2, Gfx.FONT_MEDIUM,
                                     text, textColor, Gfx.COLOR_BLUE,
                                     BOX_MARGIN, BOX_RADIUS);
    }

    hidden function drawReady(dc) {
        var text = Ui.loadResource(Rez.Strings.ready);
        drawCenteredTextInRoundedBox(dc, dc.getHeight() / 2, Gfx.FONT_MEDIUM,
                                     text, Gfx.COLOR_WHITE, Gfx.COLOR_GREEN,
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
        y += drawCenteredText(dc, y, Gfx.FONT_TINY, Ui.loadResource(Rez.Strings.AppDescription));

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        var text = "-";
        var app = Application.getApp();
        var state = app.getState();
        if (state == app.AS_NO_BRIDGE) {
            text = "No Bridge";
            drawCenteredText(dc, dc.getHeight() / 2, Gfx.FONT_MEDIUM, text);
        } else if (state == app.AS_DISCOVERING_BRIDGE) {
            text = "Discovering Bridge";
            drawCenteredText(dc, dc.getHeight() / 2, Gfx.FONT_MEDIUM, text);
        } else if (state == app.AS_NO_USERNAME || state == app.AS_REGISTERING) {
            text = "Press Button on Hue";
            drawCenteredText(dc, dc.getHeight() / 2, Gfx.FONT_MEDIUM, text);
        } else if (state == app.AS_PHONE_NOT_CONNECTED) {
            text = "Phone Not Connected";
            drawCenteredText(dc, dc.getHeight() / 2, Gfx.FONT_MEDIUM, text);
        } else if (state == app.AS_SYNCING) {
            drawSyncing(dc);
        } else if (state == app.AS_READY) {
            drawReady(dc);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
