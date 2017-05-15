using Toybox.Application;

module PropertyStore {
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