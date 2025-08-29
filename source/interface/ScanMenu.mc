import Toybox.System;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;

using Toybox.BluetoothLowEnergy as Ble;


class ScanMenuDelegate extends Menu2InputDelegate {

    typedef ScanEntry as {:name as String, :device as Ble.ScanResult, :menuid as Number};

    public const goproModelTable = {
        55 => "HERO9 Black",
        57 => "HERO10 Black",
        58 => "HERO11 Black",
        60 => "HERO11 Black Mini",
        62 => "HERO12 Black",
        65 => "HERO13 Black",
    };

    private var menu as Menu2;
    private var viewController as ViewController;
    private var timerController as TimerController;
    private var statusItem as MenuItem;
    private var cancelItem as MenuItem;


    private var scanResults as Array<ScanEntry>;
    private var scanState as Ble.ScanState?;
    private var scanTimer as TimerCallback?;
    private var animTimer as TimerCallback?;
    private var scanResultCallback as Method(device as Ble.ScanResult) as Void;


    public function initialize(menu as Menu2, viewController as ViewController, timerController as TimerController, callback as Method(device as Ble.ScanResult) as Void) {
        Menu2InputDelegate.initialize();
        self.menu = menu;
        self.viewController = viewController;
        self.timerController = timerController;
        self.statusItem = new MenuItem("", null, "status", null);
        self.cancelItem = new MenuItem("", null, "cancel", null);
        self.scanResults = [];
        self.scanResultCallback = callback;
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
            cancelItem.setLabel("Cancel scan");
            menu.setTitle("Scanning for GoPros");
            WatchUi.requestUpdate();
        }
    }

    public function stopScan() as Void {
        if (scanState!=Ble.SCAN_STATE_OFF) {
            Ble.setScanState(Ble.SCAN_STATE_OFF);
            scanTimer.stop();
            animTimer.stop();

            statusItem.setLabel("Restart scan");
            cancelItem.setLabel("Exit");
            menu.setTitle(scanResults.size()+" devices found");
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
                var label = goproModelTable.get(modelId) == null ? "Unkown GoPro Model" : goproModelTable.get(modelId);
                var entryItem = new MenuItem(label, null, "device"+scanResults.size(), null);
                menu.updateItem(entryItem, scanResults.size());
                menu.updateItem(statusItem, scanResults.size()+1);
                menu.addItem(cancelItem);
                scanResults.add({:name => label, :device => results[i], :menuid => "device"+scanResults.size()});    
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
            case "status":
                if (scanState==Ble.SCAN_STATE_OFF) {
                    startScan();
                }
                break;
            case "cancel":
                if (scanState==Ble.SCAN_STATE_SCANNING) {
                    stopScan();
                } else {
                    // exit
                    viewController.pop(SLIDE_LEFT);
                }
                break;            
            default:
                // pair device and quit menu
                for (var i=0; i<scanResults.size(); i++) {
                    if (scanResults[i].get(:menuid).equals(item.getId())) {
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