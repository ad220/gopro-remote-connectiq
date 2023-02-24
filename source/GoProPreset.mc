import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;


class GoProPreset extends GoProSettings {
    private var id;
    private var name;
    private var icon;

    public static const names = ["Preset 1", "Preset 2", "Preset 3"];

    public function initialize(_id) {
        id = "preset#"+_id;
        //TODO: get name and icon from settings v2
        name = names[_id];
        icon = GoProResources.icons[EDITABLES][_id];
        GoProSettings.initialize();

        try {
            settings = Application.Storage.getValue(id);
        } catch (exception) { //TODO: fix this shit
            settings = [_4K, _8R7, _LARGE, _60];
        }

        if (settings==null) {
            settings = [_4K, _8R7, _LARGE, _60];
        }

        //TODO: change initialize with params when BT implemented
    }

    public function savePreset() {
        Application.Storage.setValue(id, settings);
    }

    public function getName() as String {
        return name;
    }

    public function getIcon() as Bitmap {
        return icon;
    }
}