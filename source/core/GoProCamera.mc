import Toybox.Lang;

using GattProfileManager as GPM;
using ErrorManager as EM;

class GoProCamera extends GoProSettings {

    typedef TAvailableSettings as Dictionary<GoProSettings.SettingId or Char, Array<Char>>;

    public enum StatusId {
        // OVERHEATING         = 6,
        // BUSY                = 8,
        ENCODING            = 10,
        ENCODING_DURATION   = 13,
        SD_REMAINING        = 35,
        BATTERY             = 70,
        // READY               = 82,
        // COLD                = 85,
    }

    public enum CommandId {
        SHUTTER     = 0x01,
        SLEEP       = 0x05,
        HILIGHT     = 0x18,
        KEEP_ALIVE  = 0x5B,
    }

    private     var delegate                as CameraDelegate;
    private     var goproId                 as Char;
    protected   var statuses                as Dictionary<StatusId or Char, Number>;
    protected   var availableSettings       as TAvailableSettings;
    private     var availableRatios         as Dictionary<Numeric, Array<Char>>;
    private     var tmpAvailableSettings    as TAvailableSettings;
    protected   var progressTimer           as TimerCallback?;


    public function initialize(delegate as CameraDelegate, goproId as Char) {
        GoProSettings.initialize();
        
        self.delegate = delegate;
        self.goproId = goproId;
        self.statuses               = {}    as Dictionary<StatusId or Char, Number>;
        self.availableSettings      = {}    as Dictionary<GoProSettings.SettingId or Char, Array<Char>>;
        self.availableRatios        = {}    as Dictionary<Numeric, Array<Char>>;
        self.tmpAvailableSettings   = {}    as Dictionary<GoProSettings.SettingId or Char, Array<Char>>;
    }

    public function registerSettings() as Void {
        delegate.send(GattRequestQueue.REGISTER_NOTIFICATION, GPM.UUID_COMMAND_RESPONSE_CHAR, [0x01, 0x00]b);
        delegate.send(GattRequestQueue.REGISTER_NOTIFICATION, GPM.UUID_SETTINGS_RESPONSE_CHAR, [0x01, 0x00]b);
        delegate.send(GattRequestQueue.REGISTER_NOTIFICATION, GPM.UUID_QUERY_RESPONSE_CHAR, [0x01, 0x00]b);
        subscribeChanges(CameraDelegate.REGISTER_SETTING, [GoProSettings.RESOLUTION, GoProSettings.FRAMERATE, GoProSettings.GPS, GoProSettings.LED, GoProSettings.LENS, GoProSettings.FLICKER, GoProSettings.HYPERSMOOTH]b);
        subscribeChanges(CameraDelegate.REGISTER_STATUS, [ENCODING]b);
    }

    public function sendCommand(command as CommandId) as Void {
        var request = [0xFF, command as Char]b;
        if (command==SHUTTER) {
            request.addAll([0x01, isRecording() ? 0x00 : 0x01]);
        }
        request[0] = request.size()-1;
        delegate.send(GattRequestQueue.WRITE_CHARACTERISTIC, GPM.UUID_COMMAND_CHAR, request);
    }

    public function sendSetting(id as GoProSettings.SettingId, value as Char) as Void {
        var request = [0x03, id as Char, 0x01, value]b;
        settings.put(id, value);
        delegate.send(GattRequestQueue.WRITE_CHARACTERISTIC, GPM.UUID_SETTINGS_CHAR, request);
    }

    public function sendPreset(preset as GoProPreset) as Void {
        var keys = [FLICKER, RESOLUTION, LENS, FRAMERATE];
        for (var i=0; i<keys.size(); i++) {
            var value = preset.getSetting(keys[i]);
            if (settings.get(keys[i]) != value and value != null) {
                sendSetting(keys[i], value);
            }
        }  
    }

    public function requestStatuses(ids as ByteArray) as Void {
        var request = [ids.size()+1, CameraDelegate.GET_STATUS]b;
        request.addAll(ids);
        delegate.send(GattRequestQueue.WRITE_CHARACTERISTIC, GPM.UUID_QUERY_CHAR, request);
    }

    public function subscribeChanges(queryId as CameraDelegate.QueryId, values as ByteArray) as Void {
        var request = [values.size()+1, queryId as Char]b;
        request.addAll(values);
        delegate.send(GattRequestQueue.WRITE_CHARACTERISTIC, GPM.UUID_QUERY_CHAR, request);
    }

    public function onReceiveSetting(id as Char or GoProSettings.SettingId, value as ByteArray) as Void {
        if (value.size()==0) { 
            EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | 0x00 << 16, id as Number, :SilentErr);
            // TODO(raise): confirm level
            return;
        }

        settings.put(id as GoProSettings.SettingId, value[0] as Char);
        if (id==RESOLUTION) {
            settings.put(RATIO, value[0] as Char);

            var tuple = RESOLUTION_MAP.get(value[0] as Char);
            if (tuple == null) {
                EM.raise(
                    EM.ERR_CAM | EM.SUB_CAM_VAL | 0x00 << 16,
                    value[0] << 8 + id as Number,
                    :WarningErr
                );
                // TODO(raise): confirm flag
                return;
            }

            var ratios = availableRatios.get(tuple[0]);
            if (ratios != null and ratios.size() > 0) { // no error if null because available settings are requested later
                availableSettings.put(RATIO, ratios);
            }
        }
    }

    public function onReceiveStatus(id as Char or StatusId, value as ByteArray) as Void {
        if (value.size()==0) { 
            EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | 0x01 << 16, id as Number, :SilentErr);
            return;
        }

        if (id==ENCODING) {
            if (value[0]==1) {
                var request = [0x02, CameraDelegate.GET_STATUS, ENCODING_DURATION]b;
                statuses.put(ENCODING_DURATION, 0);
                delegate.send(GattRequestQueue.WRITE_CHARACTERISTIC, GPM.UUID_QUERY_CHAR, request);
                progressTimer = getApp().timerController.start(method(:incrementEncodingDuration), 5, true);
            } else {
                getApp().timerController.stop(progressTimer);
            }
        }
        if (id==ENCODING_DURATION or id==SD_REMAINING) {
            statuses.put(id, value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:endianness => Lang.ENDIAN_BIG}) as Number);
        } else {
            statuses.put(id, value[0]);
        }
        if (statuses.get(ENCODING) == null) { statuses.put(ENCODING, 0); }
    }

    public function onReceiveAvailable(id as Char, value as ByteArray) as Void {
        if (value.size()==0) {
            EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | 0x02 << 16, id as Number, :SilentErr);
            return;
        }

        var available = tmpAvailableSettings.get(id);
        if (available != null) {
            available.add(value[0] as Char);
        } else {
            tmpAvailableSettings.put(id, [value[0] as Char]);
        }
    }

    public function getStatus(id as StatusId or Char) as Number? {
        return statuses.get(id);
    }

    public function getAvailableSettings(id as GoProSettings.SettingId) as Array<Char> {
        var result = availableSettings.get(id);
        return result == null ? [] : result;
    }

    public function applyAvailableSettings() as Void {
        var tmpKeys = tmpAvailableSettings.keys();
        var tmpValues;
        for (var i=0; i<tmpKeys.size(); i++) {
            tmpValues = tmpAvailableSettings.get(tmpKeys[i]);
            if (tmpValues instanceof Array and tmpValues.size()>0) {
                if (tmpKeys[i]==RESOLUTION) {
                    availableRatios = {} as Dictionary<Numeric, Array<Char>>;
                    Helper.sort(tmpValues as Array, new ResolutionComparator());
                    var currentRes = -1;
                    var currentMap = [];
                    var availableResolutions = [];
                    for (var j=0; j<tmpValues.size(); j++) {
                        var tuple = RESOLUTION_MAP.get(tmpValues[j]);
                        if (tuple == null) {
                            EM.raise(
                                EM.ERR_CAM | EM.SUB_CAM_VAL | 0x01 << 16,
                                tmpValues[j] as Number << 8 + RESOLUTION,
                                :WarningErr
                            );
                            continue;
                        }

                        if (currentRes == tuple[0]) {
                            currentMap.add(tmpValues[j]);
                        } else {
                            currentRes = tuple[0];
                            currentMap = [tmpValues[j]];
                            availableRatios.put(currentRes, currentMap);
                            availableResolutions.add(tmpValues[j]);
                        }
                    }
                    availableSettings.put(RESOLUTION, availableResolutions);

                    var res = settings.get(RESOLUTION);
                    if (res != null) {
                        var tuple = RESOLUTION_MAP.get(res);
                        if (tuple == null) {
                            EM.raise(
                                EM.ERR_CAM | EM.SUB_CAM_VAL | 0x02 << 16,
                                res as Number << 8 + RESOLUTION,
                                :WarningErr
                            );
                        }
                        else {
                            var avRatios = availableRatios.get(tuple[0]);
                            if (avRatios != null) { availableSettings.put(RATIO, avRatios); }
                        }
                    }
                } else {
                    availableSettings.put(tmpKeys[i], tmpValues);
                }
            }
        }
        tmpAvailableSettings = {} as TAvailableSettings;
    }

    public function isRecording() as Boolean {
        return statuses.get(ENCODING) == 1;
    }

    (:typecheck(false))
    public function incrementEncodingDuration() as Void {
        if (isRecording()) {
            statuses[ENCODING_DURATION]++;
            WatchUi.requestUpdate();
        }
    }

    public function getGoProId() as Char {
        return goproId;
    }

    public function disconnect() as Void {
        delegate.disconnect();
    }
}