import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;


class GoProPreset extends GoProSettings {
    private var id;
    private var name;
    private var icon;
    private var gpSettings as Array<Number>?;

    public static const names = ["Preset 1", "Preset 2", "Preset 3"];

    public function initialize(_id) {
        id = "preset#"+_id;
        //TODO: get name and icon from settings v2
        name = names[_id];
        icon = GoProResources.icons[EDITABLES][_id];

        var app = Application.getApp();
        try {
            gpSettings = app.getProperty(id);
        } catch (exception) { //TODO: fix this shit
            gpSettings = [_4K, _8R7, _LARGE, _60];
        }

        if (gpSettings==null) {
            gpSettings = [_4K, _8R7, _LARGE, _60];
        }

        //TODO: change initialize with params when BT implemented
        GoProSettings.initialize();
        for (var i=0; i<N_SETTINGS; i++) { // i => enum Settings
            setSetting(i, gpSettings[i]);
        }
    }

    public function savePreset() {
        var app = Application.getApp();
        app.setProperty(id, gpSettings);
    }

    public function getName() as String {
        return name;
    }

    public function getIcon() as Bitmap {
        return icon;
    }
}