import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;


class GoProPreset extends GoProSettings {
    private var id;

    public function initialize(_id) {
        id = "preset#"+_id;
        GoProSettings.initialize();

        try {
            settings = Application.Storage.getValue(id);
        } catch (exception) {
            // Not an exception on every watch, therefore separate initiation below
            settings = [0];
        }
        if (settings == null or settings == [0]) {
            // Default presets defined below
            settings = [
                // 4K 16:9, linear, 24fps
                {RESOLUTION => 1, LENS => LINEAR, FRAMERATE => 10, FLICKER => HZ50, RATIO => 1},
                // 2K7 16:9, wide, 50fps
                {RESOLUTION => 4, LENS => WIDE, FRAMERATE => 6, FLICKER => HZ50, RATIO => 4},
                // 1080p 16:9, large, 25fps
                {RESOLUTION => 9, LENS => LINEAR, FRAMERATE => 9, FLICKER => HZ50, RATIO => 9},
            ][_id];
        } 
    }

    public function save() {
        settings = cam.getSettings();
        Application.Storage.setValue(id, settings);
    }
}