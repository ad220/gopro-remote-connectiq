import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

(:ble)
class BleApiWrapper extends Ble.BleDelegate {

    private var delegate as WeakReference;

    public function initialize(delegate as BluetoothDelegate) {
        BleDelegate.initialize();

        self.delegate = delegate.weak();
    }

    public function onScanStateChange(scanState as Ble.ScanState, status as Ble.Status) as Void {
        (delegate.get() as BluetoothDelegate).onScanStateChange(scanState, status);
    }

    public function onScanResults(scanResults as Ble.Iterator) as Void {
        (delegate.get() as BluetoothDelegate).onScanResults(scanResults);
    }

    public function onConnectedStateChanged(device as Ble.Device, state as Ble.ConnectionState) as Void {
        (delegate.get() as BluetoothDelegate).onConnectedStateChanged(device, state);
    }
        
    public function onEncryptionStatus(device as Ble.Device, status as Ble.Status) as Void {
        (delegate.get() as BluetoothDelegate).onEncryptionStatus(device, status);
    }

    public function onCharacteristicChanged(characteristic as Ble.Characteristic, value as ByteArray) as Void {
        (delegate.get() as BluetoothDelegate).onCharacteristicChanged(characteristic, value);
    }

    public function onCharacteristicRead(characteristic as Ble.Characteristic, status as Ble.Status, value as ByteArray) as Void {
        (delegate.get() as BluetoothDelegate).onCharacteristicRead(characteristic, status, value);
    }

    public function onCharacteristicWrite(characteristic as Ble.Characteristic, status as Ble.Status) as Void {
        (delegate.get() as BluetoothDelegate).onCharacteristicWrite(characteristic, status);
    }

    public function onDescriptorWrite(descriptor as Ble.Descriptor, status as Ble.Status) as Void {
        (delegate.get() as BluetoothDelegate).onDescriptorWrite(descriptor, status);
    }
}