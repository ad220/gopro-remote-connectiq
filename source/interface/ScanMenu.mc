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

    private var scanResults = [] as Array<ScanEntry>;

    private var menu as Menu2;
    private var statusItem as MenuItem?;
    private var cancelItem as MenuItem?;

    public function initialize(menu as Menu2) {
        Menu2InputDelegate.initialize();
        menu.setTitle("Scanning for GoPros");
        self.statusItem = new MenuItem("...", null, "status", null);
        self.cancelItem = new MenuItem("Cancel scan", null, "cancel", null);
        menu.addItem(self.statusItem);
        menu.addItem(self.cancelItem);
        self.menu = menu;

        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
        var scanTimer = new Timer.Timer();
        scanTimer.start(method(:stopScan), 20000, false);
    }

    public function stopScan() as Void{
        Ble.setScanState(Ble.SCAN_STATE_OFF);
        statusItem.setLabel("Restart scan");
        // menu.updateItem(statusItem, scanResults.size());
        menu.setTitle(scanResults.size()+" devices found");
        WatchUi.requestUpdate();
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
            if (scanResults[i].get(:device).isSameDevice(device)) {
                return true;
            }
        }
        return false;
    }

    public function onSelect(item as MenuItem) as Void {
        if (item.getLabel().equals("Restart scan")) {
            statusItem.setLabel("...");
            menu.setTitle("Scanning for GoPros");
            
            Ble.setScanState(Ble.SCAN_STATE_SCANNING);
            var scanTimer = new Timer.Timer();
            scanTimer.start(method(:stopScan), 20000, false);
        }
    }
}