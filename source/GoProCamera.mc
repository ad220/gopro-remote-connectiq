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
}