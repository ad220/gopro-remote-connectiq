import Toybox.Lang;

// NOTE: replacing switch with if-else would be more memory efficient

class GoProSettings {
    protected var settings as Array<Number>;

    function initialize() {
        settings = [];
    }

    public function getSetting(id as Number) as Number {
        return settings[id];
    }

    public function getSettings() as Array<Number> {
        return settings;
    }

    public function setSetting(id as Number, value as Number) {
        settings[id] = value;
    }

    public function getDescription() as String {
        if (settings.size() != 4) {
            return "...";
        }
        // System.println(settings);
        var frLabel = MainResources.settingLabels[FRAMERATE][settings[FRAMERATE]];
        return MainResources.settingLabels[RESOLUTION][settings[RESOLUTION]] \
            + "@" + frLabel.substring(0, frLabel.length()-4) + " " \
            + MainResources.settingLabels[RATIO][settings[RATIO]];
    }

    public function save() {
        // Implemented in subclasses
    }
}