import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.WatchUi;
import Toybox.Graphics;

using Toybox.BluetoothLowEnergy as Ble;
using InterfaceComponentsManager as ICM;
using BleApiWrapper as BleAPI;

(:test)
module ScanMenuDelegateTest {

    function callback(scanResult as Ble.ScanResult?) as Void {
        callbackCount += 1;
    }

    var dummyCallback as Method(scanResult as Ble.ScanResult?) as Void = new Method(ScanMenuDelegateTest, :callback);
    var callbackCount as Number = 0;

    function initMenu() as [TestInit.DebugCustomMenu, ScanMenuDelegate] {
        var menu = new TestInit.DebugCustomMenu(
            (0.1*ICM.screenH).toNumber()<<1,
            Graphics.COLOR_BLACK,
            {:titleItemHeight => (0.30*ICM.screenH).toNumber()}
        );
        var delegate = new ScanMenuDelegate(menu, dummyCallback);

        return [menu, delegate];
    }


    (:test)
    function testScanResults(logger as Test.Logger) as Boolean {
        var menu = initMenu();

        // Test that scan results are processed correctly
        var scanResults = [
            new BleAPI.MockScanResult(1),
            new BleAPI.MockScanResult(2)
        ] as Array<Ble.ScanResult>;

        menu[1].onScanResults(scanResults);

        if (menu[0].debugItems.size() != 4) {
            logger.error("Should have 2 scan results, got " + (menu[0].debugItems.size() - 2));
            return false;
        }

        scanResults = [
            new BleAPI.MockScanResult(1),
            new BleAPI.MockScanResult(2),
            new BleAPI.MockScanResult(3),
            new BleAPI.MockScanResult(4),
            new BleAPI.MockScanResult(5)
        ] as Array<Ble.ScanResult>;

        menu[1].onScanResults(scanResults);

        if (menu[0].debugItems.size() != 7) {
            logger.error("Should have 5 scan results, got " + (menu[0].debugItems.size() - 2));
            return false;
        }

        return true;
    }

    (:test)
    function testSelectDevice(logger as Test.Logger) as Boolean {
        var viewController = new ViewDebugController();
        getApp().viewController = viewController;

        var menu = initMenu();
        viewController.push(menu[0], menu[1], WatchUi.SLIDE_IMMEDIATE);
        callbackCount = 0;

        var scanResults = [
            new BleAPI.MockScanResult(1),
            new BleAPI.MockScanResult(2)
        ] as Array<Ble.ScanResult>;

        menu[1].onScanResults(scanResults);
        menu[1].onSelect(menu[0].debugItems[0]);

        if (callbackCount != 1) {
            logger.error("Device selection callback should have been called once");
            return false;
        }
        
        if (viewController.stack.size() != 0) {
            logger.error("Device selection should clear the menu");
            return false;
        }

        return true;
    }

    (:test)
    function testSelectStart(logger as Test.Logger) as Boolean {
        var viewController = new ViewDebugController();
        getApp().viewController = viewController;

        var menu = initMenu();
        var ble = new BluetoothDelegate();
        ble.setScanMenuDelegate(menu[1]);
        viewController.push(menu[0], menu[1], WatchUi.SLIDE_IMMEDIATE);

        menu[1].startScan();

        if (BleAPI.scanState != Ble.SCAN_STATE_SCANNING) {
            logger.error("App should be scanning for nearby devices");
            return false;
        }
        
        menu[1].onSelect(menu[0].debugItems[0]);
        
        if (BleAPI.scanState != Ble.SCAN_STATE_SCANNING) {
            logger.error("App should still be scanning");
            return false;
        }
        
        menu[1].onSelect(menu[0].debugItems[1]);

        if (BleAPI.scanState != Ble.SCAN_STATE_OFF) {
            logger.error("App shouldn't be scanning for bluetooth devices anymore");
            return false;
        }
        
        System.println(menu[0].debugItems[0].getId());
        menu[1].onSelect(menu[0].debugItems[0]);

        if (BleAPI.scanState != Ble.SCAN_STATE_SCANNING) {
            logger.error("App should be scanning again");
            return false;
        }
        
        menu[1].onSelect(menu[0].debugItems[1]);
        menu[1].onSelect(menu[0].debugItems[1]);

        if (viewController.stack.size() > 0) {
            logger.error("View stack should be empty");
            return false;
        }

        return true;
    }
}