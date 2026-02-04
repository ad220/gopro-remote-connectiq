import Toybox.Lang;
import Toybox.Test;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;

(:test :ble)
module GoProCameraTest {
    
    /* 
        TODOv4:

        [X] check sendSetting
        [X] check sendPreset
        [-] test command
            * shutter + hilight
                - isRecording
                - duration after a few seconds
                - hilight
                - shutter again
                - isRecording
            * sleep
        [ ] check keep alive (use sink, without timer)
        
        [ ] test available with unknown resolutions
        [X] test getLabel / getDescription
        [ ] test unknown status ids (useful ?)

        [X] test request ~~settings~~ / statuses / available
        [X] test notif settings / statuses / available

        [ ] test init / deinit for intended behavior, blocked msg, camera crash,  
    */

    class MockBluetoothDelegate extends BluetoothDelegate {

        function initialize() {
            BluetoothDelegate.initialize();
        }

        function getDevice() as Ble.Device? {
            return self.camera;
        }
        
        function getKeepAliveTimer() as TimerCallback? {
            return self.keepAliveTimer;
        }

        function getQueue() as GattRequestQueue? {
            return self.requestQueue;
        }
    }


    (:test)
    function testConnectionSuccess(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initSink();

        BleAPI.pairedDevices = [];
        
        var result = true;
        var delegate = new MockBluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0) as Ble.ScanResult);

        if (delegate.getDevice() == null) {
            logger.error("Delegate's BLE device is null after connection");
            result = false;
        }
        
        if (delegate.isPairing()) {
            logger.error("Pairing timer should be null after connection");
            result = false;
        }
        
        if (!(delegate.getQueue() instanceof GattRequestQueue)) {
            logger.error("Request queue not properly initialized");
            result = false;
        }

        if (!result) { return result; }
        delegate.disconnect();
        
        if (delegate.getDevice() != null) {
            logger.error("Delegate's BLE device is not null after disconnect");
            result = false;
        }
        
        if (delegate.getQueue() != null) {
            logger.error("Request queue should be null after disconnect");
            result = false;
        }
        
        if (BleAPI.pairedDevices.size() > 0) {
            logger.error("There is still at least one device paired in the API");
            result = false;
        }

        return result;
    }

    
    (:test)
    function testPairingFail(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initSink();

        BleAPI.pairedDevices = [];
        BleAPI.connectionStatus = Ble.CONNECTION_STATE_REJECTED;
        
        var result = true;
        var delegate = new MockBluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0) as Ble.ScanResult);

        // following can't be tested as in a debug run, pairing fail occurs in the call stack of pairDevice()
        // thus BluetoothDelegate.camera is not modified after the pairDevice affectation and never set to null 

        /* 
        if (delegate.getDevice() != null) {
            logger.error("Delegate's BLE device isn't null after failed connection");
            result = false;
        }

        if (BleAPI.pairedDevices.size() > 0) {
            logger.error("There is still at least one device paired in the API");
            result = false;
        }
        */
        
        if (delegate.isPairing()) {
            logger.error("Pairing timer should be null after pairing failed");
            result = false;
        }
        
        if (delegate.getQueue() != null) {
            logger.error("Request queue should be null after pairing failed");
            result = false;
        }

        BleAPI.connectionStatus = Ble.CONNECTION_STATE_CONNECTED;
        return result;
    }


    (:test)
    function testAsyncDisconnect(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initSink();

        BleAPI.pairedDevices = [];
        
        var result = true;
        var delegate = new MockBluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0) as Ble.ScanResult);
        
        BleAPI.callbacks.onConnectedStateChanged(
            delegate.getDevice() as Ble.Device,
            Ble.CONNECTION_STATE_DISCONNECTED
        );

        if (delegate.getDevice() != null) {
            logger.error("Delegate's BLE device is not null after disconnect");
            result = false;
        }
        
        if (delegate.getQueue() != null) {
            logger.error("Request queue should be null after disconnect");
            result = false;
        }
        
        if (BleAPI.pairedDevices.size() > 0) {
            logger.error("There is still at least one device paired in the API");
            result = false;
        }

        return result;
    }


    (:test)
    function testSendSetting(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initSink();
        TestInit.initConnection();

        var device = BleAPI.device as TestInit.SinkGoProDevice;
        var camera = getApp().gopro;
        
        var ids = [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE, GoProSettings.HYPERSMOOTH];
        var values = [1, 3, 5, 1] as Array<Char>; // 4K 16:9, SuperView, 60fps, Low

        device.requests = [];

        for (var i=0; i<ids.size(); i+=1) {
            camera.sendSetting(ids[i], values[i]);
        }

        for (var i=0; i<ids.size(); i+=1) {
            var expectedRequest = [GPM.UUID_SETTINGS_CHAR, [3, ids[i], 1, values[i]]b];
            if (
                !device.requests[i][0].equals(expectedRequest[0]) or
                !device.requests[i][1].equals(expectedRequest[1])
            ) {
                logger.error("Wrong request sent, expected: " + expectedRequest + ", got: " + device.requests[i]);
                return false;
            }
        }

        for (var i=0; i<ids.size(); i+=1) {
            if (camera.getSetting(ids[i]) != values[i]) {
                logger.error("Setting was not stored correctly");
                return false;
            }
        }

        return true;
    }

    
    (:test)
    function testSendPreset(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initSink();
        TestInit.initConnection();

        var device = BleAPI.device as TestInit.SinkGoProDevice;
        var camera = getApp().gopro;

        device.requests = [];

        var settings = {
            GoProSettings.FLICKER       => GoProSettings.HZ50,
            GoProSettings.RESOLUTION    => 9,
            GoProSettings.LENS          => GoProSettings.LINEAR,
            GoProSettings.FRAMERATE     => 9
        };
        
        var preset = new TestInit.MockPreset(settings as Dictionary<GoProSettings.SettingId, Char>);
        camera.sendPreset(preset);

        var ids = [GoProSettings.FLICKER, GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE];
        var values = [GoProSettings.HZ50, 9, GoProSettings.LINEAR, 9];

        if (device.requests.size() != ids.size()) {
            logger.error("Wrong number of requests, expected 4, got: " + device.requests.size());
            return false;
        }

        for (var i=0; i<ids.size(); i+=1) {
            var expectedRequest = [GPM.UUID_SETTINGS_CHAR, [3, ids[i], 1, values[i]]b];
            if (
                !device.requests[i][0].equals(expectedRequest[0]) or
                !device.requests[i][1].equals(expectedRequest[1])
            ) {
                logger.error("Wrong request sent, expected: " + expectedRequest + ", got: " + device.requests[i]);
                return false;
            }
        }

        for (var i=0; i<ids.size(); i+=1) {
            if (camera.getSetting(ids[i]) != values[i]) {
                logger.error("Setting was not stored correctly");
                return false;
            }
        }

        return true;
    }

        
    (:test)
    function testNotifSettings(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();

        var camera = getApp().gopro;
        
        var ids = [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FLICKER, GoProSettings.FRAMERATE];
        var values = [9, GoProSettings.SUPERVIEW, GoProSettings.HZ50, 6]; // 1080p 50fps
        
        for (var i=0; i<ids.size(); i+=1) {
            BleAPI.device.setSetting(ids[i], values[i]);
        }

        for (var i=0; i<ids.size(); i+=1) {
            if (camera.getSetting(ids[i]) != values[i]) {
                logger.error("Setting was not updated correctly");
                return false;
            }
        }

        // TODOv4: test unregister
        return true;
    }
    

    (:test)
    function testRequestStatus(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();

        var camera = getApp().gopro;

        camera.requestStatuses([GoProCamera.BATTERY, GoProCamera.SD_REMAINING]b);
        
        var battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery != 42) {
            logger.error("Wrong battery percentage, expected 42, got: " + battery);
            result = false;
        }

        var sd = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sd != 6942) {
            logger.error("Wrong battery percentage, expected 6942, got: " + sd);
            result = false;
        }

        return result;
    }


    (:test)
    function testNotifStatus(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();

        var camera = getApp().gopro;

        camera.subscribeChanges(CameraDelegate.REGISTER_STATUS, [
            GoProCamera.BATTERY,
            GoProCamera.SD_REMAINING
        ]b);
        
        var battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery != 42) {
            logger.error("Wrong battery percentage, expected 42, got: " + battery);
            result = false;
        }

        var sd = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sd != 6942) {
            logger.error("Wrong battery percentage, expected 6942, got: " + sd);
            result = false;
        }
        
        BleAPI.device.setStatus(GoProCamera.BATTERY, 90);
        BleAPI.device.setStatus(GoProCamera.SD_REMAINING, 7200);
        
        battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery != 90) {
            logger.error("Wrong battery percentage, expected 90, got: " + battery);
            result = false;
        }

        sd = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sd != 7200) {
            logger.error("Wrong battery percentage, expected 7200, got: " + sd);
            result = false;
        }

        // TODOv4: test unregister
        return result;
    }

    
    (:test)
    function testRequestAvailable(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();

        var camera = getApp().gopro;
                
        camera.subscribeChanges(
            CameraDelegate.GET_AVAILABLE,
            [
                GoProSettings.RESOLUTION,
                GoProSettings.LENS,
                GoProSettings.FRAMERATE,
                GoProSettings.HYPERSMOOTH
            ]b
        );

        var expectedFramerates = [8, 1, 10, 9, 5, 2, 6];
        var expectedRatios = [1, 18, 28];
        var expectedHypersmooth = [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
            GoProSettings.HS_BOOST,
            GoProSettings.HS_AUTO_BOOST,
        ];
        
        var availableFramerates = camera.getAvailableSettings(GoProSettings.FRAMERATE);
        if (!TestInit.haveSameData(availableFramerates as Array, expectedFramerates)) {
            logger.error("Wrong available framerates, expected: " + expectedFramerates + ", got: " + availableFramerates);
            result = false;
        }

        var availableRatios = camera.getAvailableSettings(GoProSettings.RATIO);
        if (!TestInit.haveSameData(availableRatios as Array, expectedRatios)) {
            logger.error("Wrong available ratios, expected: " + expectedRatios + ", got: " + availableRatios);
            result = false;
        }

        var availableHypersmooth = camera.getAvailableSettings(GoProSettings.HYPERSMOOTH);
        if (!TestInit.haveSameData(availableHypersmooth as Array, expectedHypersmooth)) {
            logger.error("Wrong available hypersmooth, expected: " + expectedHypersmooth + ", got: " + availableHypersmooth);
            result = false;
        }

        return result;
    }


    (:test)
    function testNotifAvailable(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();

        var camera = getApp().gopro;
                
        camera.subscribeChanges(
            CameraDelegate.REGISTER_AVAILABLE,
            [
                GoProSettings.RESOLUTION,
                GoProSettings.LENS,
                GoProSettings.FRAMERATE,
                GoProSettings.HYPERSMOOTH
            ]b
        );

        BleAPI.device.setSetting(GoProSettings.RESOLUTION, 6);
        BleAPI.device.setSetting(GoProSettings.LENS, GoProSettings.LINEAR);
        BleAPI.device.setSetting(GoProSettings.FLICKER, GoProSettings.HZ60);
        BleAPI.device.setSetting(GoProSettings.FRAMERATE, 5);

        var expectedFramerates = [1, 2, 5, 6];
        var expectedRatios = [4, 6];
        
        var availableFramerates = camera.getAvailableSettings(GoProSettings.FRAMERATE);
        if (!TestInit.haveSameData(availableFramerates as Array, expectedFramerates)) {
            logger.error("Wrong available framerates, expected: " + expectedFramerates + ", got: " + availableFramerates);
            result = false;
        }

        var availableRatios = camera.getAvailableSettings(GoProSettings.RATIO);
        if (!TestInit.haveSameData(availableRatios as Array, expectedRatios)) {
            logger.error("Wrong available ratios, expected: " + expectedRatios + ", got: " + availableRatios);
            result = false;
        }

        // TODOv4: test unregister
        return result;
    }

    
    (:test)
    function testUnexpectedAvailable(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        
        BleAPI.device = new FakeGoProDevice(
            TestInit.initSettings,
            TestInit.initStatuses,
            new FakeGoProSpecs.SpecsUnknown()
        );

        TestInit.initConnection();

        var camera = getApp().gopro;
                
        camera.subscribeChanges(
            CameraDelegate.REGISTER_AVAILABLE,
            [
                GoProSettings.RESOLUTION,
                GoProSettings.LENS,
                GoProSettings.FRAMERATE,
                GoProSettings.HYPERSMOOTH
            ]b
        );

        BleAPI.device.setSetting(GoProSettings.RESOLUTION, 42);
        BleAPI.device.setSetting(GoProSettings.LENS, 220);
        BleAPI.device.setSetting(GoProSettings.FRAMERATE, 28);

        var expectedFramerates = [20,21,22,28];
        var expectedRatios = [];
        
        var availableFramerates = camera.getAvailableSettings(GoProSettings.FRAMERATE);
        if (!TestInit.haveSameData(availableFramerates as Array, expectedFramerates)) {
            logger.error("Wrong available framerates, expected: " + expectedFramerates + ", got: " + availableFramerates);
            result = false;
        }

        var availableRatios = camera.getAvailableSettings(GoProSettings.RATIO);
        if (!TestInit.haveSameData(availableRatios as Array, expectedRatios)) {
            logger.error("Wrong available ratios, expected: " + expectedRatios + ", got: " + availableRatios);
            result = false;
        }

        return result;
    }


    (:test)
    function testShutterCommands(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();
        
        var camera = getApp().gopro;

        if (camera.isRecording()) {
            logger.error("Default camera is not supposed to be recording after init");
            return false;
        }

        camera.sendCommand(GoProCamera.SHUTTER);

        if (!camera.isRecording()) {
            logger.error("Camera should be recording after shutter command");
            return false;
        }

        if (camera.getStatus(GoProCamera.ENCODING_DURATION) == null) {
            logger.error("Encoding duration should not be null while recording");
            return false;
        }

        camera.sendCommand(GoProCamera.HILIGHT);

        if (BleAPI.device.hilightCount != 1) {
            logger.error("Wrong hilight count");
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);

        if (camera.isRecording()) {
            logger.error("Camera should not be recording anymore");
            return false;
        }

        return true;
    }


    (:test)
    function testRecordingCamera(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();
        
        var camera = getApp().gopro;
        
        TestInit.initStatuses.put(GoProCamera.ENCODING, 1);
        TestInit.initStatuses.put(GoProCamera.ENCODING_DURATION, 42);

        BleAPI.device.onSend(GPM.UUID_COMMAND_CHAR, [3, 1, 1, 1]b);

        if (!camera.isRecording()) {
            logger.error("Camera should already be recording, status: " + camera.getStatus(GoProCamera.ENCODING));
            return false;
        }
        
        var recDuration = camera.getStatus(GoProCamera.ENCODING_DURATION);
        if (recDuration != 42) {
            logger.error("Wrong encoding duration, expected 42, got: " + recDuration);
            return false;
        }

        camera.sendCommand(GoProCamera.SHUTTER);

        if (camera.isRecording()) {
            logger.error("Camera should not be recording anymore");
            return false;
        }

        return true;
    }

    
    (:test)
    function testLabelKnown(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        TestInit.initFake();
        TestInit.initConnection();
        
        var camera = getApp().gopro;
        var label;

        var ids = [
            GoProSettings.RESOLUTION,
            GoProSettings.RATIO,
            GoProSettings.LENS,
            GoProSettings.FRAMERATE,
            GoProSettings.GPS,
            GoProSettings.LED,
            GoProSettings.FLICKER,
            GoProSettings.HYPERSMOOTH,
        ];
        var expected = ["4K", "16:9", Rez.Strings._WIDE, "60 fps", "", Rez.Strings.On, "", Rez.Strings.Boost];

        for (var i=0; i<ids.size(); i+=1) {
            label = camera.getLabel(ids[i], null);
            if (!label.equals(expected[i])) {
                logger.error("Wrong label, expected: " + expected[i] + ", got :" + label);
                result = false;
            }
        }

        label = camera.getDescription();
        if (!label.equals("4K@60 16:9")) {
            logger.error("Wrong description, expected '4K@60 16:9', got :" + label);
            result = false;
        }

        return result;
    }

    
    (:test)
    function testLabelUnknown(logger as Logger) as Boolean {
        TestInit.initDefaults();
        
        TestInit.initSettings.put(GoProSettings.RESOLUTION, 0xFF);
        TestInit.initSettings.put(GoProSettings.LENS, 42);
        TestInit.initSettings.put(GoProSettings.FRAMERATE, 220);
        TestInit.initSettings.put(GoProSettings.GPS, 13);
        TestInit.initSettings.put(GoProSettings.LED, 69);
        TestInit.initSettings.put(GoProSettings.FLICKER, 78);
        TestInit.initSettings.put(GoProSettings.HYPERSMOOTH, 26);

        TestInit.initFake();
        TestInit.initConnection();
        
        var camera = getApp().gopro;
        var label;

        var ids = [
            GoProSettings.RESOLUTION,
            GoProSettings.RATIO,
            GoProSettings.LENS,
            GoProSettings.FRAMERATE,
            GoProSettings.GPS,
            GoProSettings.LED,
            GoProSettings.FLICKER,
            GoProSettings.HYPERSMOOTH
        ];

        for (var i=0; i<ids.size(); i+=1) {
            label = camera.getLabel(ids[i], null);
            if (!label.equals("")) {
                logger.error("Wrong label, expected empty string, got :" + label);
                return false;
            }
        }
        
        label = camera.getDescription();
        if (!label.equals(". . .")) {
            logger.error("Expected placeholder description as '. . .' got :" + label);
            return false;
        }

        return true;
    }
}