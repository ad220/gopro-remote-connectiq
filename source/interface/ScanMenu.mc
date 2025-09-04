import Toybox.System;
import Toybox.Lang;
import Toybox.WatchUi;

using Toybox.BluetoothLowEnergy as Ble;


class ScanMenuDelegate extends Menu2InputDelegate {

    typedef ScanEntry as {:name as String, :device as Ble.ScanResult, :menuid as Char};

    private const goproModelTable = {
        55      => WatchUi.loadResource(Rez.Strings.GP55),
        57      => WatchUi.loadResource(Rez.Strings.GP57),
        58      => WatchUi.loadResource(Rez.Strings.GP58),
        60      => WatchUi.loadResource(Rez.Strings.GP60),
        62      => WatchUi.loadResource(Rez.Strings.GP62),
        65      => WatchUi.loadResource(Rez.Strings.GP65),
        0xFF    => WatchUi.loadResource(Rez.Strings.GPFF),
    };
    private const SCAN_TITLE    = WatchUi.loadResource(Rez.Strings.ScanTitle);
    private const SCAN_CANCEL   = WatchUi.loadResource(Rez.Strings.ScanCancel);
    private const SCAN_RESTART  = WatchUi.loadResource(Rez.Strings.ScanRestart);
    private const EXIT          = WatchUi.loadResource(Rez.Strings.Exit);
    private const DEVICES_FOUND = WatchUi.loadResource(Rez.Strings.DevicesFound);

    private var menu as CustomMenu;
    private var viewController as ViewController;
    private var timerController as TimerController;
    private var statusItem as OptionPickerItem;
    private var cancelItem as OptionPickerItem;


    private var scanResults as Array<ScanEntry>;
    private var scanState as Ble.ScanState?;
    private var scanTimer as TimerCallback?;
    private var animTimer as TimerCallback?;
    private var scanResultCallback as Method(device as Ble.ScanResult?) as Void;
    private var title as OptionPickerTitle;


    public function initialize(menu as CustomMenu, viewController as ViewController, timerController as TimerController, callback as Method(device as Ble.ScanResult?) as Void) {
        Menu2InputDelegate.initialize();
        self.menu = menu;
        self.viewController = viewController;
        self.timerController = timerController;
        self.statusItem = new OptionPickerItem("status", 0xF0 as Char, 0xFF as Char);
        self.cancelItem = new OptionPickerItem("cancel", 0xF8 as Char, 0xFF as Char);
        self.scanResults = [];
        self.scanResultCallback = callback;
        self.title = new OptionPickerTitle("scan");
        menu.setTitle(title);
        menu.addItem(self.statusItem);
        menu.addItem(self.cancelItem);
        startScan();
    }

    public function startScan() as Void {
        if (scanState!=Ble.SCAN_STATE_SCANNING) {
            Ble.setScanState(Ble.SCAN_STATE_SCANNING);
            scanTimer = timerController.start(method(:stopScan), 40, false);
            animTimer = timerController.start(method(:animate), 2, true);

            statusItem.setLabel("...");
            cancelItem.setLabel(SCAN_CANCEL);
            title.setTitle(SCAN_TITLE);
            WatchUi.requestUpdate();
        }
    }

    public function stopScan() as Void {
        if (scanState!=Ble.SCAN_STATE_OFF) {
            Ble.setScanState(Ble.SCAN_STATE_OFF);
            timerController.stop(scanTimer);
            timerController.stop(animTimer);

            statusItem.setLabel(SCAN_RESTART);
            cancelItem.setLabel(EXIT);
            title.setTitle(scanResults.size()+DEVICES_FOUND);
            WatchUi.requestUpdate();
        }
    }

    public function animate() as Void {
        if (scanState == Ble.SCAN_STATE_SCANNING) {
            var label = statusItem.getLabel() + ".";
            label = label.substring(0, label.length()%4 + 1);
            statusItem.setLabel(label);
            WatchUi.requestUpdate();
        }
    }

    public function setScanState(state as Ble.ScanState) as Void {
        scanState = state;
    }

    public function onScanResults(results as [Ble.ScanResult]) as Void{
        for(var i=0; i<results.size(); i++) {
            if (!isDeviceInMenu(results[i])) {
                // from Open GoPro documentation, Model ID is given in byte 13
                var modelId = results[i].getRawData()[13];
                var id = scanResults.size() as Char;
                var label = goproModelTable.get(modelId);
                if (label==null) { label = goproModelTable.get(0xFF); }

                var entryItem = new OptionPickerItem(label, id, 0xFF as Char);
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
            var res = scanResults[i];
            if (res.get(:device).isSameDevice(device)) {
                return true;
            }
        }
        return false;
    }

    public function onSelect(item as MenuItem) as Void {
        switch (item.getId()) {
            case 0xF0: // status
                if (scanState==Ble.SCAN_STATE_OFF) {
                    startScan();
                }
                break;
            case 0xF8: // cancel
                if (scanState==Ble.SCAN_STATE_SCANNING) {
                    stopScan();
                } else {
                    viewController.pop(SLIDE_LEFT);
                }
                break;            
            default:
                // pair device and quit menu
                for (var i=0; i<scanResults.size(); i++) {
                    if (scanResults[i].get(:menuid)==item.getId()) {
                        stopScan();
                        var device = scanResults[i].get(:device);
                        try {
                            viewController.pop(SLIDE_IMMEDIATE);
                            WatchUi.requestUpdate();
                            scanResultCallback.invoke(device);
                        } catch (ex) {
                            System.println(ex.getErrorMessage());
                        }
                        break;
                    }
                }
                break;
        }
    }

    public function onBack() as Void {
        stopScan();
        viewController.pop(SLIDE_RIGHT);
    }
}