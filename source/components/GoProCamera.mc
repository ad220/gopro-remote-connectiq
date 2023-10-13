import Toybox.Lang;

class GoProCamera extends GoProSettings {
    private var states as Array<Number>?;
    private var settingsSave as Array<Number>?;

    private var progress = 0 as Number;
    private var connected = false as Boolean;

    public function initialize() {
        GoProSettings.initialize();
        states = [NTSC, 0];
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
        if (states[RECORDING]==null) {states[RECORDING] = 0;}
        // TODO: conditional label reload
        // MainResources.loadSettingLabels();
        WatchUi.requestUpdate();
    }

    public function isRecording() {
        return states[RECORDING]==1;
    }

    public function getRegion() {
        return states[REGION];
    }

    public function save() {
        mobile.send([COM_PUSH_SETTINGS, settings]);
    }

    public function syncProgress(_progress as Number) {
        progress = _progress;
        WatchUi.requestUpdate();
    }

    public function getProgress() {
        return progress;
    }

    public function incrementProgress() {
        progress++;
    }

    public function isConnected() {
        return connected;
    }

    public function setConnected(_connected as Boolean) {
        connected = _connected;
    }
}