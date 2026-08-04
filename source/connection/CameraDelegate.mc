import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using ErrorManager as EM;
using GattProfileManager as GPM;

class CameraDelegate {

    protected var connected as Boolean;
    protected var goproId as Number?;
    private var pairingTimer as TimerCallback?;

    public function initialize() {
        connected = false;
    }

    public function connect(device as Ble.ScanResult?) as Void {
        pairingTimer = getApp().timerController.start(method(:onPairingTimeout), 50, false);

        var pushMethod = getApp().viewController.method(getApp().fromGlance ? :switchTo : :push);
        var delegate = getApp().fromGlance ? null : new NotifDelegate();
        pushMethod.invoke(
            new NotifView(Rez.Strings.Connecting, NotifView.NOTIF_INFO),
            delegate, 
            WatchUi.SLIDE_DOWN
        );

        // Specific behavior must be implemented by subclasses
    }

    public function isConnected() as Boolean{
        return connected;
    }

    public function isPairing() as Boolean {
        return pairingTimer != null;
    }

    protected function onConnect(device as Ble.Device?) as Void {
        connected = true;

        if (pairingTimer != null) {
            pairingTimer.stop();
        }
        pairingTimer = null;

        if (goproId == null) {
            goproId = 0;
            EM.raise(EM.ERR_NULL, 9, :WarningErr);
        }
        var app = getApp();
        app.gopro = new GoProCamera(self, goproId as Number);
        
        var pushView = app.viewController.method(app.fromGlance ? :switchTo : :push);
        pushView.invoke(new RemoteView(), new RemoteDelegate(), WatchUi.SLIDE_LEFT);
        
        app.gopro.registerSettings();
    }

    public function disconnect() as Void {
        if (connected) {
            connected = false;

            getApp().viewController.returnHome(Rez.Strings.Disconnected, NotifView.NOTIF_INFO);
            getApp().gopro = Helper.createNullObject() as GoProCamera;
        }
    }

    public function onPairingTimeout() as Void {
        onPairingFailed(EM.SUB_BLE_TO | 0x01);
    }

    public function onPairingFailed(errCode as Number) as Void {
        if (!connected) {
            if (pairingTimer != null) {
                pairingTimer.stop();
                pairingTimer = null;
            }

            if (goproId == null) { goproId = 0; }
            EM.raise(EM.ERR_COMM + goproId << 24, errCode, :ConnectErr);
        } else {
            EM.raise(EM.ERR_COMM, EM.SUB_BLE_CONN | 0x0F, :WarningErr);
        }
    }

    public function send(
        type as GattRequestQueue.RequestType,
        uuid as GattProfileManager.GoProUuid,
        data as ByteArray
    ) as Void {
        // Must be implemented by subclasses
    }

    (:inline)
    protected function onMessage(charId as GPM.GoProUuid, msg as ByteArray) as Void {
        getApp().gopro.getDecoder().decodeMessage(charId, msg);
    }
}