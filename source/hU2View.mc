using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System;

class hU2View extends Ui.View {

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
        y += drawCenteredText(dc, y, Gfx.FONT_TINY, Ui.loadResource(Rez.Strings.AppDescription));

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        var text = "-";
        var app = Application.getApp();
        var state = app.getState();
        if (state == app.AS_NO_BRIDGE) {
            text = "No Bridge";
        } else if (state == app.AS_DISCOVERING_BRIDGE) {
            text = "Discovering Bridge";
        } else if (state == app.AS_NO_USERNAME || state == app.AS_REGISTERING) {
            text = "Press Button on Hue";
        } else if (state == app.AS_PHONE_NOT_CONNECTED) {
            text = "Phone Not Connected";
        } else if (state == app.AS_SYNCING) {
            text = "Syncing";
        } else if (state == app.AS_READY) {
            text = "Ready";
        }
        y += drawCenteredText(dc, dc.getHeight() / 2, Gfx.FONT_MEDIUM, text);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
