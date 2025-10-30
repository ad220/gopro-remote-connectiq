import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

class CameraDelegate extends Ble.BleDelegate {

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

    protected var isConnected as Boolean;

    private var scanStateChangeCallback as Method(state as Ble.ScanState) as Void?;
    private var scanResultCallback as Method(scanResults as [Ble.ScanResult]) as Void?;

    protected var requestQueue as GattRequestQueue?;

    private var queryReplyLength as Number?;
    private var queryReplyBuffer as ByteArray?;
    protected var pairingTimer as TimerCallback?;
    protected var pairingDevice as Ble.Device?;
    private var keepAliveTimer as TimerCallback?;

    public function initialize() {
        self.isConnected = false;
        BleDelegate.initialize();
    }

    public function setScanStateChangeCallback(callback as Method(state as Ble.ScanState) as Void?) as Void {
        scanStateChangeCallback = callback;
    }

    public function onScanStateChange(scanState as Ble.ScanState, status as Ble.Status) as Void {
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
            // filter results with GoPro 0xFEA6 UUID
            for (var device = scanResults.next() as Ble.ScanResult; device!=null; device = scanResults.next()) {
                var uuids = device.getServiceUuids();
                for (var uuid = uuids.next() as Ble.Uuid; uuid!=null; uuid = uuids.next()) {
                    if (uuid.toString().equals(GattProfileManager.GOPRO_CONTROL_SERVICE)) {
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

    public function pair(device as Ble.ScanResult?) as Void {
        pairingTimer = getApp().timerController.start(method(:onPairingFailed), 20, false);
        pairingDevice = Ble.pairDevice(device);
    }

    public function isPairing() as Boolean {
        return pairingDevice!=null;
    }

    public function onPairingFailed() as Void {
        if (!isConnected and pairingDevice!=null) {
            unpairDevice(pairingDevice);
        }
        Ble.setScanState(Ble.SCAN_STATE_OFF);
        getApp().viewController.push(new NotifView(ConnectDelegate.CONNECT_ERROR_NOTIF, NotifView.NOTIF_ERROR), new NotifDelegate(), WatchUi.SLIDE_DOWN);
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
                onDisconnect();
            }
        } else {
            isConnected = false;
            System.println("null device changed connected status");
        }
    }
    
    public function onEncryptionStatus(device as Ble.Device, status as Ble.Status) as Void {
        if (device!=null and status == Ble.STATUS_SUCCESS) {
            if (!isConnected) {
                isConnected = true;
                initiateConnection(device);
            }
        } else {
            isConnected = false;
            System.println("null device changed encryption status");
        }
    }

    private function initiateConnection(device as Ble.Device) as Void {
        Ble.setScanState(Ble.SCAN_STATE_OFF);
        pairingTimer.stop();
        pairingTimer = null;
        pairingDevice = null;
        
        var service = device.getService(Ble.stringToUuid(GattProfileManager.GOPRO_CONTROL_SERVICE));
        if (service != null) {
            requestQueue = new GattRequestQueue(service);
        }
        getApp().gopro = new GoProCamera(requestQueue, method(:onDisconnect));
        getApp().gopro.registerSettings();

        keepAliveTimer = getApp().timerController.start(method(:keepAlive), 8, true);
        var pushView = getApp().viewController.method(getApp().fromGlance ? :switchTo : :push);
        pushView.invoke(new RemoteView(), new RemoteDelegate(), WatchUi.SLIDE_LEFT);
    }

    public function keepAlive() as Void {
        if (isConnected) {
            var data = [0x03, 0x5b, 0x01, 0x42]b;
            requestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.getUuid(GattProfileManager.UUID_SETTINGS_CHAR), data);
        }
    }

    public function onDisconnect() as Void {
        // put camera to sleep and close connection
        if (isConnected) {
            isConnected = false;
            getApp().timerController.stop(keepAliveTimer);
            requestQueue.close();
            getApp().viewController.returnHome(null, null);
        }
    }

    public function onCharacteristicChanged(characteristic as Ble.Characteristic, value as ByteArray) as Void {
        if (characteristic.getUuid().equals(GattProfileManager.getUuid(GattProfileManager.UUID_QUERY_RESPONSE_CHAR))) {
            decodeQuery(value);
        }
    }

    public function onCharacteristicRead(characteristic as Ble.Characteristic, status as Ble.Status, value as ByteArray) as Void {
        if (status != Ble.STATUS_SUCCESS) {
            System.println("Error while reading characteristic");
            return;
        }
        if (characteristic.getUuid().equals(GattProfileManager.getUuid(GattProfileManager.UUID_QUERY_RESPONSE_CHAR))) {
            decodeQuery(value);
        }
    }

    protected function decodeQuery(response as ByteArray) as Void {
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
        var gopro = getApp().gopro;
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
            case GET_STATUS:
            case REGISTER_STATUS:
            case NOTIF_STATUS:
                decoder = gopro.method(:onReceiveStatus);
                break;
            case REGISTER_AVAILABLE:
            case NOTIF_AVAILABLE:
                decoder = gopro.method(:onReceiveAvailable);
                break;
            default:
                System.println("Unknown queryId: " + queryId.toNumber());
                return;
        }

        var type;
        var length;
        var value;

        for (var i=0; i<data.size(); i+=2+length) {
            type = data[i] as Char;
            length = data[i+1];
            value = data.slice(i+2, i+2+length);
            (decoder as Method(id as Char, value as ByteArray) as Void).invoke(type, value);
        }
        if (queryId == REGISTER_AVAILABLE or queryId == NOTIF_AVAILABLE) {
            gopro.applyAvailableSettings();
        }
        WatchUi.requestUpdate();
    }

    public function onCharacteristicWrite(characteristic as Ble.Characteristic, status as Ble.Status) as Void {
        requestQueue.onRequestProcessed(GattRequest.WRITE_CHARACTERISTIC, characteristic.getUuid(), status);
    }

    public function onDescriptorWrite(descriptor as Ble.Descriptor, status as Ble.Status) as Void {
        requestQueue.onRequestProcessed(GattRequest.REGISTER_NOTIFICATION, descriptor.getUuid(), status);        
    }
}