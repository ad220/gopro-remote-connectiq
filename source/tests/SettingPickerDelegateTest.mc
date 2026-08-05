import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.WatchUi;
import Toybox.Graphics;

using BleApiWrapper as BleAPI;

(:test)
module SettingPickerDelegateTest {

    
    function initMenu(settingId as GoProSettings.SettingId) as [TestInit.DebugCustomMenu, SettingPickerDelegate] {
        var menu = new TestInit.DebugCustomMenu(
            (0.1*Screen.HEIGHT).toNumber()<<1,
            Graphics.COLOR_BLACK,
            {:titleItemHeight => (0.30*Screen.HEIGHT).toNumber()}
        );
        var delegate = new SettingPickerDelegate(menu, settingId);

        return [menu, delegate];
    }

    function getLabels(menu as TestInit.DebugCustomMenu) as Array<String> {
        var result = [];
        for (var i=0; i<menu.debugItems.size(); i+=1) {
            result.add(menu.debugItems[i].getLabel());
        }
        return result;
    }


    (:test)
    function testItemOrder(logger as Test.Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);

        var gopro = getApp().gopro;
        var specs = BleAPI.device.specs;

        specs.availablePhotoLens.addAll([
            GoProSettings.WIDE_12MP,
            GoProSettings.MEDIUM_12MP,
            GoProSettings.NARROW_12MP,
            GoProSettings.LINEAR_12MP,
            GoProSettings.WIDE_9MP,
            GoProSettings.NARROW_FULL,
            GoProSettings.WIDE_27MP,
            GoProSettings.LINEAR_27MP,
            GoProSettings.LINEAR_13MP,
            GoProSettings.WIDE_13MP,
            GoProSettings.UWIDE_13MP,
            GoProSettings.UWIDE_12MP,
            GoProSettings.ULINEAR_13MP,
            GoProSettings.MAXSV_FULL,
            GoProSettings.WIDE_FULL,
            GoProSettings.LINEAR_FULL,
        ]b);

        var settings = [
            GoProSettings.RESOLUTION,
            GoProSettings.LENS,
            GoProSettings.FRAMERATE,
            GoProSettings.LED,
            GoProSettings.HYPERSMOOTH,
            GoProSettings.PHOTO_LENS,
        ];

        gopro.queryValues(GoProDecoder.GET_AVAILABLE, []b.addAll(settings));
        BleAPI.device.processRequests();

        (settings as Array).add(GoProSettings.RATIO);
        var expectedLabels = [
            ["5.3K", "4K", "2.7K", "1080p"],
            ["Wide", "SuperView", "Linear", "Linear + HLvl", "HyperView", "Linear + HLock"],
            ["120 fps", "100 fps", "60 fps", "50 fps", "30 fps", "25 fps", "24 fps"],
            ["Disabled", "Enabled"],
            ["Disabled", "Low", "Boost", "AutoBoost"],
            ["Wide", "Narrow", "Linear", "MAX SuperView", "27MP Wide", "27MP Linear",
                "13MP Wide", "13MP Linear", "13MP Ultra Wide", "13MP Ultra Linear",
                "12MP Wide", "12MP Medium", "12MP Narrow", "12MP Linear", "12MP Ultra Wide",
                "9MP Wide"],
            ["8:7", "4:3", "16:9"],
        ];

        for (var i=0; i<settings.size(); i+=1) {
            var menu = initMenu(settings[i]);
            var labels = getLabels(menu[0]);

            if (!TestInit.haveSameData(labels as Array, expectedLabels[i] as Array)) {
                logger.error(
                    "Unexpected items/order for setting id: " + settings[i] +
                    ", expected: " + expectedLabels[i] +
                    ", got: " + labels
                );
                result = false;
            }
        }

        return result;
    }


    (:test)
    function testSelectItem(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);

        var settingsCamera = [
            GoProSettings.RESOLUTION,
            GoProSettings.LENS,
            GoProSettings.FRAMERATE,
            GoProSettings.LED,
            GoProSettings.HYPERSMOOTH
        ];
        getApp().gopro.queryValues(GoProDecoder.REGISTER_AVAILABLE, []b.addAll(settingsCamera));
        BleAPI.device.processRequests();

        var settingsIface = [
            GoProSettings.RESOLUTION,
            GoProSettings.RATIO,
            GoProSettings.LENS,
            GoProSettings.FRAMERATE,
            GoProSettings.LED,
            GoProSettings.HYPERSMOOTH
        ];
        var indexes = [0, 2, 4, 0, 0, 3];

        for (var i=0; i<settingsIface.size(); i+=1) {
            var menu = initMenu(settingsIface[i]);
            menu[1].onSelect(menu[0].debugItems[indexes[i]]);
            BleAPI.device.processRequests();
        }
        
        var expectedValues = [100, 9, 8, 0, 4];
        var gopro = getApp().gopro;
        var result = true;

        for (var i=0; i<settingsCamera.size(); i+=1) {
            if (gopro.getSetting(settingsCamera[i]) != expectedValues[i]) {
                logger.error("Unexpected setting for id: " + settingsCamera[i] +
                    ", expected: " + expectedValues[i] +
                    ", got: " + gopro.getSetting(settingsCamera[i])
                );
                result = false;
            }
        }

        return result;
    }
}
