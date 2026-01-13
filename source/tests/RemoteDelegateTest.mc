import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Test;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;


(:test)
module RemoteDelegateTest {

    (:test)
    function testSettings(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        camera.sendCommand(GoProCamera.SHUTTER);
        delegate.onMenu();

        if (viewController.getCurrentDelegate() != delegate) {
            logger.error("Camera is recording, settings shouldn't be available");
            return false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        delegate.onMenu();
        
        if (!(viewController.getCurrentDelegate() instanceof SettingsMenuDelegate)) {
            logger.error("Current view should be settings menu");
            return false;
        }

        return true;
    }
    
    (:test)
    function testTogglables(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        camera.sendCommand(GoProCamera.SHUTTER);
        delegate.onPreviousPage();

        if (viewController.getCurrentDelegate() != delegate) {
            logger.error("Camera is recording, togglables shouldn't be available");
            return false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        delegate.onPreviousPage();
        
        if (!(viewController.getCurrentDelegate() instanceof TogglablesDelegate)) {
            logger.error("Current view should be settings menu");
            return false;
        }

        return true;
    }
    
    (:test)
    function testShutter(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        var keyEvent = new TestInit.MockKeyEvent(WatchUi.KEY_ENTER, WatchUi.PRESS_TYPE_ACTION);
        delegate.onKeyPressed(keyEvent);

        if (!camera.isRecording()) {
            logger.error("Camera should be recording");
            return false;
        }
        
        delegate.onKeyPressed(keyEvent);
        
        if (camera.isRecording()) {
            logger.error("Camera should not be recording");
            return false;
        }

        return true;
    }
    
    (:test)
    function testHilight(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initSink();
        TestInit.initConnection();
        
        var device = BleAPI.device as TestInit.SinkGoProDevice;

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        BleAPI.callbacks.onCharacteristicChanged(
            BleAPI.device.gpQueryResponseChar as Ble.Characteristic,
            [5, CameraDelegate.NOTIF_STATUS, 0, 10, 1, 1]b
        );

        device.requests = [];
        delegate.onPreviousPage();

        if (!TestInit.haveSameData(device.requests[0], [GPM.UUID_COMMAND_CHAR, [1, GoProCamera.HILIGHT]b])) {
            logger.error("Wrong hilight command");
            return false;
        }
        
        return true;
    }

    (:test)
    function testBack(logger as Test.Logger) as Boolean {
        // TODO
        return false;
    }
}