// This is a total hack.
//
// onMenuItem requires a Symbol to be passed to it. It doesn't appear that
// dynamically created Symbols work. To work around this, we create statically
// allocated Symbols and dynamically map them to the desired values we want to
// pass into onItem but can't
module DynamicMenu {
    hidden var mLookup = null;
    hidden var mIdx = null;

    function allocate() {
        mIdx = 0;
        mLookup = {
            :dm0 => null,
            :dm1 => null,
            :dm2 => null,
            :dm3 => null,
            :dm4 => null,
            :dm5 => null,
            :dm6 => null,
            :dm7 => null,
            :dm8 => null,
            :dm9 => null
        };
    }

    function free() {
        mIdx = null;
        mLookup = null;
    }

    function set(value) {
        var item = null;
        var i = mIdx;
        if (i == 0) {
            item = :dm0;
        } else if (i == 1) {
            item = :dm1;
        } else if (i == 2) {
            item = :dm2;
        } else if (i == 3) {
            item = :dm3;
        } else if (i == 4) {
            item = :dm4;
        } else if (i == 5) {
            item = :dm5;
        } else if (i == 6) {
            item = :dm6;
        } else if (i == 7) {
            item = :dm7;
        } else if (i == 8) {
            item = :dm8;
        } else if (i == 9) {
            item = :dm9;
        }
        if (item != null) {
            mLookup[item] = value;
            mIdx++;
        }
        return item;
    }

    function get(item) {
        return mLookup[item];
    }
}