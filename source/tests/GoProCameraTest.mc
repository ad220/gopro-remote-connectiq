import Toybox.Lang;
import Toybox.Test;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;

(:test)
module GoProCameraTest {
    
    /* TODO:
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
    [ ] check keep alive (use sink)
    [ ] check disconnect / sleep
    [ ] check available settings match those in specs
    [ ] check settings match those in fake cam
    [ ] test getLabel / getDescription

    [X] test request ~~settings~~ / statuses / available
    [X] test notif settings / statuses / available
    */

    class SinkGoProDevice extends FakeGoProDevice {

        var requests as Array<[GPM.GoProUuid, ByteArray]>;

        function initialize(
            settings as FakeGoProDevice.FakeGoProSettings,
            statuses as FakeGoProDevice.FakeGoProStatuses,
            specs as FakeGoProSpecs.ISpecs
        ) {
            FakeGoProDevice.initialize(settings, statuses, specs);

            self.requests = [];
        }

        function onSend(uuid as GPM.GoProUuid, data as ByteArray) as Void {
            requests.add([uuid, data]);
        }       
    }

    class MockPreset extends GoProPreset {
        function initialize(settings as Dictionary<GoProSettings.SettingId, Char>) {
            GoProPreset.initialize(0 as Char);

            self.settings = settings;
        }
    }

    const defaultSettings = {
        GoProSettings.RESOLUTION        => 1,
        GoProSettings.LENS              => GoProSettings.WIDE,
        GoProSettings.FRAMERATE         => 5,
        GoProSettings.FLICKER           => GoProSettings.HZ60,
        GoProSettings.HYPERSMOOTH       => GoProSettings.HS_HIGH,
        GoProSettings.LED               => GoProSettings.LED_ON
    };

    const defaultStatuses = {
        GoProCamera.ENCODING            => 0,
        GoProCamera.ENCODING_DURATION   => 0,
        GoProCamera.SD_REMAINING        => 6942,
        GoProCamera.BATTERY             => 42
    };

    (:initialized) var initSettings as FakeGoProDevice.FakeGoProSettings;
    (:initialized) var initStatuses as FakeGoProDevice.FakeGoProStatuses;

    (:typecheck(false))
    function initDefaults() as Void {
        var keys = defaultSettings.keys();
        initSettings = {};
        for (var i=0; i<keys.size(); i+=1) {
            initSettings.put(keys[i], defaultSettings.get(keys[i]));
        }

        keys = defaultStatuses.keys();
        initStatuses = {};
        for (var i=0; i<keys.size(); i+=1) {
            initStatuses.put(keys[i], defaultStatuses.get(keys[i]));
        }
    }

    function initFake() as Void {
        BleAPI.device = new FakeGoProDevice(
            initSettings,
            initStatuses,
            new FakeGoProSpecs.SpecsH11Mini()
        );

        new BluetoothDelegate();
    }

    function initSink() as Void {
        BleAPI.device = new SinkGoProDevice(
            initSettings,
            initStatuses,
            new FakeGoProSpecs.SpecsH11Mini()
        );

    }

    function initConnection() as Void {
        var delegate = new BluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0) as Ble.ScanResult);
    }


    (:test)
    function testSendSetting(logger as Logger) as Boolean {
        initDefaults();
        initSink();
        initConnection();

        var device = BleAPI.device as SinkGoProDevice;
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
        initDefaults();
        initSink();
        initConnection();

        var device = BleAPI.device as SinkGoProDevice;
        var camera = getApp().gopro;

        device.requests = [];

        var settings = {
            GoProSettings.FLICKER       => GoProSettings.HZ50,
            GoProSettings.RESOLUTION    => 9,
            GoProSettings.LENS          => GoProSettings.LINEAR,
            GoProSettings.FRAMERATE     => 9
        };
        
        var preset = new MockPreset(settings as Dictionary<GoProSettings.SettingId, Char>);
        camera.sendPreset(preset);

        var ids = [GoProSettings.FLICKER, GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE];
        var values = [GoProSettings.HZ50, 9, GoProSettings.LINEAR, 9];

        if (device.requests.size() != ids.size()) {
            logger.error("Wrong number of requests, expected 4, got: " + device.requests.size());
            System.println(device.requests);
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
        initDefaults();
        initFake();
        initConnection();

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

        return true;
    }
    

    (:test)
    function testRequestStatus(logger as Logger) as Boolean {
        initDefaults();
        initFake();
        initConnection();

        var camera = getApp().gopro;

        camera.requestStatuses([GoProCamera.BATTERY, GoProCamera.SD_REMAINING]b);
        
        var battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery != 42) {
                logger.error("Wrong battery percentage, expected 42, got: " + battery);
        }

        var sd = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sd != 6942) {
                logger.error("Wrong battery percentage, expected 6942, got: " + sd);
        }

        return true;
    }


    (:test)
    function testNotifStatus(logger as Logger) as Boolean {
        initDefaults();
        initFake();
        initConnection();

        var camera = getApp().gopro;

        camera.subscribeChanges(CameraDelegate.REGISTER_STATUS, [
            GoProCamera.BATTERY,
            GoProCamera.SD_REMAINING
        ]b);
        
        var battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery != 42) {
            logger.error("Wrong battery percentage, expected 42, got: " + battery);
        }

        var sd = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sd != 6942) {
            logger.error("Wrong battery percentage, expected 6942, got: " + sd);
        }
        
        BleAPI.device.setStatus(GoProCamera.BATTERY, 90);
        BleAPI.device.setStatus(GoProCamera.SD_REMAINING, 7200);
        
        battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery != 90) {
            logger.error("Wrong battery percentage, expected 90, got: " + battery);
        }

        sd = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sd != 7200) {
            logger.error("Wrong battery percentage, expected 7200, got: " + sd);
        }

        return true;
    }

    
    (:test)
    function testRequestAvailable(logger as Logger) as Boolean {
        initDefaults();
        initFake();
        initConnection();

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

        var expectedFramerates = [1,2,5,6,8,9,10];
        var expectedRatios = [8+7<<16, 4+3<<16, 16+9<<16];
        var expectedHypersmooth = [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
            GoProSettings.HS_BOOST,
            GoProSettings.HS_AUTO_BOOST,
        ];
        
        var availableFramerates = camera.getAvailableSettings(GoProSettings.FRAMERATE);
        if (!availableFramerates.equals(expectedFramerates)) {
            logger.error("Wrong available lenses, expected: " + expectedFramerates + ", got: " + availableFramerates);
        }

        var availableRatios = camera.getAvailableSettings(GoProSettings.RATIO);
        if (!availableRatios.equals(expectedRatios)) {
            logger.error("Wrong available ratios, expected: " + expectedRatios + ", got: " + availableRatios);
        }

        var availableHypersmooth = camera.getAvailableSettings(GoProSettings.HYPERSMOOTH);
        if (!availableHypersmooth.equals(expectedHypersmooth)) {
            logger.error("Wrong available hypersmooth, expected: " + expectedHypersmooth + ", got: " + availableHypersmooth);
        }

        return true;
    }


    (:test)
    function testNotifAvailable(logger as Logger) as Boolean {
        initDefaults();
        initFake();
        initConnection();

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

        var expectedFramerates = [1,2,5,6];
        var expectedRatios = [4+3<<16, 16+9<<16];
        
        var availableFramerates = camera.getAvailableSettings(GoProSettings.FRAMERATE);
        if (!availableFramerates.equals(expectedFramerates)) {
            logger.error("Wrong available lenses, expected: " + expectedFramerates + ", got: " + availableFramerates);
        }

        var availableRatios = camera.getAvailableSettings(GoProSettings.RATIO);
        if (!availableRatios.equals(expectedRatios)) {
            logger.error("Wrong available ratios, expected: " + expectedRatios + ", got: " + availableRatios);
        }

        return true;
    }


    (:test)
    function testShutterCommands(logger as Logger) as Boolean {
        initDefaults();
        initFake();
        initConnection();
        
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

    // test encoding duration 

    (:test)
    function testRecordingCamera(logger as Logger) as Boolean {
        initDefaults();
        initFake();
        initConnection();
        
        var camera = getApp().gopro;
        
        initStatuses.put(GoProCamera.ENCODING, 1);
        initStatuses.put(GoProCamera.ENCODING_DURATION, 42);

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

}