import Toybox.Lang;

class GoProCamera extends GoProSettings {
    private var states as Array<Number>?;
    private var availableSettings as Array<Array<Number>>?;

    private var progress as Number = 0;
    private var connected as Boolean = false;


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
        // var regionChanged = states[REGION]!=_states[REGION];
        states = _states;
        if (states[RECORDING]==null) {states[RECORDING] = 0;}
        // if (regionChanged) {MainResources.loadRegionLabels();}
        WatchUi.requestUpdate();
    }

    public function syncAvailableSettings(_availableSettings as Array<Array<Number>>) {
        availableSettings = _availableSettings;
        WatchUi.requestUpdate();
    }

    public function getAvailableSettings(id as Number) as Array<Number> {
        return availableSettings[id];
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