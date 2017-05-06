using Toybox.Application;

module PropertyStore {
    enum {
        PROP_BRIDGE_IP            = -1,
        PROP_USERNAME             = -2,
        PROP_LIGHT_IDS            = -3
    }

    function get(key) {
        return Application.getApp().getProperty(key);
    }

    function set(key, value) {
        Application.getApp().setProperty(key, value);
    }

    function delete(key) {
        Application.getApp().deleteProperty(key);
    }

    function clear() {
        Application.getApp().clearProperties();
    }
}