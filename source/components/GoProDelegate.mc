import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

class GoProDelegate extends Ble.BleDelegate {

    private var scanResultCallback as Method(scanResults as [Ble.ScanResult]) as Void?;

    public function initialize() {
        BleDelegate.initialize();
    }

    public function onProfileRegister(uuid as Ble.Uuid, status as Ble.Status) as Void {
        
    }

    public function onScanStateChange(scanState as Ble.ScanState, status as Ble.Status) as Void {
        System.println("BLE scan state changed : " + scanState + " / " + status);
    }

    public function setScanResultCallback(callback as Method(scanResults as [Ble.ScanResult]) as Void) {
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
                    }
                }
            }
            scanResultCallback.invoke(scanResultsArray);
        } else {
            System.println("scanResultCallback is null");
        }
    }

    public function onConnectedStateChanged(device as Ble.Device, state as Ble.ConnectionState) as Void {
        
    }

    public function onEncryptionStatus(device as Ble.Device, status as Ble.Status) as Void {
        
    }

    public function onCharacteristicChanged(characteristic as Ble.Characteristic, value as ByteArray) as Void {
        
    }

    public function onCharacteristicRead(characteristic as Ble.Characteristic, status as Ble.Status, value as ByteArray) as Void {
        
    }

    public function onCharacteristicWrite(characteristic as Ble.Characteristic, status as Ble.Status) as Void {
        
    }

    public function onDescriptorRead(descriptor as Ble.Descriptor, status as Ble.Status, value as ByteArray) as Void {
        
    }

    public function onDescriptorWrite(descriptor as Ble.Descriptor, status as Ble.Status) as Void {
        
    }
}