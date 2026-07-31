import Toybox.Lang;

using GattProfileManager as GPM;
using ErrorManager as EM;
using Toybox.BluetoothLowEnergy as Ble;

class GoProCamera extends GoProSettings {

    public static const modelIdTable = [0, 12, 13, 19, 21, 22, 24, 30, 32, 33, 34, 50, 51, 55, 57, 58, 60, 62, 64, 65, 66, 70, 69, 71]b;

    static const GP_UNKNOWN                 = 0;
    static const GP_HERO4S                  = 1;
    static const GP_HERO4B                  = 2;
    static const GP_HERO5B                  = 3;
    static const GP_HERO5S                  = 4;
    static const GP_FUSION                  = 5;
    static const GP_HERO6B                  = 6;
    static const GP_HERO7B                  = 7;
    static const GP_HERO7W                  = 8;
    static const GP_HERO7S                  = 9;
    static const GP_HERO2018                = 10;
    static const GP_HERO8                   = 11;
    static const GP_MAX                     = 12;
    static const GP_HERO9                   = 13;
    static const GP_HERO10                  = 14;
    static const GP_HERO11                  = 15;
    static const GP_HERO11M                 = 16;
    static const GP_HERO12                  = 17;
    static const GP_MAX2                    = 18;
    static const GP_HERO13                  = 19;
    static const GP_HERO2024                = 20;
    static const GP_HEROLIT                 = 21;
    static const GP_MISSION1PRO             = 22;
    static const GP_MISSION1                = 23;

      
    public static const modelStringTable = [
        :UnknownGP,
        4           /* 01) id:12 -> HERO4 Silver */,
        4           /* 02) id:13 -> HERO4 Black */,
        5           /* 03) id:19 -> HERO5 Black */,
        5           /* 04) id:21 -> HERO5 Session */,
        :Fusion     /* 05) id:22 -> Fusion */,
        6           /* 06) id:24 -> HERO6 Black */,
        7           /* 07) id:30 -> HERO7 Black */,
        7           /* 08) id:32 -> HERO7 White */,
        7           /* 09) id:33 -> HERO7 Silver */,
        2018        /* 10) id:34 -> HERO 2018 */,
        8           /* 11) id:50 -> HERO8 Black */,
        :MAX        /* 12) id:51 -> MAX */,
        9           /* 13) id:55 -> HERO9 Black */,
        10          /* 14) id:57 -> HERO10 Black */,
        11          /* 15) id:58 -> HERO11 Black */,
        11          /* 16) id:60 -> HERO11 Black Mini */,
        12          /* 17) id:62 -> HERO12 Black */,
        :MAX        /* 18) id:64 -> MAX2 */,
        13          /* 19) id:65 -> HERO13 Black */,
        2024        /* 20) id:66 -> HERO (2024) */,
        " Lit"      /* 21) id:70 -> HERO Lit */,
        :Mission1   /* 22) id:69 -> Mission1 Pro */,
        :Mission1   /* 23) id:71 -> Mission1 */,
    ];

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
    private     var decoder                 as GoProDecoder;
    private     var goproId                 as Number;
    protected   var statuses                as Dictionary<StatusId or Number, Number>;
    protected   var availableSettings       as TAvailableSettings;
    private     var availableRatios         as TAvailableSettings;
    private     var tmpAvailableSettings    as TAvailableSettings;
    protected   var progressTimer           as TimerCallback?;


    public function initialize(delegate as CameraDelegate, goproId as Number) {
        GoProSettings.initialize();
        
        self.delegate = delegate;
        self.goproId                = goproId;
        self.decoder                = new GoProDecoder(goproId);
        self.statuses               = {}    as Dictionary<StatusId or Number, Number>;
        self.availableSettings      = {}    as TAvailableSettings;
        self.availableRatios        = {}    as TAvailableSettings;
        self.tmpAvailableSettings   = {}    as TAvailableSettings;

        statuses[ENCODING] = 0;
    }

    public function registerSettings() as Void {
        decoder.enableNotifications(delegate);
        queryValues(GoProDecoder.REGISTER_SETTING, [GoProSettings.RESOLUTION, GoProSettings.FRAMERATE, GoProSettings.GPS, GoProSettings.LED, GoProSettings.LENS, GoProSettings.FLICKER, GoProSettings.HYPERSMOOTH]b);
        queryValues(GoProDecoder.REGISTER_STATUS, [ENCODING]b);
    }

    public function sendCommand(command as CommandId) as Void {
        delegate.send(
            GattRequestQueue.WRITE_CHARACTERISTIC,
            GPM.UUID_COMMAND_CHAR,
            decoder.encodeCommand(command)
        );
    }

    public function sendSetting(id as GoProSettings.SettingId, value as Number) as Void {
        settings.put(id, value);
        delegate.send(
            GattRequestQueue.WRITE_CHARACTERISTIC,
            GPM.UUID_SETTINGS_CHAR,
            decoder.encodeSettings(id, value)
        );
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

    public function queryValues(queryId as GoProDecoder.QueryId, values as ByteArray) as Void {
        delegate.send(
            GattRequestQueue.WRITE_CHARACTERISTIC,
            GPM.UUID_QUERY_CHAR,
            decoder.encodeQuery(queryId, values)
        );
    }

    public function onReceiveSetting(id as Number or GoProSettings.SettingId, value as Number) as Void {
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

    public function onReceiveStatus(id as Number or StatusId, value as Number) as Void {
        if (id == ENCODING) {
            if (value == 1) {
                statuses.put(ENCODING_DURATION, 0);
                queryValues(GoProDecoder.GET_STATUS, [ENCODING_DURATION]b);
                progressTimer = getApp().timerController.start(method(:incrementEncodingDuration), 5, true);
            } else {
                getApp().timerController.stop(progressTimer);
            }
        }

        statuses.put(id, value);
    }

    public function onReceiveAvailable(id as Number, value as Number) as Void {
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
                    Helper.customSort(tmpValues as Array, comp);
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

    public function getId() as Number {
        return goproId;
    }

    public function getDecoder() as GoProDecoder {
        return decoder;
    }

    public function disconnect() as Void {
        delegate.disconnect();
    }
}