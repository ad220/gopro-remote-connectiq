import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Test;
import Toybox.Graphics;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;


(:test)
module RemoteDelegateTest {

    (:test)
    function testSettings(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(FakeGoProSpecs.getSpecsM1Pro());
        TestInit.initConnection(GoProCamera.GP_MISSION1PRO);
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController(getApp().viewController);
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();
        delegate.onNextPage();

        if (viewController.getCurrentDelegate() != delegate) {
            logger.error("Camera is recording, settings shouldn't be available");
            return false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();
        delegate.onNextPage();
        
        var tmpDlgt = viewController.getCurrentDelegate();
        if (!(tmpDlgt instanceof SettingsMenuDelegate)) {
            logger.error("Current view should be settings menu");
            return false;
        }
        tmpDlgt.onBack();

        delegate = viewController.getCurrentDelegate();
        if (!(delegate instanceof RemoteDelegate)) {
            logger.error("Current view should be remote delegate");
            return false;
        }

        camera.sendCommand(GoProCamera.LOAD_PGRP);
        BleAPI.device.processRequests();
        delegate.onNextPage();

        if (viewController.getCurrentDelegate() != delegate) {
            logger.error("Less than 2 available photo lens, should not open picker menu");
            return false;
        }

        BleAPI.device.specs.availablePhotoLens.addAll([GoProSettings.MAXSV_FULL]b);
        camera.queryValues(GoProDecoder.GET_AVAILABLE, [GoProSettings.PHOTO_LENS]b);
        BleAPI.device.processRequests();
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
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController(getApp().viewController);
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();
        delegate.onMenu();

        if (viewController.getCurrentDelegate() != delegate) {
            logger.error("Camera is recording, settings shouldn't be available");
            return false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();
        delegate.onMenu();
        
        var tmpDlgt = viewController.getCurrentDelegate();
        if (!(tmpDlgt instanceof RemoteMenuDelegate)) {
            logger.error("Current view should be settings menu");
            return false;
        }

        return true;
    }
    
    (:test)
    function testAdvancedSettingsMenu(logger as Test.Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);

        var device = BleAPI.device as FakeGoProDevice;
        var viewController = new ViewDebugController(getApp().viewController);
        getApp().viewController = viewController;

        // RemoteMenuDelegate needs a real Menu2, its items can't be inspected
        var menu = new WatchUi.Menu2(null);
        var delegate = new RemoteMenuDelegate(menu);
        viewController.push(menu, delegate, WatchUi.SLIDE_IMMEDIATE);

        var icon = new WatchUi.Bitmap({:rezId => Rez.Drawables.CaptureMode});

        delegate.onSelect(new WatchUi.IconMenuItem(Rez.Strings.Protune, null, :protune, icon, null));
        BleAPI.device.processRequests();

        if (!(viewController.getCurrentDelegate() instanceof ProtuneMenuDelegate)) {
            logger.error("Selecting protune should have opened the protune menu");
            result = false;
        }

        device.requests = [];
        delegate.onSelect(new WatchUi.IconMenuItem(Rez.Strings.SwitchMode, null, :switchMode, icon, null));

        if (device.requests.size() != 1) {
            logger.error("Selecting switch mode should queue exactly 1 request, got: " + device.requests.size());
            return false;
        }

        var sent = device.requests[0] as Array;
        var payload = sent[1] as ByteArray;
        if (!TestInit.haveSameData([sent[0]] as Array, [GPM.UUID_COMMAND_CHAR] as Array)
                or payload[1] != GoProCamera.LOAD_PGRP) {
            logger.error("Selecting switch mode should send the LOAD_PGRP command, got: " + payload);
            result = false;
        }

        if (viewController.getCurrentDelegate() == delegate) {
            logger.error("Selecting switch mode should have closed the advanced settings menu");
            result = false;
        }

        return result;
    }


    (:test)
    function testMode360(logger as Test.Logger) as Boolean {
        var result = true;
        var camIds = [GoProCamera.GP_MAX, GoProCamera.GP_MAX2] as Array<Number>;
        var specMethods = [
            new Lang.Method(FakeGoProSpecs, :getSpecsMax),
            new Lang.Method(FakeGoProSpecs, :getSpecsMax2),
        ] as Array<Method() as FakeGoProSpecs.ISpecs>;

        var icon = new WatchUi.Bitmap({:rezId => Rez.Drawables.Mode360});

        for (var k=0; k<camIds.size(); k+=1) {
            TestInit.initDefaults();
            TestInit.initSettings.put(
                GoProSettings.CAM_MODE, GoProSettings.MAXCAM_SINGLE);
            TestInit.initFake(specMethods[k].invoke());
            TestInit.initConnection(camIds[k]);

            var device = BleAPI.device as FakeGoProDevice;
            var camera = getApp().gopro;

            device.processRequests();
            var value = camera.getSetting(GoProSettings.CAM_MODE);

            if (value != GoProSettings.MAXCAM_SINGLE) {
                logger.error("Camera mode should be registered on connect, got: " + value);
                result = false;
                continue;
            }

            var viewController = new ViewDebugController(getApp().viewController);
            getApp().viewController = viewController;

            var menu = new WatchUi.Menu2(null);
            var delegate = new RemoteMenuDelegate(menu);
            viewController.push(menu, delegate, WatchUi.SLIDE_IMMEDIATE);

            device.requests = [];
            delegate.onSelect(
                new WatchUi.IconMenuItem(Rez.Strings.Mode360, null, :mode360, icon, null));

            if (device.requests.size() != 1) {
                logger.error("Selecting 360 mode should queue exactly 1 request, got: "
                    + device.requests.size());
                result = false;
                continue;
            }

            // MAX answers to the deprecated lens mode id, MAX2 to the camera mode one
            var sentId = camIds[k] < GoProCamera.GP_MAX2
                ? GoProSettings.LENS_MODE : GoProSettings.CAM_MODE;
            var expectedPayload = [3, sentId, 1, GoProSettings.MAXCAM_DOUBLE]b;
            var sent = device.requests[0];
            BleAPI.device.processRequests();

            if (!TestInit.haveSameData(sent as Array, [GPM.UUID_SETTINGS_CHAR, expectedPayload])) {
                logger.error("Wrong 360 mode request, expected: " + expectedPayload
                    + ", got: " + sent[1]);
                result = false;
                continue;
            }

            value = camera.getSetting(GoProSettings.CAM_MODE);
            if (value != GoProSettings.MAXCAM_DOUBLE) {
                logger.error("Camera mode should be 360, got: " + value);
                result = false;
            }
        }

        return result;
    }


    (:test)
    function testTogglables(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController(getApp().viewController);
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();
        delegate.onPreviousPage();

        if (viewController.getCurrentDelegate() != delegate) {
            logger.error("Camera is recording, togglables shouldn't be available");
            return false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();
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
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;

        var viewController = new ViewDebugController(getApp().viewController);
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        var keyEvent = new TestInit.MockKeyEvent(WatchUi.KEY_ENTER, WatchUi.PRESS_TYPE_ACTION);
        delegate.onKeyPressed(keyEvent);
        BleAPI.device.processRequests();

        if (!camera.isRecording()) {
            logger.error("Camera should be recording");
            return false;
        }
        
        delegate.onKeyPressed(keyEvent);
        BleAPI.device.processRequests();
        
        if (camera.isRecording()) {
            logger.error("Camera should not be recording");
            return false;
        }

        return true;
    }
    
    (:test)
    function testHilight(logger as Test.Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var device = BleAPI.device as FakeGoProDevice;

        var viewController = new ViewDebugController(getApp().viewController);
        getApp().viewController = viewController;
        
        var delegate = new RemoteDelegate();
        viewController.push(new RemoteView(), delegate, WatchUi.SLIDE_IMMEDIATE);
        
        BleAPI.delegate.onCharacteristicChanged(
            BleAPI.device.gpQueryResponseChar as Ble.Characteristic,
            [5, GoProDecoder.NOTIF_STATUS, 0, 10, 1, 1]b
        );

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
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var device = BleAPI.device as FakeGoProDevice;

        var viewController = new ViewDebugController(getApp().viewController);
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