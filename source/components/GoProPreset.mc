import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;


class GoProPreset extends GoProSettings {
    private var id;

    public function initialize(id as Char) {
        self.id = "preset#"+id.toNumber();
        GoProSettings.initialize();

        try {
            self.settings = Application.Storage.getValue(self.id);
        } catch (exception) {
            // Not an exception on every watch, therefore separate initiation below
            System.println(exception.getErrorMessage());
        }
        if (self.settings==null or self.settings.isEmpty()) {
            // Default presets defined below
            self.settings = [
                // 4K 16:9, linear, 24fps
                {RESOLUTION => 1, LENS => LINEAR, FRAMERATE => 10, FLICKER => HZ50, RATIO => 1},
                // 2K7 16:9, wide, 50fps
                {RESOLUTION => 4, LENS => WIDE, FRAMERATE => 6, FLICKER => HZ50, RATIO => 4},
                // 1080p 16:9, large, 25fps
                {RESOLUTION => 9, LENS => LINEAR, FRAMERATE => 9, FLICKER => HZ50, RATIO => 9},
            ][id as Number];
        } 
    }

    public function sync(settings as GoProSettings) {
        self.settings = settings.getSettings();
        Application.Storage.setValue(id, self.settings);
    }
}