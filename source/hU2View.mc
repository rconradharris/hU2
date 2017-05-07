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
    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        dc.clear();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);

        var y = 5;

        y += drawCenteredText(dc, y, Gfx.FONT_TINY, Ui.loadResource(Rez.Strings.AppName));
        y += drawCenteredText(dc, y, Gfx.FONT_TINY, Ui.loadResource(Rez.Strings.AppDescription));

        var text = "-";
        var app = Application.getApp();
        var state = app.getState();
        if (state == app.AS_NO_BRIDGE) {
            text = "No Bridge";
        } else if (state == app.AS_DISCOVERING_BRIDGE) {
            text = "Discovering Bridge";
        } else if (state == app.AS_NO_USERNAME) {
            text = "Press Button on Hue";
        } else if (state == app.AS_REGISTERING) {
            text = "Registering";
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
