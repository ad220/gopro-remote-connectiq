import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;

(:ble)
class BluetoothDelegate extends CameraDelegate {

    private var apiCallbacks as BleApiCallbacks;

    private var scanMenuDelegate as ScanMenuDelegate?;

    protected var requestQueue as GattRequestQueue?;

    protected var camera as Ble.Device?;
    private var keepAliveTimer as TimerCallback?;

    public function initialize() {
        CameraDelegate.initialize();

        self.apiCallbacks = BleAPI.getCallbackInstance(self);
        BleAPI.setDelegate(apiCallbacks);
    }

    public function setScanMenuDelegate(menu as ScanMenuDelegate?) as Void {
        scanMenuDelegate = menu;
    }

    public function onScanStateChange(scanState as Ble.ScanState, status as Ble.Status) as Void {
        if (status == Ble.STATUS_SUCCESS and scanMenuDelegate!=null) {
            scanMenuDelegate.setScanState(scanState);
        }
    }

    public function onScanResults(scanResults as Ble.Iterator) as Void {
        if (scanMenuDelegate!=null) {
            var scanResultsArray = [];
            // filter results with GoPro 0xFEA6 UUID
            for (var device = scanResults.next() as Ble.ScanResult; device!=null; device = scanResults.next()) {
                var uuids = device.getServiceUuids();
                System.println(device.getRawData());
                for (var uuid = uuids.next() as Ble.Uuid; uuid!=null; uuid = uuids.next()) {
                    System.println(uuid.toString());
                    if (uuid.toString().equals(GattProfileManager.GOPRO_CONTROL_SERVICE)) {
                        scanResultsArray.add(device);
                        break;
                    }
                }
            }
            scanMenuDelegate.onScanResults(scanResultsArray);
        } else {
            System.println("Scan menu is null");
        }
    }

    public function connect(device as Ble.ScanResult?) as Void {
        if (device == null) { throw new Exception(); }
        CameraDelegate.connect(device);

        try {
            camera = BleAPI.pairDevice(device);
        } catch (ex) {
            var view = new NotifView(Rez.Strings.PairingFail, NotifView.NOTIF_ERROR);
            getApp().viewController.push(view, new NotifDelegate(), WatchUi.SLIDE_UP);
        }
    }

    public function onPairingFailed() as Void {
        if (!connected and camera!=null) {
            try {
                BleAPI.unpairDevice(camera);
            } catch (ex) {}
        }
        BleAPI.setScanState(Ble.SCAN_STATE_OFF);
    }

    public function onConnectedStateChanged(device as Ble.Device, state as Ble.ConnectionState) as Void {
        if (device!=null) {
            if (state == Ble.CONNECTION_STATE_CONNECTED) {
                if (device.isBonded()) {
                    onConnect(device);
                } else {
                    connected = false;
                    device.requestBond();
                }
            } else {
                onDisconnect();
            }
        } else {
            connected = false;
            System.println("null device changed connected status");
        }
    }
    
    public function onEncryptionStatus(device as Ble.Device, status as Ble.Status) as Void {
        if (device!=null and status == Ble.STATUS_SUCCESS) {
            if (!connected) {
                onConnect(device);
            }
        } else {
            connected = false;
            System.println("null device changed encryption status");
        }
    }

    private function onConnect(device as Ble.Device?) as Void {
        BleAPI.setScanState(Ble.SCAN_STATE_OFF);
        camera = null;
        
        if (device == null) { throw new Exception(); }

        var service = device.getService(Ble.stringToUuid(GattProfileManager.GOPRO_CONTROL_SERVICE));
        if (service != null) {
            requestQueue = new GattRequestQueue(service);
        } else {
            try {
                BleAPI.unpairDevice(device);
            } catch (ex) {}

            onDisconnect();
            onPairingFailed();
            return;
        }

        CameraDelegate.onConnect(device);

        keepAliveTimer = getApp().timerController.start(method(:keepAlive), 20, true);
    }

    public function keepAlive() as Void {
        if (connected and requestQueue != null) {
            var data = [0x03, 0x5b, 0x01, 0x42]b;
            requestQueue.add(GattRequest.WRITE_CHARACTERISTIC, GattProfileManager.getUuid(GattProfileManager.UUID_COMMAND_CHAR), data);
        } else {
            throw new Exception();
        }
    }

    public function onDisconnect() as Void {
        // put camera to sleep and close connection
        if (connected) {
            getApp().timerController.stop(keepAliveTimer);
            BleAPI.setDelegate(null as Ble.BleDelegate);
            try {
                if (camera != null) {
                    BleAPI.unpairDevice(camera);
                    camera = null;
                }
            } catch (ex) {}
        }
        if (requestQueue != null) {
            requestQueue.close();
            requestQueue = null;
        }
        CameraDelegate.onDisconnect();
    }

    public function send(
        type as GattRequest.RequestType,
        uuid as GattProfileManager.GoProUuid,
        data as ByteArray
    ) as Void {
        if (requestQueue == null) { throw new Exception(); }
        requestQueue.add(type, GattProfileManager.getUuid(uuid), data);
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

    public function onCharacteristicWrite(characteristic as Ble.Characteristic, status as Ble.Status) as Void {
        if (requestQueue == null) { throw new Exception(); }
        requestQueue.onRequestProcessed(GattRequest.WRITE_CHARACTERISTIC, characteristic.getUuid(), status);
    }

    public function onDescriptorWrite(descriptor as Ble.Descriptor, status as Ble.Status) as Void {
        if (requestQueue == null) { throw new Exception(); }
        requestQueue.onRequestProcessed(GattRequest.REGISTER_NOTIFICATION, descriptor.getUuid(), status);
    }
}