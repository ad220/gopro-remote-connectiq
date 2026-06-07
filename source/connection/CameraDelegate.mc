import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using ErrorManager as EM;

class CameraDelegate {

    public static const goproModelTable = [0, 12, 13, 19, 21, 22, 24, 30, 32, 33, 34, 50, 51, 55, 57, 58, 60, 62, 64, 65, 66, 70]b;
      
    public static const goproModelString = [
        :UnknownGP,
        4           /* 01) id:12 -> HERO4 Silver */,
        4           /* 02) id:13 -> HERO4 Black */,
        5           /* 03) id:19 -> HERO5 Black */,
        5           /* 04) id:21 -> HERO5 Session */,
        :Fusion     /* 05) id:22 -> Fusion */,
        6           /* 06) id:24 -> HERO6 Black */,
        7           /* 07) id:30 -> HERO7 Black */,
        7           /* 08) id:32 -> HERO7 White */,
        7           /* 09) id:33 -> HERO7 Silver */,
        2018        /* 10) id:34 -> HERO 2018 */,
        8           /* 11) id:50 -> HERO8 Black */,
        :MAX        /* 12) id:51 -> MAX */,
        9           /* 13) id:55 -> HERO9 Black */,
        10          /* 14) id:57 -> HERO10 Black */,
        11          /* 15) id:58 -> HERO11 Black */,
        11          /* 16) id:60 -> HERO11 Black Mini */,
        12          /* 17) id:62 -> HERO12 Black */,
        :MAX        /* 18) id:64 -> MAX2 */,
        13          /* 19) id:65 -> HERO13 Black */,
        2024        /* 20) id:66 -> HERO (2024) */,
        2025        /* 21) id:70 -> HERO Lit */,
    ];

    public static function getGoProId(device as Ble.ScanResult) as Number {
        var id = goproModelTable.indexOf(device.getRawData()[13]);
        return id != -1 ? id : 0;
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
    protected var goproId as Number?;
    private var pairingTimer as TimerCallback?;
    private var queryReplyLength as Number?;
    private var queryReplyBuffer as ByteArray?;

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
            EM.raise(EM.ERR_COMM, errCode + goproId.toNumber() << 24, :ConnectErr);
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
    
    protected function decodeQuery(response as ByteArray) as Void {
        if      (response[0] & 0xe0 == 0x00) { // 5-bit length packets
            readTLVMessage(response.slice(1, null));
        }
        else if (response[0] & 0xe0 == 0x20) { // 13-bit length packet
            queryReplyLength = ((response[0] & 0x1f) << 8) + response[1];
            queryReplyBuffer = response.slice(2, null);
        }
        else if (response[0] & 0xe0 == 0x40) { // 16-bit length packet
            queryReplyLength = (response[1] << 8) + response[2];
            queryReplyBuffer = response.slice(3, null);
        }
        else if ((response[0] & 0x80) == 0x80) { // Continuation packet
            if (queryReplyBuffer == null) {
                EM.raise(EM.ERR_MSG | EM.SUB_MSG_STRUCT | 0x00 << 16, 0, :WarningErr); 
                return;
            } /* TODO(raise): complete data field */ 

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
        var gopro = getApp().gopro as GoProCamera?;
        if (gopro == null) { EM.raise(EM.ERR_NULL, 3, :CriticalErr); return; }

        var queryId = message[0];
        var status = message[1];
        var data = message.slice(2, null);
        var decoder = null;

        if (status != 0) {
            // TODO(raise): skip msg, check for queue impact ? confirm err_flag
            EM.raise(EM.ERR_MSG | EM.SUB_MSG_STATUS | 0x00 << 16, 0, :SilentErr);
            // System.println("[WARNING]   Wrong query status received from camera, value: " + status.toNumber());
        }
        
        var mask = queryId & 0x1F;
        if      (mask ^ 0x12 == 0 and queryId != 0x32)  { decoder = :onReceiveSetting; }
        else if (mask ^ 0x13 == 0)                      { decoder = :onReceiveStatus; }
        else if (mask ^ 0x02 == 0 or queryId == 0x32)   { decoder = :onReceiveAvailable; }
        else {
            // TODO(raise): skip msg, check for queue impact ? confirm err_flag
            EM.raise(EM.ERR_MSG | EM.SUB_MSG_QUERY | 0x00 << 16, 0, :SilentErr);
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
            gopro.method(decoder).invoke(type, value);
        }
        if (decoder == :onReceiveAvailable) {
            gopro.applyAvailableSettings();
        }
        WatchUi.requestUpdate();
    }
}