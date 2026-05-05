import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

class CameraDelegate {

    public static const goproModelTable = [0, 12, 13, 19, 21, 22, 24, 30, /*41, *//*44, */51, 55, 57, 58, 60, 62, 64, 65]b;
      
    public static const goproModelString = [
        :UnknownGP,
        4           /* id:12 -> HERO4 Silver */,
        4           /* id:13 -> HERO4 Black */,
        5           /* id:19 -> HERO5 Black */,
        5           /* id:21 -> HERO5 Session */,
        :Fusion     /* id:22 -> Fusion */,
        6           /* id:24 -> HERO6 Black */,
        7           /* id:30 -> HERO7 Black */,
        // 4           /* id: -> HERO 2018 */,
        // 4           /* id: -> HERO8 Black*/,
        :MAX        /* id:51 -> MAX */,
        9           /* id:55 -> HERO9 Black */,
        10          /* id:57 -> HERO10 Black */,
        11          /* id:58 -> HERO11 Black*/,
        11          /* id:60 -> HERO11 Black Mini*/,
        12          /* id:62 -> HERO12 Black*/,
        :MAX        /* id:64 -> MAX2 */,
        13          /* id:65 -> HERO13 Black*/,
    ];

    public static function getGoProId(device as Ble.ScanResult) as Char {
        return goproModelTable.indexOf(device.getRawData()[13]).toChar();
    }

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
    protected var goproId as Char?;
    private var pairingTimer as TimerCallback?;
    private var queryReplyLength as Number?;
    private var queryReplyBuffer as ByteArray?;

    public function initialize() {
        connected = false;
    }

    public function connect(device as Ble.ScanResult?) as Void {
        pairingTimer = getApp().timerController.start(method(:onPairingFailed), 50, false);

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

        getApp().gopro = new GoProCamera(self, goproId);
        
        var pushView = getApp().viewController.method(getApp().fromGlance ? :switchTo : :push);
        pushView.invoke(new RemoteView(), new RemoteDelegate(), WatchUi.SLIDE_LEFT);
        
        getApp().gopro.registerSettings();
    }

    public function disconnect() as Void {
        if (connected) {
            connected = false;

            getApp().viewController.returnHome(Rez.Strings.Disconnected, NotifView.NOTIF_INFO);
            getApp().gopro = null as GoProCamera;
        }
    }

    public function onPairingFailed() as Void {
        if (!connected) {
            getApp().viewController.push(new NotifView(Rez.Strings.ConnectFail, NotifView.NOTIF_ERROR), new NotifDelegate(), WatchUi.SLIDE_DOWN);
            pairingTimer = null;
        }
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
        } else if ((response[0] & 0x80) == 0x80 and queryReplyBuffer!=null) { // Continuation packet
            // TODO(error): if buffer null
            queryReplyBuffer.addAll(response.slice(1, null));
            if (queryReplyBuffer.size() == queryReplyLength) {
                readTLVMessage(queryReplyBuffer);
            }
        }
    }

    private function readTLVMessage(message as ByteArray) as Void {
        if (message.size()<2) {
            // System.println("[WARNING]   TLV Message too short");
            return;
        }
        var gopro = getApp().gopro;
        var queryId = message[0];
        var status = message[1];
        var data = message.slice(2, null);
        var decoder = null;

        if (status != 0) {
            // TODO(error): bad camera status
            // System.println("[WARNING]   Wrong query status received from camera, value: " + status.toNumber());
        }
        
        var mask = queryId & 0x1F;
        if      (mask ^ 0x12 == 0 and queryId != 0x32)  { decoder = :onReceiveSetting; }
        else if (mask ^ 0x13 == 0)                      { decoder = :onReceiveStatus; }
        else if (mask ^ 0x02 == 0 or queryId == 0x32)   { decoder = :onReceiveAvailable; }
        else {
            // TODO(error): unknown camera queryId
            // System.println("[WARNING]   Unknown queryId: " + queryId.toNumber());
            return;
        }

        var type;
        var length;
        var value;

        for (var i=0; i<data.size(); i+=2+length) {
            type = data[i] as Char;
            length = data[i+1];
            value = data.slice(i+2, i+2+length);
            // ERA_CRASH(x1v4.0.1): gopro is null
            // This bug shouldn't exist as delegate doesn't exist if gopro is null.
            // GoPro app-wide ref set on instanciation
            // CamDelegate only exists outside of the gopro scope in ConnectViewDelegate
            gopro.method(decoder).invoke(type, value);
        }
        if (decoder == :onReceiveAvailable) {
            gopro.applyAvailableSettings();
        }
        WatchUi.requestUpdate();
    }
}