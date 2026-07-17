import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;


class GoProPreset extends GoProSettings {
    private var id as String;

    public function initialize(id as Number) {
        self.id = "preset#"+id;
        GoProSettings.initialize();

        var preset = null;

        try {
            preset = Application.Storage.getValue(self.id) as Dictionary<GoProSettings.SettingId, Number>?;
        } catch (exception) {
            // Not an exception on every watch, therefore separate initiation below
            // System.println("[WARNING]   Preset initialize : " + exception.getErrorMessage());
        }
        if (preset==null or preset.isEmpty()) {
            // Default presets defined below
            preset = [
                // 4K 16:9, linear, 24fps
                {RESOLUTION => 1, LENS => LINEAR, FRAMERATE => 10, FLICKER => HZ50},
                // 2K7 16:9, wide, 50fps
                {RESOLUTION => 4, LENS => WIDE, FRAMERATE => 6, FLICKER => HZ50},
                // 1080p 16:9, linear, 25fps
                {RESOLUTION => 9, LENS => LINEAR, FRAMERATE => 9, FLICKER => HZ50},
            ][id as Number] as Dictionary<GoProSettings.SettingId, Number>;
        } 

        self.settings = preset;
    }

    public function sync() as Void {
        var gopro = getApp().gopro;
        var ids = [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE, GoProSettings.FLICKER];
        for (var i=0; i<ids.size(); i+=1) {
            settings[ids[i]] = gopro.getSetting(ids[i]) as Number; // could be null
        }
        Application.Storage.setValue(id, settings as Dictionary<Storage.KeyType, Storage.ValueType>);
    }
}