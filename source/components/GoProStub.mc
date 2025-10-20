import Toybox.Lang;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;

(:debug) class FakeGoProDevice {

    private static const AVAILABLE_MAP_H11 = {
        26  => {
            GoProSettings.WIDE        => [8,9],
        },
        27  => {
            GoProSettings.WIDE        => [8,9,10],
            GoProSettings.LINEAR      => [8,9,10],
            GoProSettings.LINEARLOCK  => [8,9,10],
        },
        100 => {
            GoProSettings.HYPERVIEW   => [8,9,10],
            GoProSettings.SUPERVIEW   => [5,6,8,9,10],
            GoProSettings.WIDE        => [5,6,8,9,10],
            GoProSettings.LINEAR      => [5,6,8,9,10],
            GoProSettings.LINEARLOCK  => [8,9,10],
            GoProSettings.LINEARLEVEL => [5,6],
        },
        28  => {
            GoProSettings.WIDE        => [5,6,8,9],
        },
        18  => {
            GoProSettings.WIDE        => [5,6,8,9,10],
            GoProSettings.LINEAR      => [5,6,8,9,10],
            GoProSettings.LINEARLOCK  => [5,6,8,9,10],
        },
        1   => {
            GoProSettings.HYPERVIEW   => [5,6],
            GoProSettings.SUPERVIEW   => [1,2,5,6,8,9,10],
            GoProSettings.WIDE        => [1,2,5,6,8,9,10],
            GoProSettings.LINEAR      => [1,2,5,6,8,9,10],
            GoProSettings.LINEARLOCK  => [5,6,8,9,10],
            GoProSettings.LINEARLEVEL => [1,2],
        },
        6   => {
            GoProSettings.WIDE        => [1,2,5,6],
            GoProSettings.LINEAR      => [1,2,5,6],
            GoProSettings.LINEARLOCK  => [1,2,5,6],
        },
        4   => {
            GoProSettings.SUPERVIEW   => [1,2,5,6],
            GoProSettings.WIDE        => [0,1,2,5,6,13],
            GoProSettings.LINEAR      => [0,1,2,5,6,13],
            GoProSettings.LINEARLOCK  => [1,2,5,6],
            GoProSettings.LINEARLEVEL => [0,13],
        },
        9   => {
            GoProSettings.SUPERVIEW   => [1,2,5,6,8,9,10],
            GoProSettings.WIDE        => [0,1,2,5,6,8,9,10,13],
            GoProSettings.LINEAR      => [0,1,2,5,6,8,9,10,13],
            GoProSettings.LINEARLOCK  => [1,2,5,6,8,9,10],
            GoProSettings.LINEARLEVEL => [0,13],
        }
    };

    private static const AVAILABLE_FLICKER_H11 = [
        GoProSettings.HZ50,
        GoProSettings.HZ60
    ];

    private static const AVAILABLE_LED_H11 = [
        GoProSettings.LED_ON,
        GoProSettings.LED_OFF,
        // GoProSettings.LED_ALL_ON,
        // GoProSettings.LED_ALL_OFF,
        // GoProSettings.LED_BACK_ONLY,
    ];

    private static const AVAILABLE_HYPERSMOOTH_H11 = [
        GoProSettings.HS_OFF,
        GoProSettings.HS_LOW,
        GoProSettings.HS_BOOST,
        GoProSettings.HS_AUTO_BOOST,
    ];

    private static const AVAILABLE_GPS_H11 = [];

    // private static const AVAILABLE_RATIOS_H11 = {
    //     26  => [26,27,100],
    //     27  => [26,27,100],
    //     100 => [26,27,100],
    //     28  => [28,18,1],
    //     18  => [28,18,1],
    //     1   => [28,18,1],
    //     6   => [6,4],
    //     4   => [6,4],
    //     9   => [9],
    // };

    private var garminDevice as GoProDelegateStub;

    private var settings as Dictionary;
    private var statuses as Dictionary;

    public function initialize(garminDevice as GoProDelegateStub) {
        self.garminDevice = garminDevice;
        self.settings = {
            GoProSettings.RESOLUTION    => 28,
            GoProSettings.LENS          => GoProSettings.WIDE,
            GoProSettings.FRAMERATE     => 6,
            GoProSettings.FLICKER       => GoProSettings.HZ50,
            GoProSettings.LED           => GoProSettings.LED_ON,
            GoProSettings.HYPERSMOOTH   => GoProSettings.HS_LOW,
            GoProSettings.GPS           => 0,
        };
        self.statuses = {
            GoProCamera.ENCODING            => 0,
            GoProCamera.ENCODING_DURATION   => 0,
            GoProCamera.BATTERY             => 50,
            GoProCamera.SD_REMAINING        => 4269
        };

    }

    public function send(uuid as Ble.Uuid, data as ByteArray) {
        var response;
        switch (uuid) {
            case GattProfileManager.QUERY_CHARACTERISTIC:
                System.println("query :"+data);
                var queryId = data[1];
                var decoder = null;
                data = data.slice(2, null);

                switch (queryId) {
                    case GoProDelegate.GET_SETTING:
                    case GoProDelegate.REGISTER_SETTING:
                        decoder = method(:onReceiveSetting);
                        break;
                    case GoProDelegate.GET_STATUS:
                    case GoProDelegate.REGISTER_STATUS:
                        decoder = method(:onReceiveStatus);
                        break;
                    case GoProDelegate.GET_AVAILABLE:
                    case GoProDelegate.REGISTER_AVAILABLE:
                        decoder = method(:onReceiveAvailable);
                        break;
                    default:
                        System.println("Unknown queryId: " + queryId.toNumber());
                        return;
                }

                response = [queryId, 0x00]b;
                for (var i=0; i<data.size(); i++) {
                    (decoder as Method(id as Char, response as ByteArray) as Void).invoke(data[i] as Char, response);
                }
                responseSplitter(GattProfileManager.QUERY_RESPONSE_CHARACTERISTIC, response);
                break;

            case GattProfileManager.COMMAND_CHARACTERISTIC:
                var commandId = data[1];
                switch (commandId) {
                    case GoProCamera.SHUTTER:
                        statuses.put(GoProCamera.ENCODING, data[3]);
                        garminDevice.whenCharacteristicChanged(GattProfileManager.QUERY_RESPONSE_CHARACTERISTIC, [0x03, GoProDelegate.NOTIF_STATUS, 0x00, GoProCamera.ENCODING, 0x01, data[3]]b);
                        break;
                    default:
                        break;
                }
                break;

            case GattProfileManager.SETTINGS_CHARACTERISTIC:
                var minSettingChanged = 0xFF;
                response = [GoProDelegate.NOTIF_SETTING, 0x00]b;
                for (var i=1; i<data.size(); i+=2+data[i+1]) {
                    settings.put(data[i], data[i+2]);
                    response.addAll([data[i], 0x01, data[i+2]]);
                    minSettingChanged = data[i]==GoProSettings.RESOLUTION ? data[i] : \
                                        data[i]==GoProSettings.LENS and minSettingChanged!=GoProSettings.RESOLUTION ? data[i] : \
                                        data[i]==GoProSettings.FRAMERATE and minSettingChanged==0xFF ? data[i] : minSettingChanged;
                }
                responseSplitter(GattProfileManager.QUERY_RESPONSE_CHARACTERISTIC, response);

                response = [GoProDelegate.NOTIF_AVAILABLE, 0x00]b;
                var iter;
                var j;
                switch (minSettingChanged) {
                    case GoProSettings.RESOLUTION:
                        iter = (AVAILABLE_MAP_H11.get(settings.get(GoProSettings.RESOLUTION)) as Dictionary).keys();
                        for (j=0; j<iter.size(); j++) {
                            response.addAll([GoProSettings.LENS, 0x01, iter[j]]);
                        }
                    case GoProSettings.LENS:
                        iter = (AVAILABLE_MAP_H11.get(settings.get(GoProSettings.RESOLUTION)) as Dictionary)
                                                  .get(settings.get(GoProSettings.LENS)) as Array;
                        for (j=0; j<iter.size(); j++) {
                            response.addAll([GoProSettings.FRAMERATE, 0x01, iter[j]]);
                        }
                        break;
                    default:
                        break;
                }
                responseSplitter(GattProfileManager.QUERY_RESPONSE_CHARACTERISTIC, response);
                break;

            default:
                break;
        }
        garminDevice.whenCharacteristicWrite(uuid, Ble.STATUS_SUCCESS);
    }

    private function responseSplitter(uuid as Ble.Uuid, response as ByteArray) as Void {
        var length = response.size();
        if (length<20) {
            garminDevice.whenCharacteristicChanged(uuid, [length]b.addAll(response));
        }
        garminDevice.whenCharacteristicChanged(uuid, [0x20 | (0x1F & (length>>8)), 0xFF & length]b.addAll(response.slice(0, 18)));
        var counter = 0;
        response = response.slice(18, null);
        while (response.size()>0) {
            garminDevice.whenCharacteristicChanged(uuid, [0x80 | 0x0F & counter]b.addAll(response.slice(0,19)));
            response = response.slice(19, null);
            counter++;
        }
    }

    public function onReceiveSetting(id as Char, response as ByteArray) as Void {
        response.addAll([id, 0x01, settings.get(id) as Char]b);
    }

    public function onReceiveStatus(id as Char, response as ByteArray) as Void {
        if (id==GoProCamera.SD_REMAINING or id==GoProCamera.ENCODING_DURATION) {
            response.addAll([id, 0x04]b);
            var value = [0,0,0,0]b;
            value.encodeNumber(statuses.get(id) as Number, Lang.NUMBER_FORMAT_UINT32, {:endianness => Lang.ENDIAN_BIG});
            response.addAll(value);
        } else {
            response.addAll([id, 0x01, statuses.get(id) as Char]b);
        }
    }
    
    public function onReceiveAvailable(id as Char, response as ByteArray) as Void {
        var available;
        switch (id) {
            case GoProSettings.RESOLUTION:
                available = AVAILABLE_MAP_H11.keys();
                break;
            case GoProSettings.LENS:
                available = (AVAILABLE_MAP_H11.get(settings.get(GoProSettings.RESOLUTION)) as Dictionary).keys();
                break;
            case GoProSettings.FRAMERATE:
                available = (AVAILABLE_MAP_H11.get(settings.get(GoProSettings.RESOLUTION)) as Dictionary).get(settings.get(GoProSettings.LENS));
                break;
            case GoProSettings.LED:
                available = AVAILABLE_LED_H11;
                break;
            case GoProSettings.GPS:
                available = AVAILABLE_GPS_H11;
                break;
            case GoProSettings.FLICKER:
                available = AVAILABLE_FLICKER_H11;
                break;
            case GoProSettings.HYPERSMOOTH:
                available = AVAILABLE_HYPERSMOOTH_H11;
                break;
            default:
                available = [];
                System.println("Wrong id");
                break;
        }
        for (var i=0; i<available.size(); i++) {
            response.addAll([id, 0x01, available[i] as Char]b);
        }
    }
}


(:debug) class GattRequestQueueStub extends GattRequestQueue {

    private var fakeDevice as FakeGoProDevice?;
   
    public function initialize(fakeDevice as FakeGoProDevice) {
        self.fakeDevice = fakeDevice;
        self.queue = [];
        self.isProcessing = false;
    }

    public function sendRequest() as Void {
        isProcessing = true;
        var request = queue[0];
        if (!(request.getData() instanceof ByteArray)) {
            System.println("Request data is not a ByteArray: "+request.getData());
            onRequestProcessed(request.getType(), request.getUuid(), Ble.STATUS_SUCCESS);
        }
        System.println("Sending request");
        try {
            if (request.getType() == GattRequest.WRITE_CHARACTERISTIC) { // ignore register notif, fakeDevice sends notif anyway
                fakeDevice.send(request.getUuid(), request.getData());
            }
        } catch (ex) {
            System.println(ex.getErrorMessage());
        }
        request.startTimer();
    }
    
    public function close() as Void {
        while (queue.size()>0) {
            queue[0].onResponse();
            queue = queue.slice(1, queue.size());
        }
        isProcessing = false;
    }
}

(:debug) class GoProDelegateStub extends GoProDelegate {

    public function initialize() {
        GoProDelegate.initialize();
    }
    
    public function pair(device as Ble.ScanResult?) as Void {
        System.println("Initiating fake connection");
        Ble.setScanState(Ble.SCAN_STATE_OFF);
        requestQueue = new GattRequestQueueStub(new FakeGoProDevice(self));
        getApp().gopro = new GoProCamera(requestQueue, method(:onDisconnect));
        requestQueue.add(
            GattRequest.WRITE_CHARACTERISTIC,
            GattProfileManager.QUERY_CHARACTERISTIC,
            [0x08, REGISTER_SETTING, GoProSettings.RESOLUTION, GoProSettings.FRAMERATE, GoProSettings.GPS, GoProSettings.LED, GoProSettings.LENS, GoProSettings.FLICKER, GoProSettings.HYPERSMOOTH]b
        );
        requestQueue.add(
            GattRequest.WRITE_CHARACTERISTIC,
            GattProfileManager.QUERY_CHARACTERISTIC,
            [0x02, REGISTER_STATUS, GoProCamera.ENCODING]b
        );
        requestQueue.add(
            GattRequest.WRITE_CHARACTERISTIC,
            GattProfileManager.QUERY_CHARACTERISTIC,
            [0x08, REGISTER_AVAILABLE, GoProSettings.RESOLUTION, GoProSettings.FRAMERATE, GoProSettings.GPS, GoProSettings.LED, GoProSettings.LENS, GoProSettings.FLICKER, GoProSettings.HYPERSMOOTH]b
        );
        getApp().viewController.push(new RemoteView(), new RemoteDelegate(), WatchUi.SLIDE_LEFT);
    }

    
    public function whenCharacteristicChanged(uuid as Ble.Uuid, value as ByteArray) as Void {
        System.println("Characteristic changed, uuid: " + uuid.toString());
        if (uuid.equals(GattProfileManager.QUERY_RESPONSE_CHARACTERISTIC)) {
            decodeQuery(value);
        }
    }

    public function whenCharacteristicRead(uuid as Ble.Uuid, status as Ble.Status, value as ByteArray) as Void {
        System.println("Characteristic read, uuid: " + uuid.toString());
        if (status != Ble.STATUS_SUCCESS) {
            System.println("Error while reading characteristic");
            return;
        }
        if (uuid.equals(GattProfileManager.QUERY_RESPONSE_CHARACTERISTIC)) {
            decodeQuery(value);
        }
    }

    public function whenCharacteristicWrite(uuid as Ble.Uuid, status as Ble.Status) as Void {
        requestQueue.onRequestProcessed(GattRequest.WRITE_CHARACTERISTIC, uuid, status);
    }

    public function onDisconnect() as Void {
        // put camera to sleep and close connection
        if (isConnected) {
            getApp().viewController.returnHome(null, null);
        }
    }
}