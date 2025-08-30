import Toybox.Lang;

class GoProCamera extends GoProSettings {

    public enum StatusId {
        BATTERY             = 2,
        OVERHEATING         = 6,
        BUSY                = 8,
        ENCODING            = 10,
        ENCODING_DURATION   = 13,
        READY               = 82,
        COLD                = 85,

    }

    public enum CommandId {
        SHUTTER     = 0x01,
        SLEEP       = 0x05,
        HILIGHT     = 0x18,
        KEEP_ALIVE  = 0x5B,
    }

    private var timer;
    private var goproRequestQueue;
    private var disconnectCallback;
    private var statuses as Dictionary;
    private var availableSettings as Dictionary;
    private var progressTimer as TimerCallback?;


    public function initialize(timer as TimerController, requestQueue as GattRequestQueue, disconnectCallback as Method() as Void) {
        GoProSettings.initialize();
        
        self.timer = timer;
        self.goproRequestQueue = requestQueue;
        self.disconnectCallback = disconnectCallback;
        self.statuses = {ENCODING => 0};
        self.availableSettings = {};
    }

    public function sendCommand(command as CommandId) as Void {
        var request = [0xFF, command];
        if (command==SHUTTER) {
            request.addAll([0x01, isRecording() ? 1 : 0]);
        }
        request[0] = request.size()-1;
        goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.COMMAND_CHARACTERISTIC, request);
    }

    public function sendSetting(id as GoProSettings.SettingId, value as Number) as Void {
        var request = [0x03, id, 0x01, value];
        settings.put(id, value);
        goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.SETTINGS_CHARACTERISTIC, request);
    }

    public function sendPreset(preset as Dictionary) as Void {
        var request = [0xff];
        var keys = preset.keys();
        for (var i=0; i<keys.size(); i++) {
            if (settings.get(keys[i]) != preset.get(keys[i])) {
                request.addAll([keys[i], 0x01, preset.get(keys[i])]);
            }
        }
        settings = preset;
        request[0] = request.size()-1;
        goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.SETTINGS_CHARACTERISTIC, request);        
    }

    public function onReceiveSetting(id as Number, value as ByteArray) as Void {
        settings.put(id, value[0]);
    }

    public function onReceiveStatus(id as Number, value as ByteArray) as Void {
        if (id==ENCODING) {
            if (value==1) {
                var request = [0x02, GoProDelegate.GET_STATUS, ENCODING_DURATION];
                statuses.put(ENCODING_DURATION, 0);
                goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.QUERY_CHARACTERISTIC, request);
                progressTimer = timer.start(method(:incrementEncodingDuration), 2, true);
            } else {
                timer.stop(progressTimer);
            }
        }
        statuses.put(id, value[0]);
        if (statuses[ENCODING]==null) {statuses[ENCODING] = 0;}
    }

    public function onReceiveAvailable(id as Number, value as ByteArray) as Void {
        availableSettings.put(id, value);
    }

    public function getStatus(id as StatusId) as Number? {
        return statuses.get(id);
    }

    public function getAvailableSettings(id as GoProSettings.SettingId) as ByteArray? {
        return availableSettings.get(id);
    }

    public function isRecording() as Boolean {
        return statuses.get(ENCODING)==1;
    }

    public function incrementEncodingDuration() as Void {
        if (isRecording()) {
            statuses[ENCODING_DURATION]++;
            WatchUi.requestUpdate();
        }
    }

    public function disconnect() as Void {
        disconnectCallback.invoke();
    }
}