import Toybox.Lang;

class GoProCamera extends GoProSettings {
    private var recording;

    private var states as Array<Number>?;
    private var settingsSave as Array<Number>?;

    public function initialize() {
        GoProSettings.initialize();
        recording=false;
        states = [NTSC];
    }

    public function setPreset(preset as GoProPreset) {
        mobile.send([COM_PUSH_SETTINGS, preset.getSettings()]);
    }

    public function syncSettings(_settings as Array<Number>) {
        settings = _settings;
        WatchUi.requestUpdate();
    }

    public function syncStates(_states as Array<Number>) {
        states = _states;
        GoProResources.loadSettingLabels();
        WatchUi.requestUpdate();
    }

    public function pressShutter() {
        recording = !recording;
    }

    public function isRecording() {
        return recording;
    }

    public function getRegion() {
        return states[REGION];
    }

    public function save() {
        mobile.send([COM_PUSH_SETTINGS, settings]);
    }
}