import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;


(:debugoff) class FakeDelegate extends CameraDelegate {

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
        fakeDevice.send(GattProfileManager.getUuid(uuid), data);
    }

    public function onReceive(uuid as Ble.Uuid, request as ByteArray) {
        decodeQuery(request);
    }
}