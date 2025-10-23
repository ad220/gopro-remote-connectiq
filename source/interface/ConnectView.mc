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
            getApp().fromGlance = false;
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
    private const CONNECTING_NOTIF      = loadResource(Rez.Strings.Connecting);
    private const CONNECT_ERROR_NOTIF   = loadResource(Rez.Strings.ConnectFail);

    private var lastPairedDevice as Ble.ScanResult?;
    private var delegate as GoProDelegate;


    public function initialize(lastPairedDevice as Ble.ScanResult?) {
        BehaviorDelegate.initialize();

        self.lastPairedDevice = lastPairedDevice;
        self.delegate = new GoProDelegateStub();
        // self.delegate = new GoProDelegate();
        Ble.setDelegate(delegate);
        GattProfileManager.registerProfiles();
    }

    public function onSelect() as Boolean {
        // onScanResult(null);
        if (lastPairedDevice instanceof Ble.ScanResult) {
            onScanResult(lastPairedDevice);
        } else {
            startScan();
        }
        return true;
    }

    public function onMenu() as Boolean {
        startScan();
        return true;
    }

    private function startScan() as Void {
        var scanMenu = new CustomMenu((0.1*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.30*ICM.screenH).toNumber()});
        var menuDelegate = new ScanMenuDelegate(scanMenu, method(:onScanResult));
        delegate.setScanStateChangeCallback(menuDelegate.method(:setScanState));
        delegate.setScanResultCallback(menuDelegate.method(:onScanResults));
        getApp().viewController.push(scanMenu, menuDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    public function onScanResult(device as Ble.ScanResult?) as Void {
        if (device!=null and !device.equals(lastPairedDevice)) {
            Storage.setValue("lastPairedDevice", device as Application.PropertyValueType);
        }
        delegate.setScanStateChangeCallback(null);
        delegate.setScanResultCallback(null);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
        getApp().viewController.push(new NotifView(CONNECTING_NOTIF, NotifView.NOTIF_INFO), new NotifDelegate(), SLIDE_DOWN);
        delegate.pair(device);
    }
}