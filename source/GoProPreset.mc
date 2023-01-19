import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;


const nameDict = {
    :preset1 => "Preset n°1",
    :preset2 => "Preset n°2",
    :preset3 => "Preset n°3"
};


class GoProPreset extends GoProSettings {
    private var id;
    private var name;
    private var icon;
    private var gpSettings;


    public function initialize(_id) {
        id = _id;
        //TODO: get name and icon from settings v2
        // name = nameDict.get(_id);
        name = "Pretest";
        icon = WatchUi.loadResource(Rez.Drawables.Setting);

        var app = Application.getApp();
        try { 
            gpSettings = app.getProperty(id);
        } catch (exception) {
            gpSettings = {
                :resolution => :_4K,
                :ratio => :_8R7,
                :lens => :_Large,
                :framerate => :_60,
            };
        }

        //TODO: change initialize with params when BT implemented
        GoProSettings.initialize();
        for (var i=0; i<settingsList.size(); i++) {
            setSetting(settingsList[i], gpSettings.get(settingsList[i]));
        }
    }

    public function savePreset() {
        var app = Application.getApp();
        app.setProperty(id, gpSettings);
    }

    public function getName() as String {
        return name;
    }
}