using Toybox.Graphics as Gfx;

module Utils {
    hidden const DROP_SHADOW_PX = 2;
    hidden const DROP_SHADOW_COLOR = Gfx.COLOR_DK_GRAY;

    function drawTextWithDropShadow(dc, x, y, font, text, justification, textColor) {
        // Draw shadow
        dc.setColor(DROP_SHADOW_COLOR, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x + DROP_SHADOW_PX, y + DROP_SHADOW_PX, font, text, justification);

        // Draw text
        dc.setColor(textColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, justification);
    }

}