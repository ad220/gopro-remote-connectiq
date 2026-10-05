import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.WatchUi;
import Toybox.Graphics;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;


(:test)
module ScanMenuDelegateTest {

    function callback(scanResult as Ble.ScanResult?) as Void {
        callbackCount += 1;
    }

    var dummyCallback as Method(scanResult as Ble.ScanResult?) as Void = new Lang.Method(self, :callback);
    var callbackCount as Number = 0;

    function initMenu() as [TestInit.DebugCustomMenu, ScanMenuDelegate] {
        var menu = new TestInit.DebugCustomMenu(
            (0.1*Screen.HEIGHT).toNumber()<<1,
            Graphics.COLOR_BLACK,
            {:titleItemHeight => (0.30*Screen.HEIGHT).toNumber()}
        );
        var delegate = new ScanMenuDelegate(menu, dummyCallback);

        return [menu, delegate];
    }


    (:test)
    function testScanResults(logger as Test.Logger) as Boolean {
        var menu = initMenu();

        // Test that scan results are processed correctly
        var scanResults = [
            new BleAPI.MockScanResult(1, "mock", 0),
            new BleAPI.MockScanResult(2, null, 0)
        ] as Array<Ble.ScanResult>;

        menu[1].onScanResults(scanResults);

        if (menu[0].debugItems.size() != 4) {
            logger.error("Should have 2 scan results, got " + (menu[0].debugItems.size() - 2));
            return false;
        }

        scanResults = [
            new BleAPI.MockScanResult(1, "mock1", 0),
            new BleAPI.MockScanResult(2, "mock2", 0),
            new BleAPI.MockScanResult(3, null, 0),
            new BleAPI.MockScanResult(4, "mock4", 0),
            new BleAPI.MockScanResult(5, null, 0)
        ] as Array<Ble.ScanResult>;

        menu[1].onScanResults(scanResults);

        if (menu[0].debugItems.size() != 7) {
            logger.error("Should have 5 scan results, got " + (menu[0].debugItems.size() - 2));
            return false;
        }

        return true;
    }

    (:test)
    function testScanResultName(logger as Test.Logger) as Boolean {
        var menu = initMenu();

        var scanResults = [
            new BleAPI.MockScanResult(10, "GoPro 4269", GoProCamera.GP_UNKNOWN),
            new BleAPI.MockScanResult(11, null, GoProCamera.GP_HERO4S),
            new BleAPI.MockScanResult(12, null, GoProCamera.GP_HERO4B),
            new BleAPI.MockScanResult(13, null, GoProCamera.GP_HERO5B),
            new BleAPI.MockScanResult(14, null, GoProCamera.GP_HERO5S),
            new BleAPI.MockScanResult(15, null, GoProCamera.GP_FUSION),
            new BleAPI.MockScanResult(16, null, GoProCamera.GP_HERO6B),
            new BleAPI.MockScanResult(17, null, GoProCamera.GP_HERO7B),
            new BleAPI.MockScanResult(18, null, GoProCamera.GP_HERO7W),
            new BleAPI.MockScanResult(19, null, GoProCamera.GP_HERO7S),
            new BleAPI.MockScanResult(20, null, GoProCamera.GP_HERO2018),
            new BleAPI.MockScanResult(21, null, GoProCamera.GP_HERO8),
            new BleAPI.MockScanResult(22, null, GoProCamera.GP_MAX),
            new BleAPI.MockScanResult(23, null, GoProCamera.GP_HERO9),
            new BleAPI.MockScanResult(24, null, GoProCamera.GP_HERO10),
            new BleAPI.MockScanResult(25, null, GoProCamera.GP_HERO11),
            new BleAPI.MockScanResult(26, null, GoProCamera.GP_HERO11M),
            new BleAPI.MockScanResult(27, null, GoProCamera.GP_HERO12),
            new BleAPI.MockScanResult(28, null, GoProCamera.GP_MAX2),
            new BleAPI.MockScanResult(29, null, GoProCamera.GP_HERO13),
            new BleAPI.MockScanResult(30, null, GoProCamera.GP_HERO2024),
            new BleAPI.MockScanResult(31, null, GoProCamera.GP_HEROLIT),
            new BleAPI.MockScanResult(32, null, GoProCamera.GP_MISSION1PRO),
            new BleAPI.MockScanResult(33, null, GoProCamera.GP_MISSION1),
            new BleAPI.MockScanResult(34, null, GoProCamera.GP_MISSION1PROILS),
        ] as Array<Ble.ScanResult>;

        var expectedNames = [
            "GoPro 4269",
            "GoPro HERO4",
            "GoPro HERO4",
            "GoPro HERO5",
            "GoPro HERO5",
            "GoPro Fusion",
            "GoPro HERO6",
            "GoPro HERO7",
            "GoPro HERO7",
            "GoPro HERO7",
            "GoPro HERO2018",
            "GoPro HERO8",
            "GoPro MAX",
            "GoPro HERO9",
            "GoPro HERO10",
            "GoPro HERO11",
            "GoPro HERO11",
            "GoPro HERO12",
            "GoPro MAX",
            "GoPro HERO13",
            "GoPro HERO2024",
            "GoPro HERO Lit",
            "GoPro Mission1",
            "GoPro Mission1",
            "GoPro Mission1",
        ];

        menu[1].onScanResults(scanResults);

        if (menu[0].debugItems.size() != expectedNames.size() + 2) {
            logger.error("Should have 25 scan results, got " + (menu[0].debugItems.size() - 2));
            return false;
        }

        var result = true;
        for (var i=0; i<menu[0].debugItems.size() - 2; i+=1) {
            var itemName = menu[0].debugItems[i].getLabel();
            if (!itemName.equals(expectedNames[i])) {
                logger.error("Wrong scan result name, expected: " + expectedNames[i] + " got: " + itemName);
                result = false;
            }
        }

        return result;
    }

    (:test)
    function testSelectDevice(logger as Test.Logger) as Boolean {
        var viewController = new ViewDebugController();
        getApp().viewController = viewController;

        var menu = initMenu();
        viewController.push(menu[0], menu[1], WatchUi.SLIDE_IMMEDIATE);
        callbackCount = 0;

        var scanResults = [
            new BleAPI.MockScanResult(1, null, 0),
            new BleAPI.MockScanResult(2, null, 0)
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