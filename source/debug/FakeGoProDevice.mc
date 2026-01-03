import Toybox.Lang;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;

(:debug) class FakeGoProDevice {

    typedef FakeGoProSettings as Dictionary<Char or GoProSettings.SettingId, Char or Number>;
    typedef FakeGoProStatuses as Dictionary<Char or GoProCamera.StatusId, Number>;

    private var settings as FakeGoProSettings;
    private var statuses as FakeGoProStatuses;
    private var specs as FakeGoProSpecs.ISpecs;

    private var notifSettings as Array<Char>;
    private var notifStatuses as Array<Char>;
    private var notifAvailable as Array<Char>;

    private var gpControlService as BleAPI.MockService;
    private var gpQueryResponseChar as BleAPI.MockCharacteristic;

    public function initialize(
            settings as FakeGoProSettings,
            statuses as FakeGoProStatuses,
            specs as FakeGoProSpecs.ISpecs
        ) {
        self.settings = settings;
        self.statuses = statuses;
        self.specs = specs;

        self.notifSettings = [];
        self.notifStatuses = [];
        self.notifAvailable = [];

        var device = new BleAPI.MockDevice();
        gpControlService = new BleAPI.MockService(Ble.stringToUuid(GPM.GOPRO_CONTROL_SERVICE), device);
        gpQueryResponseChar = new BleAPI.MockCharacteristic(
            GPM.getUuid(GPM.UUID_QUERY_RESPONSE_CHAR),
            gpControlService
        );
    }

    public function onSend(uuid as GPM.GoProUuid, data as ByteArray) as Void {
        var response;
        
        switch (uuid) {
            case GPM.UUID_QUERY_CHAR:
                System.println("query :"+data);
                var queryId = data[1];
                var decoder = null;
                data = data.slice(2, null);

                switch (queryId) {
                    case CameraDelegate.GET_SETTING:
                    case CameraDelegate.REGISTER_SETTING:
                    case CameraDelegate.UNREGISTER_SETTING:
                        decoder = method(:onReceiveSetting);
                        break;
                    case CameraDelegate.GET_STATUS:
                    case CameraDelegate.REGISTER_STATUS:
                    case CameraDelegate.UNREGISTER_STATUS:
                        decoder = method(:onReceiveStatus);
                        break;
                    case CameraDelegate.GET_AVAILABLE:
                    case CameraDelegate.REGISTER_AVAILABLE:
                    case CameraDelegate.UNREGISTER_AVAILABLE:
                        decoder = method(:onReceiveAvailable);
                        break;
                    default:
                        System.println("Unknown queryId: " + queryId.toNumber());
                }
                if (decoder instanceof Method) {
                    response = [queryId, 0x00]b;
                    for (var i=0; i<data.size(); i++) {
                        decoder.invoke(data[i] as Char, response, queryId);
                    }
                    responseSplitter(GPM.UUID_QUERY_RESPONSE_CHAR, response);
                }
                break;

            case GPM.UUID_COMMAND_CHAR:
                var commandId = data[1];
                switch (commandId) {
                    case GoProCamera.SHUTTER:
                        statuses.put(GoProCamera.ENCODING, data[3]);
                        responseSplitter(GPM.UUID_COMMAND_RESPONSE_CHAR, [1, 0]b);
                        if (notifStatuses.indexOf(GoProCamera.ENCODING as Char) != -1) {
                            BleAPI.callbacks.onCharacteristicChanged(
                                gpQueryResponseChar as Ble.Characteristic,
                                [0x03, CameraDelegate.NOTIF_STATUS, 0x00, GoProCamera.ENCODING, 0x01, data[3]]b
                            );
                        }
                        break;
                    default:
                        break;
                }
                break;

            case GPM.UUID_SETTINGS_CHAR:
                var minSettingChanged = 0xFF;
                response = [CameraDelegate.NOTIF_SETTING, 0x00]b;
                for (var i=1; i<data.size(); i+=2+data[i+1]) {
                    settings.put(data[i] as Char, data[i+2]);
                    if (notifSettings.indexOf(data[i] as Char)!=-1) {
                        response.addAll([data[i], 0x01, data[i+2]]);
                    }
                    minSettingChanged = data[i]==GoProSettings.RESOLUTION ? data[i] : \
                                        data[i]==GoProSettings.LENS and minSettingChanged!=GoProSettings.RESOLUTION ? data[i] : \
                                        data[i]==GoProSettings.FRAMERATE and minSettingChanged==0xFF ? data[i] : minSettingChanged;
                }
                responseSplitter(GPM.UUID_SETTINGS_RESPONSE_CHAR, [1, 0]b);
                if (response.size()>2) {
                    responseSplitter(GPM.UUID_QUERY_RESPONSE_CHAR, response);
                }

                response = [CameraDelegate.NOTIF_AVAILABLE, 0x00]b;
                var iter;
                var j;
                var res = settings.get(GoProSettings.RESOLUTION) as Char;
                var lens = settings.get(GoProSettings.LENS) as Char;
                switch (minSettingChanged) {
                    case GoProSettings.RESOLUTION:
                        iter = (specs.availableSettingsMap.get(res) as Dictionary).keys();
                        if (iter.indexOf(lens) == -1) {
                            settings.put(GoProSettings.LENS as Char, iter[0] as Char);
                        }
                        if (notifAvailable.indexOf(GoProSettings.LENS as Char) != -1) {
                            for (j=0; j<iter.size(); j++) {
                                response.addAll([GoProSettings.LENS, 0x01, iter[j]]);
                            }
                        }
                    case GoProSettings.LENS:
                        if (notifAvailable.indexOf(GoProSettings.FRAMERATE as Char) != -1) {
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
                System.println("Unknown UUID" + uuid);
                break;
        }
        // garminDevice.whenCharacteristicWrite(uuid, Ble.STATUS_SUCCESS);
    }

    private function responseSplitter(uuid as GPM.GoProUuid, response as ByteArray) as Void {
        var length = response.size();

        uuid = GPM.getUuid(uuid);
        var characteristic = new BleAPI.MockCharacteristic(uuid, gpControlService) as Ble.Characteristic;

        if (length<20) {
            BleAPI.callbacks.onCharacteristicChanged(characteristic, [length]b.addAll(response));
        }
        BleAPI.callbacks.onCharacteristicChanged(characteristic, [0x20 | (0x1F & (length>>8)), 0xFF & length]b.addAll(response.slice(0, 18)));
        var counter = 0;
        response = response.slice(18, null);
        while (response.size()>0) {
            BleAPI.callbacks.onCharacteristicChanged(characteristic, [0x80 | 0x0F & counter]b.addAll(response.slice(0,19)));
            response = response.slice(19, null);
            counter++;
        }
    }

    private function updateNotif(notifs as Array<Char>, query as Char, value as Char) as Void {
        if (query>=80 and notifs.indexOf(value)==-1) {
            notifs.add(value); 
        } else if (query>=0x70) {
            notifs.remove(value);
        }
    }

    public function onReceiveSetting(id as Char, response as ByteArray, query as Char) as Void {
        updateNotif(notifSettings, query, id);
        if (query >= 0x70) { return; }

        var value = settings.get(id);
        if (value == null) {
            System.println("onReceiveSetting null value, id="+id);
            return;
        } 
        response.addAll([id, 0x01, value]b);
    }

    public function onReceiveStatus(id as Char, response as ByteArray, query as Char) as Void {
        updateNotif(notifStatuses, query, id);
        if (query >= 0x70) { return; }

        if (id==GoProCamera.SD_REMAINING or id==GoProCamera.ENCODING_DURATION) {
            response.addAll([id, 0x04]b);
            var valueN = statuses.get(id);
            var valueB = [0,0,0,0]b;

            if (valueN == null) {
                System.println("onReceiveStatus null value, id="+id);
                return;
            }

            valueB.encodeNumber(valueN, Lang.NUMBER_FORMAT_UINT32, {:endianness => Lang.ENDIAN_BIG});
            response.addAll(valueB);
        } else {
            response.addAll([id, 0x01, statuses.get(id) as Char]b);
        }
    }
    
    public function onReceiveAvailable(id as Char, response as ByteArray, query as Char) as Void {
        updateNotif(notifAvailable, query, id);
        if (query >= 0x70) { return; }

        var available;
        switch (id) {
            case GoProSettings.RESOLUTION:
                available = specs.availableSettingsMap.keys();
                break;
            case GoProSettings.LENS:
                available = (specs.availableSettingsMap.get(settings.get(GoProSettings.RESOLUTION) as Char) as Dictionary).keys();
                break;
            case GoProSettings.FRAMERATE:
                available = (
                    specs.availableSettingsMap.get(
                        settings.get(GoProSettings.RESOLUTION) as Char
                    ) as Dictionary
                ).get(settings.get(GoProSettings.LENS) as Char) as Array;
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
            default:
                available = [];
                System.println("Wrong id");
                break;
        }
        for (var i=0; i<available.size(); i++) {
            response.addAll([id, 0x01, (available as Array)[i]]b);
        }
    }
}
