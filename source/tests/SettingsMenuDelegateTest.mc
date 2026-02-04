import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;

using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;
using InterfaceComponentsManager as ICM;

(:test)
module SettingsMenuDelegateTest {

    (:test)
    function testInit(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initSink();
        TestInit.initConnection();

        var device = BleAPI.device as TestInit.SinkGoProDevice;
        device.requests = [];

        var menu = new CustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, null);
        var delegate = new SettingsMenuDelegate(menu, SettingsMenuDelegate.CAMERA, []);
        var expected = [
            GPM.UUID_QUERY_CHAR,
            [4, CameraDelegate.REGISTER_AVAILABLE, GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE]b
        ];

        if (!TestInit.haveSameData(device.requests[0], expected)) {
            logger.error("Invalid request, expected: " + expected + ", got: " + device.requests[0]);
        }

        device.requests = [];
        delegate.onBack();
        expected[1][1] = CameraDelegate.UNREGISTER_AVAILABLE;

        
        if (!TestInit.haveSameData(device.requests[0], expected)) {
            logger.error("Invalid request, expected: " + expected + ", got: " + device.requests[0]);
        }

        return true;
    }


    (:test)
    function testSelectPreset(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();
        Application.Storage.clearValues();

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;

        var menu = new TestInit.DebugCustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, null);
        var delegate = new SettingsMenuDelegate(menu, SettingsMenuDelegate.MAIN, []);

        viewController.push(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
        delegate.onSelect(menu.debugItems[1]);

        var ids = [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE, GoProSettings.FLICKER];
        var expected = [4, GoProSettings.WIDE, 6, GoProSettings.HZ50];
        var result = true;

        // Check that preset was sent to camera
        var camera = getApp().gopro;
        for (var i=0; i<ids.size(); i+=1) {
            if (camera.getSetting(ids[i]) != expected[i]) {
                logger.error("Preset setting with id: " + ids[i] + " should be: " + expected[i] + ", is: " + camera.getSetting(ids[i]));
                result = false;
            }
        }

        delegate = viewController.getCurrentDelegate();
        if (!(delegate instanceof RemoteDelegate)) {
            logger.error("Current delegate should a remote delegate after applying a preset");
            result = false;
        }

        return result;
    }


    (:test)
    function testSelectManual(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();

        // test selecting manual edit
        var viewController = new ViewDebugController();
        getApp().viewController = viewController;

        var menu = new TestInit.DebugCustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, null);
        var delegate = new SettingsMenuDelegate(menu, SettingsMenuDelegate.MAIN, []);

        viewController.push(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
        delegate.onSelect(menu.debugItems[3]);
        
        delegate = viewController.getCurrentDelegate();
        if (!(delegate instanceof SettingsMenuDelegate) or delegate.getId() != SettingsMenuDelegate.CAMERA) {
            logger.error("Current delegate should be a CAMERA SettingsMenu");
            return false;
        }

        // test selecting settings options in manual editing menu
        viewController = new ViewDebugController();
        getApp().viewController = viewController;

        menu = new TestInit.DebugCustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, null);
        delegate = new SettingsMenuDelegate(menu, SettingsMenuDelegate.CAMERA, []);
        viewController.push(menu, delegate, WatchUi.SLIDE_IMMEDIATE);

        var ids = [GoProSettings.RESOLUTION, GoProSettings.RATIO, GoProSettings.LENS, GoProSettings.FRAMERATE];

        for (var i=0; i<ids.size(); i+=1) {
            delegate.onSelect(menu.debugItems[i]);
            delegate = viewController.getCurrentDelegate();

            if (!(delegate instanceof SettingPickerDelegate)) {
                logger.error("Current delegate should be a SettingPickerDelegate");
                return false;
            }
            if (delegate.getId() != ids[i]) {
                logger.error("SettingPickerDelegate has id: " + delegate.getId() + "expected: " + ids[i]);
                return false;
            }

            delegate.onBack();
            delegate = viewController.getCurrentDelegate();
            
            if (!(delegate instanceof SettingsMenuDelegate) or delegate.getId() != SettingsMenuDelegate.CAMERA) {
                logger.error("Current delegate should be back to a CAMERA SettingsMenu");
                return false;
            }
        }

        delegate.onBack();
        delegate = viewController.getCurrentDelegate();

        if (!(delegate instanceof SettingsMenuDelegate) or delegate.getId() != SettingsMenuDelegate.MAIN) {
            logger.error("Current delegate should be back to a MAIN SettingsMenu");
            return false;
        }

        return true;
    }

    (:test)
    function testSelectSaveAs(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();
        Application.Storage.clearValues();

        // test selecting preset saving
        var viewController = new ViewDebugController();
        getApp().viewController = viewController;

        var menu = new TestInit.DebugCustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, null);
        var items = [];
        var delegate = new SettingsMenuDelegate(menu, SettingsMenuDelegate.MAIN, items);

        viewController.push(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
        delegate.onSelect(menu.debugItems[4]);
        
        delegate = viewController.getCurrentDelegate();
        if (!(delegate instanceof SettingsMenuDelegate) or delegate.getId() != SettingsMenuDelegate.PRESET) {
            logger.error("Current delegate should be a PRESET SettingsMenu");
            return false;
        }

        // test selecting a preset in the saving settings as preset menu
        viewController = new ViewDebugController();
        getApp().viewController = viewController;

        menu = new TestInit.DebugCustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, null);
        delegate = new SettingsMenuDelegate(menu, SettingsMenuDelegate.PRESET, items);
        viewController.push(menu, delegate, WatchUi.SLIDE_IMMEDIATE);

        delegate.onSelect(menu.debugItems[2]);
        delegate = viewController.getCurrentDelegate();

        var preset = new GoProPreset(2 as Char);
        var ids = [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE, GoProSettings.FLICKER];
        var result = true;
        var gopro = getApp().gopro;

        for (var i=0; i<ids.size(); i+=1) {
            if (preset.getSetting(ids[i]) != gopro.getSetting(ids[i])) {
                logger.error(
                    "Preset settings (" + preset.getSetting(ids[i]) +
                    ") doesn't match gopro's (" + gopro.getSetting(ids[i]) +
                    ") for id: " + ids[i]
                );
                result = false;
            }
        }
        
        if (!(delegate instanceof RemoteDelegate)) {
            logger.error("Current delegate should a remote delegate after saving a preset");
            result = false;
        }

        return result;
    }
}