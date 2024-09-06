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
        } catch (exception) { //TODO: fix this: should not happen
            settings = [0];
        }
        if (settings == null or settings == [0]) {
            settings = [
                [_5K, _16R9, _LINEARLOCK, _24],
                [_4K, _8R7, _LARGE, _60],
                [_2K, _16R9, _LINEAR, _30]
            ][_id];
        }

        //TODO: change initialize with params when BT implemented
    }

    public function save() {
        Application.Storage.setValue(id, settings);
    }


    public function getSettings() as Array<Number> {
        return settings;
    }
}