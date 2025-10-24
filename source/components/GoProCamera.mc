import Toybox.Lang;

class GoProCamera extends GoProSettings {

    public enum StatusId {
        OVERHEATING         = 6,
        BUSY                = 8,
        ENCODING            = 10,
        ENCODING_DURATION   = 13,
        SD_REMAINING        = 35,
        BATTERY             = 70,
        READY               = 82,
        COLD                = 85,
    }

    public enum CommandId {
        SHUTTER     = 0x01,
        SLEEP       = 0x05,
        HILIGHT     = 0x18,
        KEEP_ALIVE  = 0x5B,
    }

    private var goproRequestQueue as GattRequestQueue;
    protected var disconnectCallback as Method() as Void;
    protected var statuses as Dictionary;
    protected var availableSettings as Dictionary;
    private var availableRatios as Dictionary;
    private var tmpAvailableSettings as Dictionary;
    protected var progressTimer as TimerCallback?;


    public function initialize(requestQueue as GattRequestQueue, disconnectCallback as Method() as Void) {
        GoProSettings.initialize();
        
        self.goproRequestQueue = requestQueue;
        self.disconnectCallback = disconnectCallback;
        self.statuses = {};
        self.availableSettings = {};
        self.availableRatios = {};
        self.tmpAvailableSettings = {};
    }

    public function sendCommand(command as CommandId) as Void {
        var request = [0xFF, command as Char]b;
        if (command==SHUTTER) {
            request.addAll([0x01, isRecording() ? 0x00 : 0x01]);
        }
        request[0] = request.size()-1;
        goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.getUuid(GattProfileManager.UUID_COMMAND_CHAR), request);
    }

    public function sendSetting(id as GoProSettings.SettingId, value as Char) as Void {
        var request = [0x03, id as Char, 0x01, value]b;
        settings.put(id, value);
        goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.getUuid(GattProfileManager.UUID_SETTINGS_CHAR), request);
    }

    public function sendPreset(preset as GoProPreset) as Void {
        var keys = [RESOLUTION, LENS, FRAMERATE];
        for (var i=0; i<3; i++) {
            if (settings.get(keys[i]) != preset.getSetting(keys[i])) {
                sendSetting(keys[i], preset.getSetting(keys[i]));
            }
        }  
    }

    public function requestStatuses(ids as ByteArray) as Void {
        var request = [ids.size()+1, GoProDelegate.GET_STATUS]b;
        request.addAll(ids);
        goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.getUuid(GattProfileManager.UUID_QUERY_CHAR), request);
    }

    public function onReceiveSetting(id as Char, value as ByteArray) as Void {
        settings.put(id, value[0]);
        if (id==RESOLUTION) {
            settings.put(RATIO, value[0]);
            if (availableRatios!={}) {
                availableSettings.put(RATIO, availableRatios.get((RESOLUTION_MAP.get(settings.get(RESOLUTION)) as Array)[0]));
                System.println("set available ratios: "+availableSettings.get(RATIO));
            }
        }
    }

    public function onReceiveStatus(id as Char, value as ByteArray) as Void {
        if (id==ENCODING) {
            if (value[0]==1) {
                var request = [0x02, GoProDelegate.GET_STATUS, ENCODING_DURATION]b;
                statuses.put(ENCODING_DURATION, 0);
                goproRequestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.getUuid(GattProfileManager.UUID_QUERY_CHAR), request);
                System.println("starting progress timer");
                progressTimer = getApp().timerController.start(method(:incrementEncodingDuration), 2, true);
            } else {
                getApp().timerController.stop(progressTimer);
            }
        }
        if (id==ENCODING_DURATION or id==SD_REMAINING) {
            statuses.put(id, value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:endianness => Lang.ENDIAN_BIG}));
        } else {
            statuses.put(id, value[0]);
        }
        if (statuses[ENCODING]==null) {statuses[ENCODING] = 0;}
    }

    public function onReceiveAvailable(id as Char, value as ByteArray) as Void {
        var available = tmpAvailableSettings.get(id);
        if (available instanceof Array) {
            available.add(value[0]);
        } else {
            tmpAvailableSettings.put(id, [value[0]]);
        }
    }

    public function getStatus(id as StatusId) as Number? {
        return statuses.get(id);
    }

    public function getAvailableSettings(id as GoProSettings.SettingId) as Array? {
        return availableSettings.get(id);
    }

    public function applyAvailableSettings() as Void {
        var tmpKeys = tmpAvailableSettings.keys();
        var tmpValues;
        for (var i=0; i<tmpKeys.size(); i++) {
            tmpValues = tmpAvailableSettings.get(tmpKeys[i]);
            if (tmpValues instanceof Array and tmpValues.size()>0) {
                if (tmpKeys[i]==RESOLUTION) {
                    availableRatios = {};
                    tmpValues.sort(new ResolutionComparator() as Lang.Comparator);
                    var currentRes = -1;
                    var currentMap = [];
                    var availableResolutions = [];
                    for (var j=0; j<tmpValues.size(); j++) {
                        if (currentRes==(RESOLUTION_MAP.get(tmpValues[j]) as Array)[0]) {
                            currentMap.add(tmpValues[j]);
                        } else {
                            currentRes=(RESOLUTION_MAP.get(tmpValues[j]) as Array)[0];
                            currentMap = [tmpValues[j]];
                            availableRatios.put(currentRes, currentMap);
                            availableResolutions.add(tmpValues[j]);
                        }
                    }
                    System.println("available res: "+availableResolutions+"");
                    availableSettings.put(RESOLUTION, availableResolutions);
                    var res = settings.get(RESOLUTION);
                    if (res != null) {
                        availableSettings.put(RATIO, availableRatios.get((RESOLUTION_MAP.get(res) as Array)[0]));
                    }
                } else {
                    availableSettings.put(tmpKeys[i], tmpValues);
                }
            }
        }
        tmpAvailableSettings = {};
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