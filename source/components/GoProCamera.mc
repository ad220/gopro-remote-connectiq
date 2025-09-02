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

    protected var timer;
    private var goproRequestQueue;
    protected var disconnectCallback;
    protected var statuses as Dictionary;
    protected var availableSettings as Dictionary;
    private var tmpAvailableSettings as Dictionary;
    protected var progressTimer as TimerCallback?;


    public function initialize(timer as TimerController, requestQueue as GattRequestQueue, disconnectCallback as Method() as Void) {
        GoProSettings.initialize();
        
        self.timer = timer;
        self.goproRequestQueue = requestQueue;
        self.disconnectCallback = disconnectCallback;
        self.statuses = {};
        self.availableSettings = {};
        self.tmpAvailableSettings = {};
    }

    public function sendCommand(command as CommandId) as Void {
        var request = [0xFF, command as Number]b;
        if (command==SHUTTER) {
            request.addAll([0x01, isRecording() ? 0x00 : 0x01]);
        }
        request[0] = request.size()-1;
        goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.COMMAND_CHARACTERISTIC, request);
    }

    public function sendSetting(id as GoProSettings.SettingId, value as Number) as Void {
        var request = [0x03, id as Number, 0x01, value]b;
        settings.put(id, value);
        goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.SETTINGS_CHARACTERISTIC, request);
    }

    public function sendPreset(preset as Dictionary) as Void {
        var request = [0xff]b;
        var keys = preset.keys();
        for (var i=0; i<keys.size(); i++) {
            if (settings.get(keys[i]) != preset.get(keys[i])) {
                request.addAll([keys[i], 0x01, preset.get(keys[i])]);
            }
        }
        request[0] = request.size()-1;
        goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.SETTINGS_CHARACTERISTIC, request);        
    }

    public function onReceiveSetting(id as Number, value as ByteArray) as Void {
        settings.put(id, value[0]);
        if (id==RESOLUTION) {
            settings.put(RATIO, value[0]);
        }
    }

    public function onReceiveStatus(id as Number, value as ByteArray) as Void {
        if (id==ENCODING) {
            if (value[0]==1) {
                var request = [0x02, GoProDelegate.GET_STATUS, ENCODING_DURATION]b;
                statuses.put(ENCODING_DURATION, 0);
                goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.QUERY_CHARACTERISTIC, request);
                System.println("starting progress timer");
                progressTimer = timer.start(method(:incrementEncodingDuration), 2, true);
            } else {
                timer.stop(progressTimer);
            }
        }
        if (id==ENCODING_DURATION) {
            statuses.put(id, value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:endianness => Lang.ENDIAN_BIG}));
        } else {
            statuses.put(id, value[0]);
        }
        if (statuses[ENCODING]==null) {statuses[ENCODING] = 0;}
    }

    public function onReceiveAvailable(id as Number, value as ByteArray) as Void {
        var bytes = tmpAvailableSettings.get(id);
        if (bytes instanceof ByteArray) {
            bytes.add(value[0]);
        }
    }

    public function getStatus(id as StatusId) as Number? {
        return statuses.get(id);
    }

    public function getAvailableSettings(id as GoProSettings.SettingId) as ByteArray? {
        return availableSettings.get(id);
    }

    public function resetAvailableSettings() as Void {
        tmpAvailableSettings = {
            RESOLUTION  => []b,
            LENS        => []b,
            FRAMERATE   => []b,
            FLICKER     => []b,
        };
        tmpAvailableSettings.put(RATIO, availableSettings.get(RESOLUTION));
    }

    public function applyAvailableSettings() as Void {
        var tmpKeys = tmpAvailableSettings.keys();
        var tmpValues;
        for (var i=0; i<tmpKeys.size(); i++) {
            tmpValues = tmpAvailableSettings.get(tmpKeys[i]);
            if (tmpValues instanceof ByteArray and !tmpValues.equals([]b)) {
                availableSettings.put(tmpKeys[i], tmpValues);
            }
        }
        resetAvailableSettings();
    }

    public function isRecording() as Boolean {
        return statuses.get(ENCODING)==1;
    }

    public function incrementEncodingDuration() as Void {
        System.println("incr");
        if (isRecording()) {
            System.println(statuses.get(ENCODING_DURATION));
            statuses[ENCODING_DURATION]++;
            System.println(statuses.get(ENCODING_DURATION));
            WatchUi.requestUpdate();
        }
    }

    public function disconnect() as Void {
        disconnectCallback.invoke();
    }
}