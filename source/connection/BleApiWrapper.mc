import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;


(:ble :release)
module BleApiWrapper {

    typedef GattProfile as {
        :uuid as Ble.Uuid,
        :characteristics as Lang.Array<{
            :uuid as Ble.Uuid,
            :descriptors as Lang.Array<Ble.Uuid>
        }>
    };


    (:inline :force_dce)
    function registerProfile(profile as GattProfile) as Void {
        Ble.registerProfile(profile);
    }

    (:inline :force_dce)
    function setDelegate(delegate as Ble.BleDelegate) as Void {
        Ble.setDelegate(delegate);
    }

    (:inline :force_dce)
    function setScanState(state as Ble.ScanState) as Void {
        Ble.setScanState(state);
    }

    (:inline :force_dce)
    function pairDevice(device as Ble.ScanResult) as Ble.Device? {
        return Ble.pairDevice(device);
    }

    (:inline :force_dce)
    function unpairDevice(device as Ble.Device) as Void {
        Ble.unpairDevice(device);
    }    
}
