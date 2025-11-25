import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

class CameraDelegate extends Ble.BleDelegate {

    public enum QueryId {
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

    protected var connected as Boolean;
    private var pairingTimer as TimerCallback?;
    private var queryReplyLength as Number?;
    private var queryReplyBuffer as ByteArray?;

    public function initialize() {
        BleDelegate.initialize();
        connected = false;
    }

    public function connect(device as Ble.ScanResult?) as Void {
        pairingTimer = getApp().timerController.start(method(:onPairingFailed), 20, false);

        var pushMethod = getApp().viewController.method(getApp().fromGlance ? :switchTo : :push);
        var delegate = getApp().fromGlance ? null : new NotifDelegate();
        pushMethod.invoke(
            new NotifView(ConnectDelegate.CONNECTING_NOTIF, NotifView.NOTIF_INFO),
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
        pairingTimer.stop();
        pairingTimer = null;

        getApp().gopro = new GoProCamera(self, method(:onDisconnect));
        getApp().gopro.registerSettings();
        
        var pushView = getApp().viewController.method(getApp().fromGlance ? :switchTo : :push);
        pushView.invoke(new RemoteView(), new RemoteDelegate(), WatchUi.SLIDE_LEFT);
    }

    public function onDisconnect() as Void {
        if (connected) {
            connected = false;
            getApp().viewController.returnHome(null, null);
        }
    }

    public function onPairingFailed() as Void {
        getApp().viewController.push(new NotifView(ConnectDelegate.CONNECT_ERROR_NOTIF, NotifView.NOTIF_ERROR), new NotifDelegate(), WatchUi.SLIDE_DOWN);
        pairingTimer = null;
    }

    public function send(
        type as GattRequest.RequestType,
        uuid as GattProfileManager.GoProUuid,
        data as ByteArray
    ) as Void {
        // Must be implemented by subclasses
    }
    
    protected function decodeQuery(response as ByteArray) as Void {
        if (response[0] & 0xe0 == 0x00) { // 5-bit length packets
            readTLVMessage(response.slice(1, null));
        } else if (response[0] & 0xe0 == 0x20) { // 13-bit length packet
            queryReplyLength = ((response[0] & 0x1f) << 8) + response[1];
            queryReplyBuffer = response.slice(2, null);
        } else if (response[0] & 0xe0 == 0x40) { // 16-bit length packet
            queryReplyLength = (response[1] << 8) + response[2];
            queryReplyBuffer = response.slice(3, null);
        } else if ((response[0] & 0x80) == 0x80) { // Continuation packet
            queryReplyBuffer.addAll(response.slice(1, null));
            if (queryReplyBuffer.size() == queryReplyLength) {
                readTLVMessage(queryReplyBuffer);
            }
        }
    }

    private function readTLVMessage(message as ByteArray) as Void {
        if (message.size()<2) {
            System.println("TLV Message too short");
            return;
        }
        var gopro = getApp().gopro;
        var queryId = message[0];
        var status = message[1];
        var data = message.slice(2, null);
        var decoder = null;

        if (status != 0) {
            System.println("Wrong query status received from camera, value: " + status.toNumber());
        }
        
        var mask = queryId & 0x1F;
        if      (mask ^ 0x12 == 0) { decoder = gopro.method(:onReceiveSetting); }
        else if (mask ^ 0x13 == 0) { decoder = gopro.method(:onReceiveStatus); }
        else if (mask ^ 0x02 == 0) { decoder = gopro.method(:onReceiveAvailable); }
        else {
            System.println("Unknown queryId: " + queryId.toNumber());
            return;
        }

        var type;
        var length;
        var value;

        for (var i=0; i<data.size(); i+=2+length) {
            type = data[i] as Char;
            length = data[i+1];
            value = data.slice(i+2, i+2+length);
            (decoder as Method(id as Char, value as ByteArray) as Void).invoke(type, value);
        }
        if (queryId == REGISTER_AVAILABLE or queryId == NOTIF_AVAILABLE) {
            gopro.applyAvailableSettings();
        }
        WatchUi.requestUpdate();
    }
}