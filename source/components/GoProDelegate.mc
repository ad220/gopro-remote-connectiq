import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

class GoProDelegate extends Ble.BleDelegate {

    public enum QueryId {
        GET_SETTING             = 0x12,
        GET_STATUS              = 0x13,
        GET_AVAILABLE           = 0x32,
        REGISTER_SETTING        = 0x52,
        REGISTER_STATUS         = 0x53,
        REGISTER_AVAILABLE      = 0x62,
        UNREGISTER_SETTING      = 0x72,
        UNREGISTER_STATUS       = 0x73,
        UNREGISTER_AVAILABLE    = 0x82,
        NOTIF_SETTING           = 0x92,
        NOTIF_STATUS            = 0x93,
        NOTIF_AVAILABLE         = 0xA2,
    }

    private var timerController as TimerController;
    private var viewController as ViewController;
    private var isConnected as Boolean;

    private var scanStateChangeCallback as Method(state as Ble.ScanState) as Void?;
    private var scanResultCallback as Method(scanResults as [Ble.ScanResult]) as Void?;

    private var gopro as GoProCamera?;
    private var requestQueue as GattRequestQueue?;

    private var queryReplyLength as Number?;
    private var queryReplyBuffer as ByteArray?;
    private var keepAliveTimer as TimerCallback?;

    public function initialize(timerController as TimerController, viewController as ViewController) {
        self.timerController = timerController;
        self.viewController = viewController;
        self.isConnected = false;
        BleDelegate.initialize();
    }

    public function onProfileRegister(uuid as Ble.Uuid, status as Ble.Status) as Void {
        
    }

    public function setScanStateChangeCallback(callback as Method(state as Ble.ScanState) as Void?) as Void {
        scanStateChangeCallback = callback;
    }

    public function onScanStateChange(scanState as Ble.ScanState, status as Ble.Status) as Void {
        System.println("BLE scan state changed : " + scanState + " / " + status);
        if (status == Ble.STATUS_SUCCESS and scanStateChangeCallback!=null) {
            scanStateChangeCallback.invoke(scanState);
        }
    }

    public function setScanResultCallback(callback as Method(scanResults as [Ble.ScanResult]) as Void?) as Void{
        scanResultCallback = callback;
    }

    public function onScanResults(scanResults as Ble.Iterator) as Void {
        if (scanResultCallback!=null) {
            var scanResultsArray = [];
            System.println("onScanResults");
            // filter results with GoPro 0xFEA6 UUID
            for (var device = scanResults.next() as Ble.ScanResult; device!=null; device = scanResults.next()) {
                var uuids = device.getServiceUuids();
                System.println(device.getDeviceName());
                for (var uuid = uuids.next() as Ble.Uuid; uuid!=null; uuid = uuids.next()) {
                    System.println(uuid.toString());
                    if (uuid.equals(GattProfileManager.GOPRO_CONTROL_SERVICE)) {
                        scanResultsArray.add(device);
                        break;
                    }
                }
            }
            scanResultCallback.invoke(scanResultsArray);
        } else {
            System.println("scanResultCallback is null");
        }
    }

    public function onConnectedStateChanged(device as Ble.Device, state as Ble.ConnectionState) as Void {
        if (device!=null) {
            if (state == Ble.CONNECTION_STATE_CONNECTED) {
                if (device.isBonded()) {
                    isConnected = true;
                    initiateConnection(device);
                } else {
                    isConnected = false;
                    device.requestBond();
                }                
            } else {
                isConnected = false;
                keepAliveTimer.stop();
            }
        } else {
            isConnected = false;
            System.println("null device changed connected status");
        }
    }
    
    public function onEncryptionStatus(device as Ble.Device, status as Ble.Status) as Void {
        if (device!=null and status == Ble.STATUS_SUCCESS) {
            isConnected = true;
            initiateConnection(device);
        } else {
            isConnected = false;
            System.println("null device changed encryption status");
        }
    }

    private function initiateConnection(device as Ble.Device) as Void {
        var service = device.getService(GattProfileManager.GOPRO_CONTROL_SERVICE);
        requestQueue = new GattRequestQueue(service, timerController);
        gopro = new GoProCamera(timerController, requestQueue, method(:onDisconnect));

        requestQueue.add(GattRequest.REGISTER_NOTIFICATION, GattProfileManager.COMMAND_RESPONSE_CHARACTERISTIC, [1] as ByteArray);
        requestQueue.add(GattRequest.REGISTER_NOTIFICATION, GattProfileManager.SETTINGS_RESPONSE_CHARACTERISTIC, [1] as ByteArray);
        requestQueue.add(GattRequest.REGISTER_NOTIFICATION, GattProfileManager.QUERY_RESPONSE_CHARACTERISTIC, [1] as ByteArray);
        requestQueue.add(
            GattRequest.WRITE_CHARACTERISTIC,
            GattProfileManager.QUERY_CHARACTERISTIC,
            [5, REGISTER_SETTING, GoProSettings.RESOLUTION, GoProSettings.FRAMERATE, GoProSettings.LENS, GoProSettings.FLICKER] as ByteArray
        );
        requestQueue.add(
            GattRequest.WRITE_CHARACTERISTIC,
            GattProfileManager.QUERY_CHARACTERISTIC,
            [2, REGISTER_STATUS, GoProCamera.ENCODING] as ByteArray
        );
        requestQueue.add(
            GattRequest.WRITE_CHARACTERISTIC,
            GattProfileManager.QUERY_CHARACTERISTIC,
            [4, REGISTER_AVAILABLE, GoProSettings.RESOLUTION, GoProSettings.FRAMERATE, GoProSettings.LENS] as ByteArray
        );

        keepAliveTimer = timerController.start(method(:keepAlive), 10, true);
        viewController.push(new RemoteView(gopro), new RemoteDelegate(viewController, gopro), WatchUi.SLIDE_LEFT);
    }

    public function keepAlive() as Void {
        if (isConnected) {
            var data = [0x03, 0x5b, 0x01, 0x42];
            requestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.SETTINGS_CHARACTERISTIC, data as ByteArray);
        }
    }

    public function onDisconnect() as Void {

    }


    public function onCharacteristicChanged(characteristic as Ble.Characteristic, value as ByteArray) as Void {
        System.println("Characteristic changed, uuid: " + characteristic.getUuid().toString());
        if (characteristic.getUuid().equals(GattProfileManager.QUERY_RESPONSE_CHARACTERISTIC)) {
            decodeQuery(value);
        }
    }

    public function onCharacteristicRead(characteristic as Ble.Characteristic, status as Ble.Status, value as ByteArray) as Void {
        System.println("Characteristic read, uuid: " + characteristic.getUuid().toString());
        if (status != Ble.STATUS_SUCCESS) {
            System.println("Error while reading characteristic");
            return;
        }
        if (characteristic.getUuid().equals(GattProfileManager.QUERY_RESPONSE_CHARACTERISTIC)) {
            decodeQuery(value);
        }
    }

    private function decodeQuery(response as ByteArray) as Void {
        if (response[0] & 0xe0 == 0x00) { // 5-bit length packets
            readTLVMessage(response.slice(1, null));
        } else if (response[0] & 0xe0 == 0x20) { // 13-bit length packet
            queryReplyLength = ((response[0] & 0x1f) << 8) + response[1];
            queryReplyBuffer = response.slice(2, null);
        } else if (response[0] & 0xe0 == 0x40) { // 16-bit length packet
            queryReplyLength = (response[1] << 8) + response[2];
            queryReplyBuffer = response.slice(3, null);
        } else if ((response[0] & 0x80) == 0x80) { // Continuation packet
            queryReplyBuffer.addAll(response.slice(1, null));
            if (queryReplyBuffer.size() == queryReplyLength) {
                readTLVMessage(queryReplyBuffer);
            }
        }
    }

    private function readTLVMessage(message as ByteArray) as Void {
        if (message.size()<2) {
            System.println("TLV Message too short");
            return;
        }
        var queryId = message[0];
        var status = message[1];
        var data = message.slice(2, null);
        var decoder = null;

        if (status != 0) {
            System.println("Wrong query status received from camera, value: " + status.toNumber());
        }

        switch (queryId) {
            case REGISTER_SETTING:
            case NOTIF_SETTING:
                decoder = gopro.method(:onReceiveSetting);
                break;
            case REGISTER_STATUS:
            case NOTIF_STATUS:
                decoder = gopro.method(:onReceiveStatus);
            case REGISTER_AVAILABLE:
            case NOTIF_AVAILABLE:
                decoder = gopro.method(:onReceiveAvailable);
            default:
                System.println("Unknown queryId: " + queryId.toNumber());
                return;
        }

        var type;
        var length;
        var value;

        for (var i=0; i<data.size(); i+=2+length) {
            type = data[i];
            length = data[i+1];
            value = data.slice(i+2, i+2+length);
            (decoder as Method(id as Number, value as ByteArray) as Void).invoke(type, value);
        }
        WatchUi.requestUpdate();
    }

    public function onCharacteristicWrite(characteristic as Ble.Characteristic, status as Ble.Status) as Void {
        requestQueue.onRequestProcessed(characteristic.getUuid(), status);
    }

    public function onDescriptorWrite(descriptor as Ble.Descriptor, status as Ble.Status) as Void {
        requestQueue.onRequestProcessed(descriptor.getUuid(), status);        
    }
}