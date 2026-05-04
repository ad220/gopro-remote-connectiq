import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

(:ble :release)
class BleApiCallbacks extends Ble.BleDelegate {

    private var delegate;

    public function initialize(delegate as BluetoothDelegate) {
        BleDelegate.initialize();

        self.delegate = delegate;
    }

    public function onScanStateChange(scanState as Ble.ScanState, status as Ble.Status) as Void {
        delegate.onScanStateChange(scanState, status);
    }

    public function onScanResults(scanResults as Ble.Iterator) as Void {
        delegate.onScanResults(scanResults);
    }

    public function onConnectedStateChanged(device as Ble.Device, state as Ble.ConnectionState) as Void {
        delegate.onConnectedStateChanged(device, state);
    }
        
    public function onEncryptionStatus(device as Ble.Device, status as Ble.Status) as Void {
        delegate.onEncryptionStatus(device, status);
    }

    public function onCharacteristicChanged(characteristic as Ble.Characteristic, value as ByteArray) as Void {
        delegate.onCharacteristicChanged(characteristic, value);
    }

    public function onCharacteristicRead(characteristic as Ble.Characteristic, status as Ble.Status, value as ByteArray) as Void {
        delegate.onCharacteristicRead(characteristic, status, value);
    }

    public function onCharacteristicWrite(characteristic as Ble.Characteristic, status as Ble.Status) as Void {
        delegate.onCharacteristicWrite(characteristic, status);
    }

    public function onDescriptorWrite(descriptor as Ble.Descriptor, status as Ble.Status) as Void {
        delegate.onDescriptorWrite(descriptor, status);
    }
}