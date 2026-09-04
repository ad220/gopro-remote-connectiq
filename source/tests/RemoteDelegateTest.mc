import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Test;

using Toybox.BluetoothLowEnergy as Ble;
using GattProfileManager as GPM;


(:test)
module RemoteDelegateTest {

    (:test)
    function testSettings(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();
        delegate.onNextPage();

        if (viewController.getCurrentDelegate() != delegate) {
            logger.error("Camera is recording, settings shouldn't be available");
            return false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();
        delegate.onNextPage();
        
        var tmpDlgt = viewController.getCurrentDelegate();
        if (!(tmpDlgt instanceof SettingsMenuDelegate)) {
            logger.error("Current view should be settings menu");
            return false;
        }
        tmpDlgt.onBack();

        camera.sendCommand(GoProCamera.SWITCH_MODE);
        device.processRequests();
        delegate.onNextPage();

        if (!(viewController.getCurrentDelegate() instanceof SettingPickerDelegate)) {
            logger.error("Current view should be setting picker menu");
            return false;
        }

        return true;
    }


    (:test)
    function testMenu(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();
        delegate.onMenu();

        if (viewController.getCurrentDelegate() != delegate) {
            logger.error("Camera is recording, settings shouldn't be available");
            return false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();
        delegate.onMenu();
        
        var tmpDlgt = viewController.getCurrentDelegate();
        if (!(tmpDlgt instanceof RemoteMenuDelegate)) {
            logger.error("Current view should be settings menu");
            return false;
        }

        return true;
    }
    
    (:test)
    function testTogglables(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();
        delegate.onPreviousPage();

        if (viewController.getCurrentDelegate() != delegate) {
            logger.error("Camera is recording, togglables shouldn't be available");
            return false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();
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
        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        var keyEvent = new TestInit.MockKeyEvent(WatchUi.KEY_ENTER, WatchUi.PRESS_TYPE_ACTION);
        delegate.onKeyPressed(keyEvent);
        device.processRequests();

        if (!camera.isRecording()) {
            logger.error("Camera should be recording");
            return false;
        }
        
        delegate.onKeyPressed(keyEvent);
        device.processRequests();
        
        if (camera.isRecording()) {
            logger.error("Camera should not be recording");
            return false;
        }

        return true;
    }
    
    (:test)
    function testHilight(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        device.iface.sendMessage(GPM.UUID_QUERY_RESPONSE_CHAR, [5, GoProDecoder.NOTIF_STATUS, 0, 10, 1, 1]b);

        device.requests = [];
        delegate.onPreviousPage();

        if (!TestInit.haveSameData(device.requests[0] as Array, [GPM.UUID_COMMAND_CHAR, [1, GoProCamera.HILIGHT]b])) {
            logger.error("Wrong hilight command");
            return false;
        }
        
        return true;
    }

    (:test)
    function testBack(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);

        device.requests = [];
        delegate.onBack();

        if (!TestInit.haveSameData(device.requests[0] as Array, [GPM.UUID_COMMAND_CHAR, [1, GoProCamera.SLEEP]b])) {
            logger.error("Wrong sleep command");
            return false;
        }
        
        return true;
    }
}