import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;

using Toybox.BluetoothLowEnergy as Ble;
using InterfaceComponentsManager as ICM;
using BleApiWrapper as BleAPI;


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
                GoProSettings.LED               => GoProSettings.LED_ALL_ON,
                GoProSettings.GPS               => 1,
                GoProSettings.PHOTO_LENS        => GoProSettings.WIDE_7MP,
            } as FakeGoProDevice.FakeGoProSettings,
            {
                GoProCamera.CAPTURE_MODE        => GoProCamera.MODE_VIDEO,
                GoProCamera.ENCODING            => 0,
                GoProCamera.ENCODING_DURATION   => 0,
                GoProCamera.SD_REMAINING        => 6942,
                GoProCamera.BATTERY             => 42,
                GoProCamera.PHOTOS_TAKEN        => 1234,
            } as FakeGoProDevice.FakeGoProStatuses,
            new FakeGoProSpecs.SpecsH5Session()
        );
        BleAPI.scannedDevices[0].goproId = BleAPI.device.specs.cameraId;

        var processMethod = BleAPI.device.method(:processRequests);
        getApp().timerController.start(processMethod, 1, true);
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
        var menu = new Menu2(null);
        getApp().viewController.push(menu, new HomeMenuDelegate(menu, self), SLIDE_IMMEDIATE);
        return true;
    }

    (:mobile)
    public function startScan() as Void {
        // quick fix for missing startScan function with mobile builds
    }

    (:ble)
    public function startScan() as Void {
        var scanMenu = ICM.newCustomMenu(0.1, 0.3);
        var menuDelegate = new ScanMenuDelegate(scanMenu, method(:onScanResult));
        (delegate as BluetoothDelegate).setScanMenuDelegate(menuDelegate);
        menuDelegate.startScan();
        getApp().viewController.push(scanMenu, menuDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    (:ble)
    public function onScanResult(device as Ble.ScanResult?) as Void {
        if (scanResultToStorage(device)) {
            Application.Storage.setValue("lastPairedDevice", device as Storage.ValueType);
        }
        (delegate as BluetoothDelegate).setScanMenuDelegate(null);
        BleAPI.setScanState(Ble.SCAN_STATE_SCANNING);
        delegate.connect(device);
    }

    (:ble :inline :release)
    public function scanResultToStorage(device as Ble.ScanResult?) as Boolean {
        return device instanceof Ble.ScanResult and !device.equals(lastPairedDevice);
    }

    (:ble :inline :debug)
    public function scanResultToStorage(device as Ble.ScanResult?) as Boolean {
        return device instanceof Ble.ScanResult and !device.equals(lastPairedDevice)
            and !(device instanceof BleApiWrapper.MockScanResult);
    }
}