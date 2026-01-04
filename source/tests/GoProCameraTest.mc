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
    [ ] check sendPreset
    [ ] check register settings
        * sink --> good request
        * fake --> all settings received, then updated, same for encoding status
    [ ] check requestStatuses
    [-] test command
        * shutter + hilight
            - isRecording
            - duration after a few seconds
            - hilight
            - shutter again
            - isRecording
        * hilight with sink
        * sleep
    [ ] check keep alive (use sink)
    [ ] check disconnect / sleep
    [ ] check available settings match those in specs
    [ ] check settings match those in fake cam
    [ ] test getLabel / getDescription
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

        for (var i=0; i<ids.size(); i+=1) {
            camera.sendSetting(ids[i], values[i]);
        }

        for (var i=0; i<ids.size(); i+=1) {
            var expectedRequest = [3, ids[i], 1, values[i]];
            if (device.requests[i].equals(expectedRequest)) {
                logger.error("Expected request to be sent");
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