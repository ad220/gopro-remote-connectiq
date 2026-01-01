import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using InterfaceComponentsManager as ICM;


class ConnectDelegate extends WatchUi.BehaviorDelegate {
    
    (:ble) private var lastPairedDevice as Ble.ScanResult?;

    private var delegate as CameraDelegate;

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

    (:mobile)
    public function initialize(lastPairedDevice as Ble.ScanResult?) {
        BehaviorDelegate.initialize();
        self.delegate = new MobileDelegate();
    }

    (:debug :ble)
    public function initialize(lastPairedDevice as Ble.ScanResult?) {
        BehaviorDelegate.initialize();
        self.lastPairedDevice = lastPairedDevice;
        self.delegate = new BluetoothDelegate();
        GattProfileManager.registerProfile(
            Ble.stringToUuid(GattProfileManager.GOPRO_CONTROL_SERVICE),
            GattProfileManager.UUID_COMMAND_CHAR, 
            GattProfileManager.UUID_CONTROL_MAX
        );
        
        BleAPI.device = new FakeGoProDevice(
            {
                GoProSettings.RESOLUTION        => 1,
                GoProSettings.LENS              => GoProSettings.WIDE,
                GoProSettings.FRAMERATE         => 5,
                GoProSettings.FLICKER           => GoProSettings.HZ60,
                GoProSettings.HYPERSMOOTH       => GoProSettings.HS_HIGH,
                GoProSettings.LED               => GoProSettings.LED_ON
            } as FakeGoProDevice.FakeGoProSettings,
            {
                GoProCamera.ENCODING            => 10,
                GoProCamera.ENCODING_DURATION   => 0,
                GoProCamera.SD_REMAINING        => 6942,
                GoProCamera.BATTERY             => 42
            } as FakeGoProDevice.FakeGoProStatuses,
            new FakeGoProSpecs.SpecsH11Mini()
        );
    }

    
    (:ble)
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

    (:mobile)
    public function onSelect() as Boolean {
        if (!delegate.isPairing()){
            delegate.connect(null);
        }
        return true;
    }

    (:ble)
    public function onMenu() as Boolean {
        startScan();
        return true;
    }

    (:ble)
    private function startScan() as Void {
        var scanMenu = new CustomMenu((0.1*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.30*ICM.screenH).toNumber()});
        var menuDelegate = new ScanMenuDelegate(scanMenu, method(:onScanResult));
        (delegate as BluetoothDelegate).setScanMenuDelegate(menuDelegate);
        menuDelegate.startScan();
        getApp().viewController.push(scanMenu, menuDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    (:ble)
    public function onScanResult(device as Ble.ScanResult?) as Void {
        if (device instanceof Ble.ScanResult and !device.equals(lastPairedDevice)) {
            Storage.setValue("lastPairedDevice", device as Application.PropertyValueType);
        }
        (delegate as BluetoothDelegate).setScanMenuDelegate(null);
        BleAPI.setScanState(Ble.SCAN_STATE_SCANNING);
        delegate.connect(device);
    }
}