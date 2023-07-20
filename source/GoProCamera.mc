import Toybox.Lang;

class GoProCamera extends GoProSettings {
    private var recording;
    private var region;

    public function initialize() {
        GoProSettings.initialize();
        recording=false;
        region=NTSC;
    }

    public function setPreset(preset as GoProPreset) {
        for (var id=0; id<N_SETTINGS; id++) {
            settings[id]=preset.getSetting(id);
        }
        mobile.send([COM_PUSH_SETTINGS, settings]);
    }

    public function syncSettings(_settings as Array<Number>) {
        settings = _settings;
        WatchUi.requestUpdate();
    }

    public function pressShutter() {
        recording = !recording;
    }

    public function isRecording() {
        return recording;
    }

    public function getRegion() {
        return region;
    }

    public function save() {
        mobile.send([COM_PUSH_SETTINGS, settings]);
    }
}