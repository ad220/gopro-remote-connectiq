import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using ErrorManager as EM;

(:ble)
class BluetoothDelegate extends CameraDelegate {

    private var scanMenuDelegate as ScanMenuDelegate?;

    protected var requestQueue as GattRequestQueue?;

    protected var camera as Ble.Device?;
    protected var keepAliveTimer as TimerCallback?;

    public function initialize() {
        CameraDelegate.initialize();

        BleAPI.setDelegate(new BleApiCallbacks(self));
    }

    public function setScanMenuDelegate(menu as ScanMenuDelegate?) as Void {
        scanMenuDelegate = menu;
    }

    public function onScanStateChange(scanState as Ble.ScanState, status as Ble.Status) as Void {
        if (status == Ble.STATUS_SUCCESS) {
            if (scanMenuDelegate != null) { scanMenuDelegate.setScanState(scanState); }
        }
        else {
            EM.raise(EM.ERR_COMM, EM.SUB_BLE_STATUS | 0x00, :WarningErr);
        }
    }

    public function onScanResults(scanResults as Ble.Iterator) as Void {
        if (scanMenuDelegate!=null) {
            var scanResultsArray = [];
            // filter results with GoPro 0xFEA6 UUID
            for (var device = scanResults.next() as Ble.ScanResult; device!=null; device = scanResults.next()) {
                var uuids = device.getServiceUuids();
                // System.println("[DEBUG]     Scan result raw data: " + device.getRawData());
                for (var uuid = uuids.next() as Ble.Uuid; uuid!=null; uuid = uuids.next()) {
                    // System.println("[DEBUG]     Scan result uuid: " + uuid.toString());
                    if (uuid.toString().equals(GattProfileManager.GOPRO_CONTROL_SERVICE)) {
                        scanResultsArray.add(device);
                        break;
                    }
                }
            }
            scanMenuDelegate.onScanResults(scanResultsArray);
        }
        // else {
        //     System.println("[WARNING]   Scan menu is null");
        // }
    }

    public function connect(device as Ble.ScanResult?) as Void {
        if (device == null) { 
            EM.raise(EM.ERR_NULL, 0, :CriticalErr);
            return;
        }

        CameraDelegate.connect(device);
        goproId = getGoProId(device);

        try {
            camera = BleAPI.pairDevice(device);
        } catch (ex) {
            onPairingFailed(EM.SUB_BLE_API | 0x00);
        }
    }

    public function onPairingFailed(errCode as Number) as Void {
        if (!connected) {
            // System.println("[DEBUG]     Bluetooth pairing failed");
            CameraDelegate.onPairingFailed(errCode);

            if (camera != null) {
                try { BleAPI.unpairDevice(camera); }

                catch (ex) {
                    EM.raise(EM.ERR_COMM, EM.SUB_BLE_API | 0x01, :WarningErr);
                    // System.println("[ERROR]     Unexpected error while unpairing camera : " + ex.getErrorMessage());
                }

                camera = null;
            }

            BleAPI.setScanState(Ble.SCAN_STATE_OFF);
        }
    }

    public function onConnectedStateChanged(device as Ble.Device, state as Ble.ConnectionState) as Void {
        if (state == Ble.CONNECTION_STATE_CONNECTED) {
            if (device.isBonded()) {
                onConnect(device);
            } else {
                connected = false;
                try             { device.requestBond(); }
                catch (ex)      { onPairingFailed(EM.SUB_BLE_API | 0x04); }
            }
        } else {
            if (isPairing())    { onPairingFailed(EM.SUB_BLE_STATUS | 0x0F); }
            else                { onDisconnect(); }
        }
    }
    
    public function onEncryptionStatus(device as Ble.Device, status as Ble.Status) as Void {
        if (status == Ble.STATUS_SUCCESS) {
            if (!connected) {
                onConnect(device);
            }
        } else {
            onPairingFailed(EM.SUB_BLE_STATUS | 0x01);
            connected = false;
        }
    }

    private function onConnect(device as Ble.Device?) as Void {
        BleAPI.setScanState(Ble.SCAN_STATE_OFF);
        
        if (device == null) { 
            EM.raise(EM.ERR_NULL, 1, :CriticalErr);
            return;
        }

        var service = device.getService(Ble.stringToUuid(GattProfileManager.GOPRO_CONTROL_SERVICE));
        if (service != null) {
            requestQueue = new GattRequestQueue(service);
        } else {
            onPairingFailed(EM.SUB_BLE_BADSCD | 0x00);
            return;
        }

        CameraDelegate.onConnect(device);

        keepAliveTimer = getApp().timerController.start(method(:keepAlive), 15, true);
    }

    public function keepAlive() as Void {
        if (connected and requestQueue != null) {
            // System.println("[DEBUG]     keepAlive");

            var data = [0x03, 0x5b, 0x01, 0x42]b;
            requestQueue.add(GattRequestQueue.WRITE_CHARACTERISTIC, GattProfileManager.getUuid(GattProfileManager.UUID_COMMAND_CHAR), data);
        } else {
            // ERA_CRASH(x9v4.0.1)
            EM.raise(EM.ERR_COMM, EM.SUB_BLE_NULLQ | 0x00, :CriticalErr);
        }
    }

    public function disconnect() as Void {
        // close connection
        if (connected) {
            getApp().timerController.stop(keepAliveTimer);
            keepAliveTimer = null;
            
            if (camera != null) {
                try { BleAPI.unpairDevice(camera); }
                catch (ex) { EM.raise(EM.ERR_COMM, EM.SUB_BLE_API | 0x02, :SilentErr); }

                camera = null;
            }
            else {
                EM.raise(EM.ERR_NULL, 2, :SilentErr); // paranoid
            }
        }
    }

    private function onDisconnect() as Void {
        // System.println("[DEBUG]     onDisconnect");
        if (connected) {
            if (camera != null or keepAliveTimer != null) {
                disconnect();
            }
            
            if (requestQueue != null) {
                requestQueue.close();
                requestQueue = null;
            }

            CameraDelegate.disconnect();
        }
        // else {
        //     // System.println("[WARNING]   onDisconnect called while camera already disconnected");
        //     EM.raise(EM.ERR_COMM, EM.SUB_BLE_CONN | 0x00, :SilentErr); // paranoid
        // }
    }

    public function send(
        type as GattRequestQueue.RequestType,
        uuid as GattProfileManager.GoProUuid,
        data as ByteArray
    ) as Void {
        if (requestQueue == null) {
            EM.raise(EM.ERR_COMM, EM.SUB_BLE_NULLQ | 0x01, :CriticalErr);
            return;
        }
        requestQueue.add(type, GattProfileManager.getUuid(uuid), data);
    }

    public function onCharacteristicChanged(characteristic as Ble.Characteristic, value as ByteArray) as Void {
        if (characteristic.getUuid().equals(GattProfileManager.getUuid(GattProfileManager.UUID_QUERY_RESPONSE_CHAR))) {
            decodeQuery(value);
        }
    }

    public function onCharacteristicRead(characteristic as Ble.Characteristic, status as Ble.Status, value as ByteArray) as Void {
        if (status != Ble.STATUS_SUCCESS) {
            // System.println("[WARNING]   Error while reading characteristic");
            EM.raise(EM.ERR_COMM, EM.SUB_BLE_STATUS | 0x02, :SilentErr);
            return;
        }
        if (characteristic.getUuid().equals(GattProfileManager.getUuid(GattProfileManager.UUID_QUERY_RESPONSE_CHAR))) {
            decodeQuery(value);
        }
    }

    public function onCharacteristicWrite(characteristic as Ble.Characteristic, status as Ble.Status) as Void {
        if (requestQueue == null) { EM.raise(EM.ERR_COMM, EM.SUB_BLE_NULLQ | 0x02, :CriticalErr); return; }
        requestQueue.onRequestProcessed(GattRequestQueue.WRITE_CHARACTERISTIC, characteristic.getUuid(), status);
    }

    public function onDescriptorWrite(descriptor as Ble.Descriptor, status as Ble.Status) as Void {
        if (requestQueue == null) { EM.raise(EM.ERR_COMM, EM.SUB_BLE_NULLQ | 0x03, :CriticalErr); return; }
        requestQueue.onRequestProcessed(GattRequestQueue.REGISTER_NOTIFICATION, descriptor.getUuid(), status);
    }
}