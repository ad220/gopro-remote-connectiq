import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;

using Toybox.BluetoothLowEnergy as Ble;
using InterfaceComponentsManager as ICM;


class ConnectDelegate extends WatchUi.BehaviorDelegate {
    static const CONNECTING_NOTIF      = WatchUi.loadResource(Rez.Strings.Connecting);
    static const CONNECT_ERROR_NOTIF   = WatchUi.loadResource(Rez.Strings.ConnectFail);

    (:ble) private var lastPairedDevice as Ble.ScanResult?;

    private var delegate as CameraDelegate;

    (:debug)
    public function initialize(lastPairedDevice as Ble.ScanResult?) {
        BehaviorDelegate.initialize();
        self.delegate = new FakeDelegate();
    }

    (:release :ble)
    public function initialize(lastPairedDevice as Ble.ScanResult?) {
        BehaviorDelegate.initialize();
        self.lastPairedDevice = lastPairedDevice;
        self.delegate = new BluetoothDelegate();
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
        delegate.connect(null);
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
        if (!delegate.isPairing()){
            delegate.connect(null);
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
        (delegate as BluetoothDelegate).setScanStateChangeCallback(menuDelegate.method(:setScanState));
        (delegate as BluetoothDelegate).setScanResultCallback(menuDelegate.method(:onScanResults));
        getApp().viewController.push(scanMenu, menuDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    (:ble)
    public function onScanResult(device as Ble.ScanResult?) as Void {
        if (device!=null and !device.equals(lastPairedDevice)) {
            Storage.setValue("lastPairedDevice", device as Application.PropertyValueType);
        }
        (delegate as BluetoothDelegate).setScanStateChangeCallback(null);
        (delegate as BluetoothDelegate).setScanResultCallback(null);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
        delegate.connect(device);
    }
}