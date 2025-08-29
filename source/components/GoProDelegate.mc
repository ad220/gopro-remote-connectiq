import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

class GoProDelegate extends Ble.BleDelegate {

    private enum QueryId {
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
    private var scanStateChangeCallback as Method(state as Ble.ScanState) as Void?;
    private var scanResultCallback as Method(scanResults as [Ble.ScanResult]) as Void?;
    private var requestQueue as GattRequestQueue?;

    public function initialize(timerController as TimerController) {
        self.timerController = timerController;
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
                    initiateConnection(device);
                } else {
                    device.requestBond();
                }                
            }
        } else {
            System.println("null device changed connected status");
        }
    }
    
    public function onEncryptionStatus(device as Ble.Device, status as Ble.Status) as Void {
        if (device!=null and status == Ble.STATUS_SUCCESS) {
            initiateConnection(device);
        } else {
            System.println("null device changed encryption status");
        }
    }

    private function initiateConnection(device as Ble.Device) as Void {
        var service = device.getService(GattProfileManager.GOPRO_CONTROL_SERVICE);
        requestQueue = new GattRequestQueue(service, timerController);
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
    }



    public function onCharacteristicChanged(characteristic as Ble.Characteristic, value as ByteArray) as Void {
        
    }

    public function onCharacteristicRead(characteristic as Ble.Characteristic, status as Ble.Status, value as ByteArray) as Void {
        
    }

    public function onCharacteristicWrite(characteristic as Ble.Characteristic, status as Ble.Status) as Void {
        requestQueue.onRequestProcessed(characteristic.getUuid(), status);
    }

    public function onDescriptorWrite(descriptor as Ble.Descriptor, status as Ble.Status) as Void {
        requestQueue.onRequestProcessed(descriptor.getUuid(), status);        
    }
}