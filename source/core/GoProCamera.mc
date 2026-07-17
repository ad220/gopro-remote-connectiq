import Toybox.Lang;

using GattProfileManager as GPM;
using ErrorManager as EM;

class GoProCamera extends GoProSettings {

    typedef TAvailableSettings as Dictionary<Number, Array<Number>>;

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
    private     var goproId                 as Number;
    protected   var statuses                as Dictionary<StatusId or Number, Number>;
    protected   var availableSettings       as TAvailableSettings;
    private     var availableRatios         as TAvailableSettings;
    private     var tmpAvailableSettings    as TAvailableSettings;
    protected   var progressTimer           as TimerCallback?;


    public function initialize(delegate as CameraDelegate, goproId as Number) {
        GoProSettings.initialize();
        
        self.delegate = delegate;
        self.goproId = goproId;
        self.statuses               = {}    as Dictionary<StatusId or Number, Number>;
        self.availableSettings      = {}    as TAvailableSettings;
        self.availableRatios        = {}    as TAvailableSettings;
        self.tmpAvailableSettings   = {}    as TAvailableSettings;
    }

    public function registerSettings() as Void {
        delegate.send(GattRequestQueue.REGISTER_NOTIFICATION, GPM.UUID_COMMAND_RESPONSE_CHAR, [0x01, 0x00]b);
        delegate.send(GattRequestQueue.REGISTER_NOTIFICATION, GPM.UUID_SETTINGS_RESPONSE_CHAR, [0x01, 0x00]b);
        delegate.send(GattRequestQueue.REGISTER_NOTIFICATION, GPM.UUID_QUERY_RESPONSE_CHAR, [0x01, 0x00]b);
        queryValues(CameraDelegate.REGISTER_SETTING, [GoProSettings.RESOLUTION, GoProSettings.FRAMERATE, GoProSettings.GPS, GoProSettings.LED, GoProSettings.LENS, GoProSettings.FLICKER, GoProSettings.HYPERSMOOTH]b);
        queryValues(CameraDelegate.REGISTER_STATUS, [ENCODING]b);
    }

    public function sendCommand(command as CommandId) as Void {
        var request = [0xFF, command as Number]b;
        if (command==SHUTTER) {
            request.addAll([0x01, isRecording() ? 0x00 : 0x01]);
        }
        request[0] = request.size()-1;
        delegate.send(GattRequestQueue.WRITE_CHARACTERISTIC, GPM.UUID_COMMAND_CHAR, request);
    }

    public function sendSetting(id as GoProSettings.SettingId, value as Number) as Void {
        settings.put(id, value);

        if (goproId < CameraDelegate.GP_MAX) {
            if      (id == GoProSettings.LENS)          { id = GoProSettings.FOV; }
            else if (id == GoProSettings.FLICKER)       { id = GoProSettings.FORMAT; }
            else if (id == GoProSettings.HYPERSMOOTH)   { id = GoProSettings.EIS; }
        }

        var request = goproId == CameraDelegate.GP_MISSION1 or goproId == CameraDelegate.GP_MISSION1PRO ?
            [0x05, 0xFF, 0x00]b : [0x03]b;
        request.addAll([id as Number, 0x01, value]b);

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

    public function queryValues(queryId as CameraDelegate.QueryId, values as ByteArray) as Void {
        var idsSize = values.size();
        var request = [idsSize + 1, queryId as Number]b;
        
        if (goproId == CameraDelegate.GP_MISSION1 or goproId == CameraDelegate.GP_MISSION1PRO) {
            idsSize *= 2;

            if ((queryId & 0x1F) ^ 0x02 != 0 and queryId != 0x32) { queryId += 3; }
            request = [idsSize + 1, queryId as Number]b;

            var idsBuffer = new [idsSize]b;

            for (var i=0; i<idsSize; i+=2) {
                idsBuffer[i+1]  = values[i >> 1];
            }

            values = idsBuffer;
        }

        if (goproId < CameraDelegate.GP_MAX and queryId & 0xF == 0x2) {
            var idx;
            
            idx = values.indexOf(GoProSettings.LENS);
            if (idx != -1)  { values[idx] = GoProSettings.FOV; }

            idx = values.indexOf(GoProSettings.FLICKER);
            if (idx != -1)  { values[idx] = GoProSettings.FORMAT; }

            idx = values.indexOf(GoProSettings.HYPERSMOOTH);
            if (idx != -1)  { values[idx] = GoProSettings.EIS; }
        }

        request.addAll(values);
        delegate.send(GattRequestQueue.WRITE_CHARACTERISTIC, GPM.UUID_QUERY_CHAR, request);
    }

    public function onReceiveSetting(id as Number or GoProSettings.SettingId, value as ByteArray) as Void {
        if (value.size()==0) {
            EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | 0x00 << 16, id as Number, :SilentErr);
            return;
        }

        if      (id == GoProSettings.FOV)           { id = GoProSettings.LENS; }
        else if (id == GoProSettings.FORMAT)        { id = GoProSettings.FLICKER; }
        else if (id == GoProSettings.EIS)           { id = GoProSettings.HYPERSMOOTH; }

        value = value[0];
        settings.put(id as GoProSettings.SettingId, value);
        if (id==RESOLUTION) {
            settings.put(RATIO, value);
            
            var tuple = RESOLUTION_MAP.get(value);
            if (tuple == null) {
                // TODO(photo): this may occur when camera is in photo mode
                EM.raise(
                    EM.ERR_CAM | EM.SUB_CAM_VAL | 0x00 << 16,
                    value << 8 + id,
                    :WarningErr
                );
                return;
            }

            var ratios = availableRatios.get(tuple >> 16);
            if (ratios != null and ratios.size() > 0) { // no error if null because available settings are requested later
                availableSettings.put(RATIO, ratios);
            }
        }
    }

    public function onReceiveStatus(id as Number or StatusId, value as ByteArray) as Void {
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

    public function onReceiveAvailable(id as Number, value as ByteArray) as Void {
        if (value.size()==0) {
            EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | 0x02 << 16, id as Number, :SilentErr);
            return;
        }

        if      (id == GoProSettings.FOV)           { id = GoProSettings.LENS; }
        else if (id == GoProSettings.FORMAT)        { id = GoProSettings.FLICKER; }
        else if (id == GoProSettings.EIS)           { id = GoProSettings.HYPERSMOOTH; }

        value = value[0];
        var available = tmpAvailableSettings.get(id);
        if (available != null) {
            available.add(value);
        } else {
            tmpAvailableSettings.put(id, [value]);
        }
    }

    public function getStatus(id as StatusId or Number) as Number? {
        return statuses.get(id);
    }

    public function getAvailableSettings(id as GoProSettings.SettingId) as Array<Number> {
        var result = availableSettings.get(id);
        return result == null ? [] as Array<Number> : result;
    }

    public function applyAvailableSettings() as Void {
        var tmpKeys = tmpAvailableSettings.keys();
        var tmpValues;
        for (var i=0; i<tmpKeys.size(); i++) {
            tmpValues = tmpAvailableSettings.get(tmpKeys[i]);
            if (tmpValues != null and tmpValues.size()>0) {
                if (tmpKeys[i]==RESOLUTION) {
                    availableRatios = {} as TAvailableSettings;
                    
                    var comp = new ResolutionComparator();
                    Helper.sort(tmpValues as Array, comp);
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

                        if (currentRes == tuple >> 16) {
                            currentMap.add(tmpValues[j]);
                        } else {
                            currentRes = tuple >> 16;
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
                            var avRatios = availableRatios.get(tuple >> 16);
                            if (avRatios != null) { availableSettings.put(RATIO, avRatios); }
                        }
                    }
                } else {
                    availableSettings.put(tmpKeys[i], tmpValues);
                }
            }
        }
        tmpAvailableSettings = {} as Dictionary<Number, Array<Number>>;
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

    public function getGoProId() as Number {
        return goproId;
    }

    public function disconnect() as Void {
        delegate.disconnect();
    }
}