import Toybox.Lang;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;

(:debug :ble) class FakeGoProDevice {

    typedef FakeGoProSettings as Dictionary<Number or GoProSettings.SettingId, Number or Number>;
    typedef FakeGoProStatuses as Dictionary<Number or GoProCamera.StatusId, Number>;

    var settings as FakeGoProSettings;
    var statuses as FakeGoProStatuses;
    var specs as FakeGoProSpecs.ISpecs;

    var notifSettings as ByteArray;
    var notifStatuses as ByteArray;
    var notifAvailable as ByteArray;

    var gpControlService as BleAPI.MockService;
    var gpQueryResponseChar as BleAPI.MockCharacteristic;

    var autoSleepTimer as TimerCallback?;
    var hilightCount as Number = 0;

    typedef Message as [GPM.GoProUuid, ByteArray];
    var requests as Array<Message>;
    var processingRequests as Boolean;

    public function initialize(
            settings as FakeGoProSettings,
            statuses as FakeGoProStatuses,
            specs as FakeGoProSpecs.ISpecs
        ) {
        self.settings = settings;
        self.statuses = statuses;
        self.specs = specs;

        self.notifSettings = []b;
        self.notifStatuses = []b;
        self.notifAvailable = []b;
        self.requests = [];
        self.processingRequests = false;

        resetSleepTimer();

        var device = new BleAPI.MockDevice();
        gpControlService = new BleAPI.MockService(Ble.stringToUuid(GPM.GOPRO_CONTROL_SERVICE), device);
        gpQueryResponseChar = new BleAPI.MockCharacteristic(
            GPM.getUuid(GPM.UUID_QUERY_RESPONSE_CHAR),
            gpControlService
        );
    }

    private function resetSleepTimer() as Void {
        if (autoSleepTimer != null) {
            autoSleepTimer.stop();
        }
        autoSleepTimer = getApp().timerController.start(method(:sleep), 40, false);
    }

    public function sleep() as Void {
        BleAPI.delegate.onConnectedStateChanged(
            gpControlService.device as Ble.Device,
            Ble.CONNECTION_STATE_DISCONNECTED
        );
        if (autoSleepTimer != null) {
            autoSleepTimer.stop();
            autoSleepTimer = null;
        }
    }

    public function onSend(msg as Message) as Void {
        requests.add(msg);
    }

    public function processRequests() as Void {
        processingRequests = true;
        while (requests.size() > 0) {
            processMsg(requests[0]);
            requests.remove(requests[0]);
        }
        processingRequests = false;
    }

    private function processMsg(msg as Message) as Void {
        var uuid = msg[0];
        var data = msg[1];
        var response;
        resetSleepTimer();
        
        switch (uuid) {
            case GPM.UUID_QUERY_CHAR:
                var queryId = data[1];
                var decoder = null;
                data = data.slice(2, null);

                switch (queryId) {
                    case GoProDecoder.GET_SETTING:
                    case GoProDecoder.GET_SETTING_2B:
                    case GoProDecoder.REGISTER_SETTING:
                    case GoProDecoder.REGISTER_SETTING_2B:
                    case GoProDecoder.UNREGISTER_SETTING:
                    case GoProDecoder.UNREGISTER_SETTING_2B:
                        decoder = method(:onReceiveSetting);
                        break;
                    case GoProDecoder.GET_STATUS:
                    case GoProDecoder.GET_STATUS_2B:
                    case GoProDecoder.REGISTER_STATUS:
                    case GoProDecoder.REGISTER_STATUS_2B:
                    case GoProDecoder.UNREGISTER_STATUS:
                    case GoProDecoder.UNREGISTER_STATUS_2B:
                        decoder = method(:onReceiveStatus);
                        break;
                    case GoProDecoder.GET_AVAILABLE:
                    case GoProDecoder.REGISTER_AVAILABLE:
                    case GoProDecoder.UNREGISTER_AVAILABLE:
                        decoder = method(:onReceiveAvailable);
                        break;
                    default:
                        // System.println("[DBG WARN]  Unknown queryId: " + queryId.toNumber());
                }
                var isQuery2B = queryId & 0x0F > 3;
                if (decoder instanceof Method) {
                    response = [queryId, 0x00]b;
                    for (var i=0; i<data.size(); i+=1) {
                        if (isQuery2B) { i+=1; }
                        decoder.invoke(data[i], response, queryId);
                    }
                    responseSplitter(GPM.UUID_QUERY_RESPONSE_CHAR, response);
                }
                break;

            case GPM.UUID_COMMAND_CHAR:
                var commandId = data[1];
                switch (commandId) {
                    case GoProCamera.SHUTTER:
                        if (statuses[GoProCamera.CAPTURE_MODE] == GoProCamera.MODE_VIDEO) {
                            statuses.put(GoProCamera.ENCODING, data[3]);
                            responseSplitter(GPM.UUID_COMMAND_RESPONSE_CHAR, [1, 0]b);
                            if (notifStatuses.indexOf(GoProCamera.ENCODING) != -1) {
                                BleAPI.delegate.onCharacteristicChanged(
                                    gpQueryResponseChar as Ble.Characteristic,
                                    [0x05, GoProDecoder.NOTIF_STATUS, 0x00, GoProCamera.ENCODING, 0x01, data[3]]b
                                );
                            }
                        } else {
                            var pt = 1 + statuses[GoProCamera.PHOTOS_TAKEN] as Number;
                            statuses[GoProCamera.PHOTOS_TAKEN] = pt;
                            if (notifStatuses.indexOf(GoProCamera.PHOTOS_TAKEN) != -1) {
                                BleAPI.delegate.onCharacteristicChanged(
                                    gpQueryResponseChar as Ble.Characteristic,
                                    [0x08, GoProDecoder.NOTIF_STATUS, 0x00, GoProCamera.PHOTOS_TAKEN, 0x04, 0, 0, pt >> 8, pt & 0xFF]b
                                );
                            }
                        }
                        break;

                    case GoProCamera.HILIGHT:
                        responseSplitter(GPM.UUID_COMMAND_RESPONSE_CHAR, [commandId, 0]b);
                        hilightCount += 1;
                        break;

                    case GoProCamera.SLEEP:
                        sleep();
                        break;

                    case GoProCamera.SWITCH_MODE:
                        var modeId = GoProCamera.CAPTURE_MODE;
                        statuses.put(modeId, data[3]);
                        if (notifStatuses.indexOf(modeId) != -1) {
                            responseSplitter(
                                GPM.UUID_QUERY_RESPONSE_CHAR,
                                [GoProDecoder.NOTIF_STATUS, 0x00, modeId, 1, data[3]]b
                            );
                        }
                        break;

                    default:
                        break;
                }
                break;

            case GPM.UUID_SETTINGS_CHAR:
                var minSettingChanged = 0xFF;
                response = [GoProDecoder.NOTIF_SETTING, 0x00]b;
                for (var i=1; i<data.size(); i+=2+data[i+1]) {
                    var id = data[i];

                    if (id == 0xFF) {
                        i += 2;
                        id = data[i];
                    }

                    var idx = GoProDecoder.OLD_SETTINGS.indexOf(id);
                    if (idx != -1) { id = GoProDecoder.NEW_SETTINGS[idx]; }

                    var value = data[i+2];

                    settings.put(id, value);
                    if (notifSettings.indexOf(id) != -1) {
                        response.addAll([data[i], 0x01, value]);
                    }
                    minSettingChanged = id == GoProSettings.RESOLUTION ? id : \
                                        id == GoProSettings.LENS and minSettingChanged != GoProSettings.RESOLUTION ? id : \
                                        id == GoProSettings.FRAMERATE and minSettingChanged==0xFF ? id : minSettingChanged;
                }
                responseSplitter(GPM.UUID_SETTINGS_RESPONSE_CHAR, [1, 0]b);
                if (response.size()>2) {
                    responseSplitter(GPM.UUID_QUERY_RESPONSE_CHAR, response);
                }

                response = [GoProDecoder.NOTIF_AVAILABLE, 0x00]b;
                var iter;
                var j;
                var res = settings.get(GoProSettings.RESOLUTION) as Number; // could be null
                var lens = settings.get(GoProSettings.LENS) as Number; // could be null
                switch (minSettingChanged) {
                    case GoProSettings.RESOLUTION:
                        iter = specs.availableSettingsMap.get(res);
                        if (iter == null) { throw new Exception(); }

                        iter = iter.keys();
                        if (iter.indexOf(lens) == -1) {
                            settings.put(GoProSettings.LENS, iter[0]);
                        }
                        if (notifAvailable.indexOf(GoProSettings.LENS) != -1) {
                            var lensId = specs.cameraId < GoProCamera.GP_MAX
                                ? GoProSettings.FOV : GoProSettings.LENS;

                            for (j=0; j<iter.size(); j++) {
                                response.addAll([lensId, 0x01, iter[j]]);
                            }
                        }
                    case GoProSettings.LENS:
                        if (notifAvailable.indexOf(GoProSettings.FRAMERATE) != -1) {
                            iter = specs.availableSettingsMap.get(res);
                            iter = iter!=null ? iter.get(lens) : null;
                            for (j=0; iter!=null and j<iter.size(); j++) {
                                response.addAll([GoProSettings.FRAMERATE, 0x01, iter[j]]);
                            }
                        }
                        break;
                    default:
                        break;
                }
                if (response.size()>2) {
                    responseSplitter(GPM.UUID_QUERY_RESPONSE_CHAR, response);
                }
                break;

            default:
                // System.println("[DBG WARN]  Unknown UUID" + uuid);
                break;
        }
        // garminDevice.whenCharacteristicWrite(uuid, Ble.STATUS_SUCCESS);
    }

    private function responseSplitter(uuid as GPM.GoProUuid, response as ByteArray) as Void {
        var length = response.size();

        uuid = GPM.getUuid(uuid);
        var characteristic = new BleAPI.MockCharacteristic(uuid, gpControlService) as Ble.Characteristic;

        if (length<20) {
            BleAPI.delegate.onCharacteristicChanged(characteristic, [length]b.addAll(response));
        }
        BleAPI.delegate.onCharacteristicChanged(characteristic, [0x20 | (0x1F & (length>>8)), 0xFF & length]b.addAll(response.slice(0, 18)));
        var counter = 0;
        response = response.slice(18, null);
        while (response.size()>0) {
            BleAPI.delegate.onCharacteristicChanged(characteristic, [0x80 | 0x0F & counter]b.addAll(response.slice(0,19)));
            response = response.slice(19, null);
            counter++;
        }
    }

    private function updateNotif(notifs as ByteArray, query as Number, value as Number) as Void {
        if (query>=80 and notifs.indexOf(value)==-1) {
            notifs.add(value); 
        } else if (query>=0x70) {
            notifs.remove(value);
        }
    }

    public function onReceiveSetting(id as Number, response as ByteArray, query as Number) as Void {
        var internalId = id;

        var idx = GoProDecoder.OLD_SETTINGS.indexOf(id);
        if (idx != -1) { id = GoProDecoder.NEW_SETTINGS[idx]; }

        updateNotif(notifSettings, query, internalId);
        if (query >= 0x70) { return; }

        var value = settings.get(internalId);
        if (value == null) {
            // System.println("[DBG WARN]  onReceiveSetting null value, id="+id);
            return;
        }

        if (specs.cameraId < GoProCamera.GP_MISSION1PRO) { response.addAll([0xFF, 0]); }
        response.addAll([id, 0x01, value]b);
    }

    public function onReceiveStatus(id as Number, response as ByteArray, query as Number) as Void {
        updateNotif(notifStatuses, query, id);
        if (query >= 0x70) { return; }

        if (specs.cameraId < GoProCamera.GP_MISSION1PRO) { response.addAll([0xFF, 0]); }

        if (id == GoProCamera.SD_REMAINING
            or id == GoProCamera.ENCODING_DURATION
            or id == GoProCamera.PHOTOS_TAKEN)
        {
            response.addAll([id, 0x04]b);
            var valueN = statuses.get(id);
            var valueB = [0,0,0,0]b;

            if (valueN == null) {
                // System.println("[DBG WARN]  onReceiveStatus null value, id="+id);
                return;
            }

            valueB.encodeNumber(valueN, Lang.NUMBER_FORMAT_UINT32, {:endianness => Lang.ENDIAN_BIG});
            response.addAll(valueB);
        } else {
            response.addAll([id, 0x01, statuses.get(id) as Number]b);
        }
    }
    
    public function onReceiveAvailable(id as Number, response as ByteArray, query as Number) as Void {
        var internalId = id;

        var idx = GoProDecoder.OLD_SETTINGS.indexOf(id);
        if (idx != -1) { internalId = GoProDecoder.NEW_SETTINGS[idx]; }

        updateNotif(notifAvailable, query, internalId);
        if (query >= 0x70) { return; }

        var available;
        switch (internalId) {
            case GoProSettings.RESOLUTION:
                available = specs.availableSettingsMap.keys();
                break;
            case GoProSettings.LENS:
                available = specs.availableSettingsMap.get(settings.get(GoProSettings.RESOLUTION) as Number); // could be null
                available = available !=null ? available.keys() : []b;
                break;
            case GoProSettings.FRAMERATE:
                available = specs.availableSettingsMap.get(settings.get(GoProSettings.RESOLUTION) as Number); // could be null
                available = available != null ? available.get(settings.get(GoProSettings.LENS) as Number) : []b; // could be null
                if (available == null) { available = []b; }
                break;
            case GoProSettings.LED:
                available = specs.availableLed;
                break;
            case GoProSettings.GPS:
                available = specs.availableGps;
                break;
            case GoProSettings.FLICKER:
                available = specs.availableFlicker;
                break;
            case GoProSettings.HYPERSMOOTH:
                available = specs.availableHypersmooth;
                break;
            case GoProSettings.PHOTO_LENS:
                available = specs.availablePhotoLens;
                break;
            default:
                available = []b;
                // System.println("[DBG WARN]  Wrong id");
                break;
        }
        for (var i=0; i<available.size(); i++) {
            response.addAll([id, 0x01, available[i]]b);
        }
    }

    function setSetting(id as GoProSettings.SettingId or Number, value as Number) as Void {
        var msg = specs.cameraId < GoProCamera.GP_MISSION1PRO ? [3]b : [5, 0xFF, 0]b;

        if (specs.cameraId < GoProCamera.GP_MAX) {
            var idx = GoProDecoder.NEW_SETTINGS.indexOf(id);
            if (idx != -1) { id = GoProDecoder.OLD_SETTINGS[idx]; }
        }

        msg.addAll([id, 1, value]);
        onSend([GPM.UUID_SETTINGS_CHAR, msg]);
    }

    function setStatus(id as Number, value as Number) as Void {
        statuses.put(id, value);

        var notif = [GoProDecoder.NOTIF_STATUS, 0, id]b;
        if (id == GoProCamera.SD_REMAINING or id == GoProCamera.ENCODING_DURATION) {
            var valueB = [0,0,0,0]b;
            valueB.encodeNumber(value, Lang.NUMBER_FORMAT_UINT32, {:endianness => Lang.ENDIAN_BIG});
            notif.add(4).addAll(valueB);
        } else {
            notif.addAll([1, value]b);
        }
        
        responseSplitter(GPM.UUID_QUERY_RESPONSE_CHAR, notif);
    }
}
