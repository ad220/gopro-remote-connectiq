class GoProCamera extends GoProSettings {
    private var recording;

    public function initialize() {
        GoProSettings.initialize();
        recording=false;
    }

    public function pressShutter() {
        recording = !recording;
    }

    public function isRecording() {
        return recording;
    }
}