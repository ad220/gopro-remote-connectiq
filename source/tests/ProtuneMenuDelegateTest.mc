import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Test;

using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;

(:test)
module ProtuneMenuDelegateTest {

    typedef Fixture as [ProtuneMenu, ProtuneMenuDelegate, ViewDebugController];

    class DebugProtuneMenu extends ProtuneMenu {
        var debugItems as Array<MenuItem>;

        function initialize() {
            ProtuneMenu.initialize();
            self.debugItems = mItems;
        }
    }

    function initProtuneMenu() as Fixture {
        TestInit.initDefaults();
        TestInit.initSettings.put(GoProSettings.PROTUNE, 0);
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);

        var viewController = new ViewDebugController(getApp().viewController);
        getApp().viewController = viewController;

        var menu = new DebugProtuneMenu();
        var delegate = new ProtuneMenuDelegate(menu);
        viewController.push(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
        BleAPI.device.processRequests();
        menu.onShow();

        return [menu, delegate, viewController];
    }


    (:test)
    function testToggleItem(logger as Test.Logger) as Boolean {
        var fixture = initProtuneMenu();
        var menu = fixture[0] as DebugProtuneMenu;

        // first item is Protune, it only has 2 available values so it should be toggled in place
        fixture[1].onSelect(menu.debugItems[0]);
        BleAPI.device.processRequests();

        if (getApp().gopro.getSetting(GoProSettings.PROTUNE) != 1) {
            logger.error("Protune should have been toggled to 1, got: " \
                + getApp().gopro.getSetting(GoProSettings.PROTUNE));
            return false;
        }

        if (fixture[2].getCurrentDelegate() != fixture[1]) {
            logger.error("Toggling an item shouldn't have pushed a view");
            return false;
        }

        return true;
    }


    (:test)
    function testPickItem(logger as Test.Logger) as Boolean {
        var fixture = initProtuneMenu();
        var menu = fixture[0] as DebugProtuneMenu;

        // second item is white balance, it has more than 2 available values so it should open a picker
        fixture[1].onSelect(menu.debugItems[1]);
        BleAPI.device.processRequests();

        var dlgt = fixture[2].getCurrentDelegate();
        if (!(dlgt instanceof SettingPickerDelegate)) {
            logger.error("Selecting white balance should have opened a setting picker");
            return false;
        }

        if ((dlgt as SettingPickerDelegate).getId() != GoProSettings.WHITE_BL) {
            logger.error("Wrong setting in the picker, expected: " + GoProSettings.WHITE_BL \
                + ", got: " + (dlgt as SettingPickerDelegate).getId());
            return false;
        }

        return true;
    }


    (:test)
    function testBackUnregisters(logger as Test.Logger) as Boolean {
        var fixture = initProtuneMenu();
        var device = BleAPI.device as FakeGoProDevice;

        device.requests = [];
        fixture[1].onBack();

        if (device.requests.size() != 1) {
            logger.error("Leaving protune menu should send exactly 1 request, got: " + device.requests.size());
            return false;
        }

        var ids = fixture[0].ids;
        var payload = [ids.size() + 1, GoProDecoder.UNREGISTER_SETTING]b;
        payload.addAll(ids);
        var expected = [GPM.UUID_QUERY_CHAR, payload] as Array;
        if (!TestInit.haveSameData(device.requests[0] as Array, expected)) {
            logger.error("Leaving protune menu should unregister its settings, expected: " \
                + expected + ", got: " + device.requests[0]);
            return false;
        }

        device.processRequests();

        if (fixture[2].getCurrentDelegate() == fixture[1]) {
            logger.error("Protune menu should have been popped");
            return false;
        }

        return true;
    }
}
