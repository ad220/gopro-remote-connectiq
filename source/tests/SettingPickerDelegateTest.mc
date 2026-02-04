import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

(:test)
module SettingPickerDelegateTest {

    
    function initMenu(settingId as GoProSettings.SettingId) as [TestInit.DebugCustomMenu, SettingPickerDelegate] {
        var menu = new TestInit.DebugCustomMenu(
            (0.1*ICM.screenH).toNumber()<<1,
            Graphics.COLOR_BLACK,
            {:titleItemHeight => (0.30*ICM.screenH).toNumber()}
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
        TestInit.initFake();
        TestInit.initConnection();

        var settings = [
            GoProSettings.RESOLUTION,
            GoProSettings.RATIO,
            GoProSettings.LENS,
            GoProSettings.FRAMERATE,
            GoProSettings.LED,
            GoProSettings.HYPERSMOOTH
        ];
        getApp().gopro.subscribeChanges(CameraDelegate.GET_AVAILABLE, []b.addAll(settings));

        var expectedLabels = [
            ["5.3K", "4K", "2.7K", "1080p"],
            ["8:7", "4:3", "16:9"],
            ["Wide", "SuperView", "Linear", "Linear + HLvl", "HyperView", "Linear + HLock"],
            ["120 fps", "100 fps", "60 fps", "50 fps", "30 fps", "25 fps", "24 fps"],
            ["Disabled", "Enabled"],
            ["Disabled", "Low", "Boost", "AutoBoost"],
        ];

        for (var i=0; i<settings.size(); i+=1) {
            var menu = initMenu(settings[i]);
            var labels = getLabels(menu[0]);

            if (!TestInit.haveSameData(labels as Array, expectedLabels[i])) {
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
        TestInit.initFake();
        TestInit.initConnection();

        var settings = [
            GoProSettings.RESOLUTION,
            GoProSettings.RATIO,
            GoProSettings.LENS,
            GoProSettings.FRAMERATE,
            GoProSettings.LED,
            GoProSettings.HYPERSMOOTH
        ];
        getApp().gopro.subscribeChanges(CameraDelegate.REGISTER_AVAILABLE, []b.addAll(settings));

        var indexes = [0, 2, 4, 0, 0, 3];

        for (var i=0; i<settings.size(); i+=1) {
            var menu = initMenu(settings[i]);
            menu[1].onSelect(menu[0].debugItems[indexes[i]]);
        }
        
        settings = [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE, GoProSettings.LED, GoProSettings.HYPERSMOOTH];
        var expectedValues = [100, 9, 8, 0, 4];
        var gopro = getApp().gopro;
        var result = true;

        for (var i=0; i<settings.size(); i+=1) {
            if (gopro.getSetting(settings[i]) != expectedValues[i]) {
                logger.error("Unexpected setting for id: " + settings[i] +
                    ", expected: " + expectedValues[i] +
                    ", got: " + gopro.getSetting(settings[i])
                );
                result = false;
            }
        }

        return result;
    }
}
