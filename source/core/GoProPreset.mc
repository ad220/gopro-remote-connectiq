import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;


class GoProPreset extends GoProSettings {
    private var id as String;

    public function initialize(id as Char) {
        self.id = "preset#"+id.toNumber();
        GoProSettings.initialize();

        var preset = null;

        try {
            preset = Application.Storage.getValue(self.id) as Dictionary<GoProSettings.SettingId, Char>?;
        } catch (exception) {
            // Not an exception on every watch, therefore separate initiation below
            System.println(exception.getErrorMessage());
        }
        if (preset==null or preset.isEmpty()) {
            // Default presets defined below
            preset = [
                // 4K 16:9, linear, 24fps
                {RESOLUTION => 1, LENS => LINEAR, FRAMERATE => 10, FLICKER => HZ50, RATIO => 1},
                // 2K7 16:9, wide, 50fps
                {RESOLUTION => 4, LENS => WIDE, FRAMERATE => 6, FLICKER => HZ50, RATIO => 4},
                // 1080p 16:9, large, 25fps
                {RESOLUTION => 9, LENS => LINEAR, FRAMERATE => 9, FLICKER => HZ50, RATIO => 9},
            ][id as Number] as Dictionary<GoProSettings.SettingId, Char>;
        } 

        self.settings = preset;
    }

    public function sync() as Void {
        self.settings = getApp().gopro.getSettings();
        Application.Storage.setValue(id, self.settings as Dictionary<PropertyKeyType, PropertyValueType>);
    }
}