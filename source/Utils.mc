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

    // Split a string into items using a given array of separators
    //
    // Parameters:
    //      string(String): a string to split
    //      separators(Array): characters to split on, defaults to space,
    //          newline and return. (NOTE: Monkey C doesn't yet support the
    //          "\t" and "\f" escape characters so we can't split on tabs for
    //          formfeeds)
    //
    //  Returns:
    //      (Array): an array of strings split using `separators` array
    function split(string, separators) {
        if (separators == null) {
            separators = [" ", "\n", "\r"];
        }
        var items = new [0];
        var curItem = "";
        for (var i=0; i < string.length(); i++) {
            var c = string.substring(i, i + 1);
            var separatorHit = false;

            for (var j=0; j < separators.size(); j++) {
                if (c.equals(separators[j])) {
                    if (curItem.length() > 0) {
                        // Add item
                        items.add(curItem);
                        curItem = "";
                    }
                    separatorHit = true;
                    break;
                }
            }
            if (!separatorHit) {
                curItem += c;
            }
        }

        // Handle any curItem residue
        if (curItem.length() > 0) {
            items.add(curItem);
        }

        return items;
    }
}