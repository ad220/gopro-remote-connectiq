import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

using Toybox.BluetoothLowEnergy as Ble;
using InterfaceComponentsManager as ICM;


class ConnectView extends WatchUi.View {

    private var label as String;
    private var delegate as ConnectDelegate;

    function initialize(label as String, delegate as ConnectDelegate) {
        View.initialize();

        self.label = label;
        self.delegate = delegate;
    }

    public function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.ConnectLayout(dc));
    }


    function onShow() as Void {
        if (getApp().fromGlance) {
            delegate.onSelect();
        }
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        View.onUpdate(dc);
        (findDrawableById("ConnectLabel") as Text).setText(label);
    }
}


class ConnectDelegate extends WatchUi.BehaviorDelegate {
    static const CONNECTING_NOTIF      = WatchUi.loadResource(Rez.Strings.Connecting);
    static const CONNECT_ERROR_NOTIF   = WatchUi.loadResource(Rez.Strings.ConnectFail);

    private var lastPairedDevice as Ble.ScanResult?;
    private var delegate as BluetoothDelegate or MobileDelegate;

    (:debug)
    public function initialize(lastPairedDevice as Ble.ScanResult?) {
        BehaviorDelegate.initialize();
        self.lastPairedDevice = lastPairedDevice;
        self.delegate = new BluetoothDelegateStub();
        Ble.setDelegate(delegate);
    }

    (:release :ble)
    public function initialize(lastPairedDevice as Ble.ScanResult?) {
        BehaviorDelegate.initialize();
        self.lastPairedDevice = lastPairedDevice;
        self.delegate = new BluetoothDelegate();
        Ble.setDelegate(delegate);
        GattProfileManager.registerProfile(
            Ble.stringToUuid(GattProfileManager.GOPRO_CONTROL_SERVICE),
            GattProfileManager.UUID_COMMAND_CHAR, 
            GattProfileManager.UUID_CONTROL_MAX
        );
        // GattProfileManager.registerProfile(
        //     GattProfileManager.getUuid(GattProfileManager.UUID_MANAGE_SERVICE),
        //     GattProfileManager.UUID_NETWORK_CHAR,
        //     GattProfileManager.UUID_MANAGE_MAX
        // );
    }

    (:release :mobile)
    public function initialize(lastPairedDevice as Ble.ScanResult?) {
        BehaviorDelegate.initialize();
        self.delegate = new MobileDelegate();
    }

    (:debug)
    public function onSelect() as Boolean {
        onScanResult(null);
        return true;
    }
    
    (:release :ble)
    public function onSelect() as Boolean {
        if (lastPairedDevice instanceof Ble.ScanResult) {
            if (!delegate.isPairing()) {
                onScanResult(lastPairedDevice);
            }
        } else {
            startScan();
        }
        return true;
    }

    (:release :mobile)
    public function onSelect() as Boolean {
        if (getApp().fromGlance) {
            getApp().viewController.switchTo(new NotifView(CONNECTING_NOTIF, NotifView.NOTIF_INFO), null, SLIDE_DOWN);
        } else if (!delegate.isPairing()){
            delegate.connect();
            getApp().viewController.push(new NotifView(CONNECTING_NOTIF, NotifView.NOTIF_INFO), new NotifDelegate(), SLIDE_DOWN);
        }
        return true;
    }

    (:release :ble)
    public function onMenu() as Boolean {
        startScan();
        return true;
    }

    (:ble)
    private function startScan() as Void {
        var scanMenu = new CustomMenu((0.1*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.30*ICM.screenH).toNumber()});
        var menuDelegate = new ScanMenuDelegate(scanMenu, method(:onScanResult));
        delegate.setScanStateChangeCallback(menuDelegate.method(:setScanState));
        delegate.setScanResultCallback(menuDelegate.method(:onScanResults));
        getApp().viewController.push(scanMenu, menuDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    (:ble)
    public function onScanResult(device as Ble.ScanResult?) as Void {
        if (device!=null and !device.equals(lastPairedDevice)) {
            Storage.setValue("lastPairedDevice", device as Application.PropertyValueType);
        }
        delegate.setScanStateChangeCallback(null);
        delegate.setScanResultCallback(null);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
        if (getApp().fromGlance) {
            getApp().viewController.switchTo(new NotifView(CONNECTING_NOTIF, NotifView.NOTIF_INFO), null, SLIDE_DOWN);
        } else {
            getApp().viewController.push(new NotifView(CONNECTING_NOTIF, NotifView.NOTIF_INFO), new NotifDelegate(), SLIDE_DOWN);
        }
        delegate.pair(device);
    }
}