import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;

(:ble :debug)
class BleApiCallbacks extends Ble.BleDelegate {

    var delegate as BluetoothDelegate;

    public function initialize(delegate as BluetoothDelegate) {
        BleDelegate.initialize();

        self.delegate = delegate;
    }
}