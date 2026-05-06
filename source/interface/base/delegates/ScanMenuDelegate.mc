import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using InterfaceComponentsManager as ICM;

(:ble)
class ScanMenuDelegate extends Menu2InputDelegate {

    typedef ScanEntry as {:name as String, :device as Ble.ScanResult, :menuid as Char};

    private const SCAN_TITLE    = WatchUi.loadResource(Rez.Strings.ScanTitle)       as String;
    private const SCAN_CANCEL   = WatchUi.loadResource(Rez.Strings.ScanCancel)      as String;
    private const SCAN_RESTART  = WatchUi.loadResource(Rez.Strings.ScanRestart)     as String;
    private const EXIT          = WatchUi.loadResource(Rez.Strings.Exit)            as String;
    private const DEVICES_FOUND = WatchUi.loadResource(Rez.Strings.DevicesFound)    as String;

    private var menu as CustomMenu;
    private var statusItem as PickerItem;
    private var cancelItem as PickerItem;


    private var scanResults as Array<ScanEntry>;
    private var scanState as Ble.ScanState?;
    private var scanTimer as TimerCallback?;
    private var animTimer as TimerCallback?;
    private var scanResultCallback as Method(device as Ble.ScanResult?) as Void;
    private var title as PickerTitle;


    public function initialize(menu as CustomMenu, callback as Method(device as Ble.ScanResult?) as Void) {
        Menu2InputDelegate.initialize();
        self.menu = menu;
        self.statusItem = new PickerItem("status", 0xF0 as Char, 0xFF as Char);
        self.cancelItem = new PickerItem("cancel", 0xF8 as Char, 0xFF as Char);
        self.scanResults = [];
        self.scanResultCallback = callback;
        self.title = new PickerTitle("scan");
        menu.setTitle(title);
        menu.addItem(self.statusItem);
        menu.addItem(self.cancelItem);
    }

    public function startScan() as Void {
        if (scanState!=Ble.SCAN_STATE_SCANNING) {
            BleAPI.setScanState(Ble.SCAN_STATE_SCANNING);
            scanTimer = getApp().timerController.start(method(:stopScan), 100, false);
            animTimer = getApp().timerController.start(method(:animate), 5, true);

            statusItem.setLabel(". . .");
            cancelItem.setLabel(SCAN_CANCEL);
            title.setTitle(SCAN_TITLE);
            WatchUi.requestUpdate();
        }
    }

    public function stopScan() as Void {
        if (scanState!=Ble.SCAN_STATE_OFF) {
            BleAPI.setScanState(Ble.SCAN_STATE_OFF);
            getApp().timerController.stop(scanTimer);
            getApp().timerController.stop(animTimer);

            statusItem.setLabel(SCAN_RESTART);
            cancelItem.setLabel(EXIT);
            title.setTitle(scanResults.size()+DEVICES_FOUND);
            WatchUi.requestUpdate();
        }
    }

    public function animate() as Void {
        if (scanState == Ble.SCAN_STATE_SCANNING) {
            var label = statusItem.getLabel() + " .";
            if (label.length() > 5) { label = "."; }
            
            statusItem.setLabel(label);
            WatchUi.requestUpdate();
        }
    }

    public function setScanState(state as Ble.ScanState) as Void {
        scanState = state;
    }

    public function onScanResults(results as Array<Ble.ScanResult>) as Void{
        for(var i=0; i<results.size(); i++){
            if (!isDeviceInMenu(results[i])) {

                var label = results[i].getDeviceName();

                if (label == null) {
                    // from Open GoPro documentation, Model ID is given in byte 13
                    var camId = CameraDelegate.getGoProId(results[i]) as Number;
                    if (camId == -1) { camId = 0; }

                    label = CameraDelegate.goproModelString[camId];
                    if (label instanceof Symbol) {
                        label = ICM.loadString(label);
                    } else {
                        label = loadResource(Rez.Strings.HERO) as String + label;
                    }
                }

                var id = scanResults.size() as Char;
                var entryItem = new PickerItem(label, id, 0xFF as Char);
                menu.updateItem(entryItem, scanResults.size());
                menu.updateItem(statusItem, scanResults.size()+1);
                menu.addItem(cancelItem);
                scanResults.add({:name => label, :device => results[i], :menuid => id});    
                WatchUi.requestUpdate();
            }
        }
    }

    private function isDeviceInMenu(device as Ble.ScanResult) as Boolean {
        for (var i=0; i<scanResults.size(); i++) {
            var dev = scanResults[i].get(:device) as Ble.ScanResult;
            if (dev.isSameDevice(device)) {
                return true;
            }
        }
        return false;
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (id == null) { return; } // TODO(error): null warning
        
        switch (id) {
            case 0xF0: // status
                if (scanState==Ble.SCAN_STATE_OFF) {
                    startScan();
                }
                break;
            case 0xF8: // cancel
                if (scanState==Ble.SCAN_STATE_SCANNING) {
                    stopScan();
                } else {
                    onBack();
                }
                break;            
            default:
                // pair device and quit menu
                for (var i=0; i<scanResults.size(); i++) {
                    if (scanResults[i].get(:menuid)==item.getId()) {
                        stopScan();
                        var device = scanResults[i].get(:device);
                        
                        getApp().viewController.pop(SLIDE_IMMEDIATE);
                        WatchUi.requestUpdate();
                        scanResultCallback.invoke(device);
                        break;
                    }
                }
                break;
        }
    }

    public function onBack() as Void {
        stopScan();
        getApp().viewController.returnHome(null, null);
    }
}
