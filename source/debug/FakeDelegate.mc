import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;


(:debug) class FakeDelegate extends CameraDelegate {

    private var fakeDevice as FakeGoProDevice?;
   
    public function initialize() {
        CameraDelegate.initialize();
        self.fakeDevice = new FakeGoProDevice(weak());
    }

    public function connect(device as Ble.ScanResult?) as Void {
        CameraDelegate.connect(device);
        onConnect(null);
    }

    public function send(
        type as GattRequest.RequestType,
        uuid as GattProfileManager.GoProUuid,
        data as ByteArray
    ) as Void {
        fakeDevice.send(uuid, data);
    }

    public function onReceive(uuid as GattProfileManager.GoProUuid, request as ByteArray) {
        decodeQuery(request);
    }
}