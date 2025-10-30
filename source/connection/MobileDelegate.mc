import Toybox.Lang;
import Toybox.System;
import Toybox.Communications;

using Toybox.BluetoothLowEnergy as Ble;

(:mobile)
class MobileDelegate {

    private var connected as Boolean;
    private var pairingTimer as TimerCallback?;

    public function initialize() {
        connected = false;
    }

    public function connect() as Void {
        pairingTimer = getApp().timerController.start(method(:onPairingFailed), 20, false);
        Communications.registerForPhoneAppMessages(method(:onReceive) as Communications.PhoneMessageCallback);
        send(true);
        connected = true;
    }

    public function onPairingFailed() as Void {
        getApp().viewController.push(new NotifView(ConnectDelegate.CONNECT_ERROR_NOTIF, NotifView.NOTIF_ERROR), new NotifDelegate(), WatchUi.SLIDE_DOWN);
        disconnect();
    }

    public function disconnect() as Void {
        Communications.registerForPhoneAppMessages(null);
        send(false);
        connected = false;
    }

    public function isConnected() as Boolean {
        return connected;
    }

    public function onReceive(message as Communications.PhoneAppMessage) {
        var data = message.data;
        if (data instanceof Boolean) {
            if (data) {
                pairingTimer.stop();
                pairingTimer = null;

                getApp().gopro = new GoProCamera(self, method(:disconnect));
                getApp().gopro.registerSettings();

                var pushView = getApp().viewController.method(getApp().fromGlance ? :switchTo : :push);
                pushView.invoke(new RemoteView(), new RemoteDelegate(), WatchUi.SLIDE_LEFT);
            } else {
                onPairingFailed();
            }
        } else {
            // TODO: implement reveiving messages from phone comm bridge
        }
    }

    public function send(data as Object) {
        Communications.transmit(data, {}, new Communications.ConnectionListener());
    }

    public function add(type as GattRequest.RequestType, uuid as Ble.Uuid, data as ByteArray) as Void {
        send([type.toString(), uuid.toString(), data.toString()]);
    }
}

// class MobileConnection extends Communications.ConnectionListener {
//     public function initialize() {
//         ConnectionListener.initialize();
//     }

//     public function onError() {
//         // getApp().viewController.push(new NotifView(NotifView.))
//     }
// }