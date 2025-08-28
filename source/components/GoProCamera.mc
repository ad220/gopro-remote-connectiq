import Toybox.Lang;

class GoProCamera extends GoProSettings {

    public enum StateId {
        ENCODING = 10,
    }

    private var states as Dictionary;
    private var availableSettings as Array<Array<Number>>;

    private var progress as Number = 0;
    private var connected as Boolean = false;


    public function initialize() {
        GoProSettings.initialize();

        self.states = {ENCODING => 0};
        self.availableSettings = [];
    }

    public function setPreset(preset as GoProPreset) {
        // mobile.send([MobileDevice.COM_PUSH_SETTINGS, preset.getSettings()]);
    }

    public function syncSettings(settings as Dictionary) {
        self.settings = settings;
        WatchUi.requestUpdate();
    }

    public function syncStates(states as Dictionary) {
        // var regionChanged = states[REGION]!=_states[REGION];
        self.states = states;
        if (states[ENCODING]==null) {states[ENCODING] = 0;}
        // if (regionChanged) {MainResources.loadRegionLabels();}
        WatchUi.requestUpdate();
    }

    public function syncAvailableSettings(availableSettings as Array<Array<Number>>) {
        self.availableSettings = availableSettings;
        WatchUi.requestUpdate();
    }

    public function getAvailableSettings(id as Number) as Array<Number> {
        return availableSettings[id];
    }

    public function isRecording() {
        return states.get(ENCODING)==1;
    }

    public function save() {
        mobile.send([MobileDevice.COM_PUSH_SETTINGS, settings]);
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