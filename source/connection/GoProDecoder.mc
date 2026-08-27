import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using ErrorManager as EM;
using GattProfileManager as GPM;

class GoProDecoder {

    public static enum QueryId {
        GET_SETTING             = 0x12,
        GET_STATUS              = 0x13,
        GET_SETTING_2B          = 0x15,
        GET_STATUS_2B           = 0x16,
        GET_AVAILABLE           = 0x32,
        REGISTER_SETTING        = 0x52,
        REGISTER_STATUS         = 0x53,
        REGISTER_SETTING_2B     = 0x55,
        REGISTER_STATUS_2B      = 0x56,
        REGISTER_AVAILABLE      = 0x62,
        UNREGISTER_SETTING      = 0x72,
        UNREGISTER_STATUS       = 0x73,
        UNREGISTER_SETTING_2B   = 0x75,
        UNREGISTER_STATUS_2B    = 0x76,
        UNREGISTER_AVAILABLE    = 0x82,
        NOTIF_SETTING           = 0x92,
        NOTIF_STATUS            = 0x93,
        NOTIF_SETTING_2B        = 0x95,
        NOTIF_STATUS_2B         = 0x96,
        NOTIF_AVAILABLE         = 0xA2,
    }

    private static enum QueryType {
        QTYPE_SETTING,
        QTYPE_STATUS,
        QTYPE_AVAILABLE,
    }
    
    public static const OLD_SETTINGS   = [
        GoProSettings.FOV, 
        GoProSettings.FORMAT, 
        GoProSettings.EIS,
        GoProSettings.PHOTO_RES,
    ]b;

    public static const NEW_SETTINGS   = [
        GoProSettings.LENS,
        GoProSettings.FLICKER,
        GoProSettings.HYPERSMOOTH,
        GoProSettings.PHOTO_LENS,
    ]b;


    private var goproId             as Number;
    private var queryResponseBuffer as ByteArray?;
    private var queryResponseLength as Number?;

    function initialize(goproId as Number) {
        self.goproId = goproId;
    }


    (:ble)
    static function getGoProId(device as Ble.ScanResult) as Number {
        var raw_id = device.getRawData()[13];
        var id = GoProCamera.modelIdTable.indexOf(raw_id);
        if (id == -1) {
            EM.raise(EM.ERR_CAM | EM.SUB_CAM_ID | 0x0F << 16, raw_id, :SilentErr);
            id = 0;
        }
        return id;
    }

    function enableNotifications(dlgt as CameraDelegate) as Void {
        dlgt.send(GattRequestQueue.REGISTER_NOTIFICATION, GPM.UUID_COMMAND_RESPONSE_CHAR, [0x01, 0x00]b);
        dlgt.send(GattRequestQueue.REGISTER_NOTIFICATION, GPM.UUID_SETTINGS_RESPONSE_CHAR, [0x01, 0x00]b);
        dlgt.send(GattRequestQueue.REGISTER_NOTIFICATION, GPM.UUID_QUERY_RESPONSE_CHAR, [0x01, 0x00]b);
    }

    function encodeSettings(id as GoProSettings.SettingId, value as Number) as ByteArray {      
        if (goproId < GoProCamera.GP_MAX) {
            var idx = NEW_SETTINGS.indexOf(id);
            if (idx != -1) { id = OLD_SETTINGS[idx]; }
        }

        var request = goproId == GoProCamera.GP_MISSION1 or goproId == GoProCamera.GP_MISSION1PRO ?
            [0x05, 0xFF, 0x00]b : [0x03]b;
        request.addAll([id as Number, 0x01, value]b);

        return request;
    }

    function decodeSettings(id as Number or GoProSettings.SettingId, value as ByteArray)
            as [Number or GoProSettings.SettingId, Number]
    {
        var idx = OLD_SETTINGS.indexOf(id);
        if (idx != -1) { id = NEW_SETTINGS[idx]; }

        return [id, value[0]];
    }

    function encodeCommand(command as GoProCamera.CommandId) as ByteArray {
        var request = [0xFF, command as Number]b;
        var cam = getApp().gopro;

        if      (command == GoProCamera.SHUTTER) {
            request.addAll([0x01, cam.isRecording() ? 0x00 : 0x01]);
        }
        else if (command == GoProCamera.SWITCH_MODE) {
            var mode = cam.getStatus(GoProCamera.CAPTURE_MODE);
            if (mode == null) { mode = 0; }
            request.addAll([0x01, mode ^ 0x01]);
        }

        request[0] = request.size()-1;
        return request;
    }

    function decodeStatus(id as Number or GoProCamera.StatusId, value as ByteArray) 
        as [Number or GoProCamera.StatusId,  Number]
    {
        if (id == GoProCamera.ENCODING_DURATION
            or id == GoProCamera.SD_REMAINING
            or id == GoProCamera.PHOTOS_TAKEN)
        {
            value = value.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:endianness => Lang.ENDIAN_BIG}) as Number;
        } else {
            value = value[0];
        }

        return [id, value];
    }

    function encodeQuery(queryId as QueryId, values as ByteArray) as ByteArray {
        var idsSize = values.size();
        var request = [idsSize + 1, queryId as Number]b;
        
        if (goproId == GoProCamera.GP_MISSION1 or goproId == GoProCamera.GP_MISSION1PRO) {
            idsSize *= 2;

            if ((queryId & 0x1F) ^ 0x02 != 0 and queryId != 0x32) { queryId += 3; }
            request = [idsSize + 1, queryId as Number]b;

            var idsBuffer = new [idsSize]b;

            for (var i=0; i<idsSize; i+=2) {
                idsBuffer[i+1]  = values[i >> 1];
            }

            values = idsBuffer;
        }

        if (goproId < GoProCamera.GP_MAX and queryId & 0xF == 0x2) {
            var idx;
            for (var i=0; i<NEW_SETTINGS.size(); i+=1) {
                idx = values.indexOf(NEW_SETTINGS[i]);
                if (idx != -1) { values[idx] = OLD_SETTINGS[i]; }
            }
        }

        request.addAll(values);
        return request;
    }

    function decodeQuery(response as ByteArray) as Void {
        if      (response[0] & 0xe0 == 0x00) { // 5-bit length packets
            readTLVMessage(response.slice(1, null));
        }
        else if (response[0] & 0xe0 == 0x20) { // 13-bit length packet
            queryResponseLength = ((response[0] & 0x1f) << 8) + response[1];
            queryResponseBuffer = response.slice(2, null);
        }
        else if (response[0] & 0xe0 == 0x40) { // 16-bit length packet
            queryResponseLength = (response[1] << 8) + response[2];
            queryResponseBuffer = response.slice(3, null);
        }
        else if ((response[0] & 0x80) == 0x80) { // Continuation packet
            if (queryResponseBuffer == null) {
                EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | 0x03 << 16, 0, :WarningErr); 
                return;
            }

            queryResponseBuffer.addAll(response.slice(1, null));
            if (queryResponseBuffer.size() == queryResponseLength) {
                readTLVMessage(queryResponseBuffer);
            }
        }
    }

    private function readTLVMessage(message as ByteArray) as Void {
        if (message.size()<2) {
            // System.println("[WARNING]   TLV Message too short");
            return;
        }
        var gopro = Helper.safeGoProAccess(3);
        if (gopro == null) { return; }

        var queryId = message[0];
        var status = message[1];
        var data = message.slice(2, null);
        var queryType = null;

        if (status != 0) {
            // Error flag switched to warning because never raised as of v4.2.7
            EM.raise(EM.ERR_MSG | EM.SUB_MSG_STATUS | 0x00 << 16, 0, :WarningErr);
            // System.println("[WARNING]   Wrong query status received from camera, value: " + status);
        }
        
        var mask = queryId & 0x1F;
        if      (mask ^ 0x12 == 0 and queryId != 0x32 or mask ^ 0x15 == 0)  { queryType = QTYPE_SETTING; }
        else if (mask ^ 0x13 == 0 or mask ^ 0x16 == 0)                      { queryType = QTYPE_STATUS; }
        else if (mask ^ 0x02 == 0 or queryId == 0x32)                       { queryType = QTYPE_AVAILABLE; }
        else {
            // Error flag switched to warning because never raised as of v4.2.7
            EM.raise(EM.ERR_MSG | EM.SUB_MSG_QUERY | 0x00 << 16, 0, :WarningErr);
            // System.println("[WARNING]   Unknown queryId: " + queryId);
            return;
        }

        var type;
        var length;
        var value;
        var tuple;
        var decoder = queryType == QTYPE_STATUS ? :decodeStatus : :decodeSettings;
        var receiver = [:onReceiveSetting, :onReceiveStatus, :onReceiveAvailable][queryType];

        for (var i=0; i<data.size(); i+=2+length) {
            type = data[i];
            if (type == 0xFF) {
                i += 2;

                try { type = data[i]; } catch (ex) {
                    EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | 0x05 << 16, 0, :WarningErr);
                    break;
                }
            }

            try { length = data[i+1]; } catch (ex) {
                EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | 0x04 << 16, 0, :WarningErr);
                break;
            }

            if (length == 0) {
                EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | queryType << 16, type, :SilentErr);
            }

            value = data.slice(i+2, i+2+length);

            tuple = method(decoder).invoke(type, value) as [Number, Number];
            gopro.method(receiver).invoke(tuple[0], tuple[1]);
        }

        if      (receiver == :onReceiveAvailable) {
            gopro.applyAvailableSettings();
        }
        else if (receiver == :onReceiveSetting) {
            gopro.updateDescription();
        }
        $.Toybox.WatchUi.requestUpdate();
    }

    public function decodeMessage(charId as GPM.GoProUuid, msg as ByteArray) as Void {
        if (charId == GPM.UUID_QUERY_RESPONSE_CHAR) {
            decodeQuery(msg);
        }
    }
}
