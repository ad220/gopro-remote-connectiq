import Toybox.Lang;
import Toybox.Test;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;

(:test)
module GoProCameraTest {
    
    /* 
        TODO(test):

        [ ] test command
            * sleep
            * keep alive (use sink, without timer loop)
        [ ] test unknown status ids (useful ?)
        [ ] test init / deinit for intended behavior, blocked msg, camera crash, request fail  
        [ ] test unregister settings, status, available (with sink, useful ?)
    */

    const testDeviceIds = [
        GoProCamera.GP_HERO5S,
        GoProCamera.GP_HERO11M,
        // GoProCamera.GP_MAX2,
        GoProCamera.GP_MISSION1PRO,
    ];

    const testDeviceSpecs = [
        new Lang.Method(FakeGoProSpecs, :getSpecsH5S),
        new Lang.Method(FakeGoProSpecs, :getSpecsH11M),
        // new Lang.Method(FakeGoProSpecs, :getSpecsMAX2),
        new Lang.Method(FakeGoProSpecs, :getSpecsM1Pro),
    ] as Array<Method() as FakeGoProSpecs.ISpecs>;

    const testDeviceNames = [
        "HERO5 Session",
        "HERO11 Mini",
        // "MAX2",
        "Mission1 Pro",
    ];

    function logDeviceError(logger as Logger, message as String, k as Number) as Void {
        logger.error(message);
        logger.error("with gopro: " + testDeviceNames[k]);
    }

    function expectedSettingRequest(id as Number, value as Number, k as Number) as ByteArray {
        k = testDeviceIds[k];
        if      (k == GoProCamera.GP_MISSION1PRO or k == GoProCamera.GP_MISSION1) {
            return [5, 0xFF, 0, id, 1, value]b;
        }
        else if (k < GoProCamera.GP_MAX) {
            if      (id == GoProSettings.LENS)          { id = GoProSettings.FOV; }
            else if (id == GoProSettings.FLICKER)       { id = GoProSettings.FORMAT; }
            else if (id == GoProSettings.HYPERSMOOTH)   { id = GoProSettings.EIS; }
        }
        return [3, id, 1, value]b;
    }


    (:test)
    function testModelIds(logger as Logger) as Boolean {
        return GoProCamera.modelIdTable.size() == GoProCamera.modelStringTable.size(); 
    }


    (:test)
    function testSendSetting(logger as Logger) as Boolean {

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        var device = TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;
        
        var ids = [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE, GoProSettings.HYPERSMOOTH, GoProSettings.FLICKER];
        var values = [1, 3, 5, 1, GoProSettings.PAL ]; // 4K 16:9, SuperView, 60fps, Low, 50Hz

        device.requests = [];

        for (var i=0; i<ids.size(); i+=1) {
            camera.sendSetting(ids[i], values[i]);
        }

        for (var i=0; i<ids.size(); i+=1) {
            var expectedRequest = [GPM.UUID_SETTINGS_CHAR, expectedSettingRequest(ids[i], values[i], k)];
            if (
                !device.requests[i][0].equals(expectedRequest[0]) or
                !device.requests[i][1].equals(expectedRequest[1])
            ) {
                logDeviceError(logger, "Wrong request sent, expected: " + expectedRequest + ", got: " + device.requests[i], k);
                return false;
            }
        }

        for (var i=0; i<ids.size(); i+=1) {
            var camSetting = camera.getSetting(ids[i]);
            if (camSetting != values[i]) {
                logDeviceError(logger, "Setting was not stored correctly, id: " + ids[i] \
                                        + ", expected: " + values[i] \
                                        + ", got: " + camSetting, k);
                return false;
            }
        }

        } // end of testDevice loop
        return true;
    }

    
    (:test)
    function testSendPreset(logger as Logger) as Boolean {
        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop
        
        TestInit.initDefaults();
        var device = TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;

        device.requests = [];

        var settings = {
            GoProSettings.FLICKER       => GoProSettings.HZ50,
            GoProSettings.RESOLUTION    => 9,
            GoProSettings.LENS          => GoProSettings.LINEAR,
            GoProSettings.FRAMERATE     => 9
        };
        
        var preset = new TestInit.MockPreset(settings as Dictionary<GoProSettings.SettingId, Number>);
        camera.sendPreset(preset);

        var ids = [GoProSettings.FLICKER, GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE];
        var values = [GoProSettings.HZ50, 9, GoProSettings.LINEAR, 9];

        if (device.requests.size() != ids.size()) {
            logDeviceError(logger, "Wrong number of requests, expected 4, got: " + device.requests.size(), k);
            return false;
        }

        for (var i=0; i<ids.size(); i+=1) {
            var expectedRequest = [GPM.UUID_SETTINGS_CHAR, expectedSettingRequest(ids[i], values[i], k)];
            if (
                !device.requests[i][0].equals(expectedRequest[0]) or
                !device.requests[i][1].equals(expectedRequest[1])
            ) {
                logDeviceError(logger, "Wrong request sent, expected: " + expectedRequest + ", got: " + device.requests[i], k);
                return false;
            }
        }

        for (var i=0; i<ids.size(); i+=1) {
            if (camera.getSetting(ids[i]) != values[i]) {
                logDeviceError(logger, "Setting was not stored correctly", k);
                return false;
            }
        }

        } // end of testDevice loop

        return true;
    }

        
    (:test)
    function testNotifSettings(logger as Logger) as Boolean {
        var ret = true;

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        var device = TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;
        
        var ids = [
            GoProSettings.RESOLUTION,
            GoProSettings.LENS,
            GoProSettings.FLICKER,
            GoProSettings.FRAMERATE,
            GoProSettings.HYPERSMOOTH,
        ];
        var values = [
            9,
            GoProSettings.SUPERVIEW,
            GoProSettings.HZ50,
            6,
            GoProSettings.HS_OFF,
        ]; // 1080p 50fps
        
        for (var i=0; i<ids.size(); i+=1) {
            device.setSetting(ids[i], values[i]);
        }

        device.processRequests();

        for (var i=0; i<ids.size(); i+=1) {
            var camSetting = camera.getSetting(ids[i]);
            if (camSetting != values[i]) {
                logDeviceError(logger, "Setting was not updated correctly id: " + ids[i] \
                                        + ", expected: " + values[i] \
                                        + ", got: " + camSetting, k);
                ret = false;
            }
        }

        } // end of testDevice loop

        return ret;
    }
    

    (:test)
    function testRequestStatus(logger as Logger) as Boolean {
        var result = true;

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        var device = TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;

        camera.queryValues(GoProDecoder.GET_STATUS, [GoProCamera.BATTERY, GoProCamera.SD_REMAINING]b);

        device.processRequests();
        
        var battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery != 42) {
            logDeviceError(logger, "Wrong battery percentage, expected 42, got: " + battery, k);
            result = false;
        }

        var sd = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sd != 6942) {
            logDeviceError(logger, "Wrong battery percentage, expected 6942, got: " + sd, k);
            result = false;
        }

        } // end of testDevice loop

        return result;
    }


    (:test)
    function testNotifStatus(logger as Logger) as Boolean {
        var result = true;

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        var device = TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;

        camera.queryValues(GoProDecoder.REGISTER_STATUS, [
            GoProCamera.BATTERY,
            GoProCamera.SD_REMAINING
        ]b);

        device.processRequests();
        
        var battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery != 42) {
            logDeviceError(logger, "Wrong battery percentage, expected 42, got: " + battery, k);
            result = false;
        }

        var sd = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sd != 6942) {
            logDeviceError(logger, "Wrong battery percentage, expected 6942, got: " + sd, k);
            result = false;
        }
        
        device.setStatus(GoProCamera.BATTERY, 90);
        device.setStatus(GoProCamera.SD_REMAINING, 7200);

        device.processRequests();
        
        battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery != 90) {
            logDeviceError(logger, "Wrong battery percentage, expected 90, got: " + battery, k);
            result = false;
        }

        sd = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sd != 7200) {
            logDeviceError(logger, "Wrong battery percentage, expected 7200, got: " + sd, k);
            result = false;
        }

        } // end of testDevice loop

        return result;
    }

    
    (:test)
    function testRequestAvailable(logger as Logger) as Boolean {
        var result = true;

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        var device = TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;
                
        camera.queryValues(
            GoProDecoder.GET_AVAILABLE,
            [
                GoProSettings.RESOLUTION,
                GoProSettings.LENS,
                GoProSettings.FRAMERATE,
                GoProSettings.HYPERSMOOTH
            ]b
        );

        device.processRequests();

        var expectedFramerates = [
            [8, 9],
            [8, 1, 10, 9, 5, 2, 6],
            [0, 13, 1, 2, 5, 6, 8, 9, 10]
        ];
        var expectedRatios = [
            [1],
            [28, 18, 1],
            [109, 112, 1],
        ];
        var expectedHypersmooth = [[
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW
        ],  [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
            GoProSettings.HS_BOOST,
            GoProSettings.HS_AUTO_BOOST,
        ], [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
            GoProSettings.HS_AUTO_BOOST,
        ]];
        
        var availableFramerates = camera.getAvailableSettings(GoProSettings.FRAMERATE);
        if (!TestInit.haveSameData(availableFramerates as Array, expectedFramerates[k] as Array)) {
            logDeviceError(logger, "Wrong available framerates, expected: " + expectedFramerates[k] + ", got: " + availableFramerates, k);
            result = false;
        }

        var availableRatios = camera.getAvailableSettings(GoProSettings.RATIO);
        Helper.customSort(availableRatios as Array, new RatioComparator());
        if (!TestInit.haveSameData(availableRatios as Array, expectedRatios[k] as Array)) {
            logDeviceError(logger, "Wrong available ratios, expected: " + expectedRatios[k] + ", got: " + availableRatios, k);
            result = false;
        }

        var availableHypersmooth = camera.getAvailableSettings(GoProSettings.HYPERSMOOTH);
        if (!TestInit.haveSameData(availableHypersmooth as Array, expectedHypersmooth[k] as Array)) {
            logDeviceError(logger, "Wrong available hypersmooth, expected: " + expectedHypersmooth[k] + ", got: " + availableHypersmooth, k);
            result = false;
        }

        } // end of testDevice loop
        

        return result;
    }


    (:test)
    function testNotifAvailable(logger as Logger) as Boolean {
        var result = true;

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        var device = TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;
                
        camera.queryValues(
            GoProDecoder.REGISTER_AVAILABLE,
            [
                GoProSettings.RESOLUTION,
                GoProSettings.LENS,
                GoProSettings.FRAMERATE,
                GoProSettings.HYPERSMOOTH
            ]b
        );

        device.processRequests();

        device.setSetting(GoProSettings.RESOLUTION, 9);
        device.setSetting(GoProSettings.LENS, GoProSettings.LINEAR);
        device.setSetting(GoProSettings.FLICKER, GoProSettings.HZ60);
        device.setSetting(GoProSettings.FRAMERATE, 5);

        device.processRequests();

        var expectedFramerates = [
            [5, 6, 8, 9, 10],
            [0, 1, 2, 5, 6, 8, 9, 10, 13],
            [18, 15, 0, 13, 1, 2, 5, 6, 8, 9, 10],
        ];
        var expectedRatios = [
            [8, 9],
            [9],
            [110, 9],
        ];
        
        var availableFramerates = camera.getAvailableSettings(GoProSettings.FRAMERATE);
        if (!TestInit.haveSameData(availableFramerates as Array, expectedFramerates[k] as Array)) {
            logDeviceError(logger, "Wrong available framerates, expected: " + expectedFramerates[k] + ", got: " + availableFramerates, k);
            result = false;
        }

        var availableRatios = camera.getAvailableSettings(GoProSettings.RATIO);
        Helper.customSort(availableRatios as Array, new RatioComparator());
        if (!TestInit.haveSameData(availableRatios as Array, expectedRatios[k] as Array)) {
            logDeviceError(logger, "Wrong available ratios, expected: " + expectedRatios[k] + ", got: " + availableRatios, k);
            result = false;
        }

        } // end of testDevice loop

        return result;
    }

    
    (:test)
    function testUnexpectedAvailable(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();

        var device = new FakeGoProDevice(
            TestInit.initSettings,
            TestInit.initStatuses,
            new FakeGoProSpecs.SpecsUnknown()
        );
        TestInit.setDevice(device);

        TestInit.initConnection(GoProCamera.GP_HERO11M);

        var camera = getApp().gopro;
                
        camera.queryValues(
            GoProDecoder.REGISTER_AVAILABLE,
            [
                GoProSettings.RESOLUTION,
                GoProSettings.LENS,
                GoProSettings.FRAMERATE,
                GoProSettings.HYPERSMOOTH
            ]b
        );

        device.processRequests();

        device.setSetting(GoProSettings.RESOLUTION, 42);
        device.setSetting(GoProSettings.LENS, 220);
        device.setSetting(GoProSettings.FRAMERATE, 28);

        device.processRequests();

        var expectedFramerates = [20,21,22,28];
        var expectedRatios = [];
        
        var availableFramerates = camera.getAvailableSettings(GoProSettings.FRAMERATE);
        if (!TestInit.haveSameData(availableFramerates as Array, expectedFramerates as Array)) {
            logger.error("Wrong available framerates, expected: " + expectedFramerates + ", got: " + availableFramerates);
            result = false;
        }

        var availableRatios = camera.getAvailableSettings(GoProSettings.RATIO);
        if (!TestInit.haveSameData(availableRatios as Array, expectedRatios as Array)) {
            logger.error("Wrong available ratios, expected: " + expectedRatios + ", got: " + availableRatios);
            result = false;
        }

        return result;
    }


    (:test)
    function testShutterCommands(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;
        device.processRequests();

        if (camera.isRecording()) {
            logger.error("Default camera is not supposed to be recording after init");
            return false;
        }

        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();

        if (!camera.isRecording()) {
            logger.error("Camera should be recording after shutter command");
            return false;
        }

        if (camera.getStatus(GoProCamera.ENCODING_DURATION) == null) {
            logger.error("Encoding duration should not be null while recording");
            return false;
        }

        if (device.hilightCount != 0) {
            logger.error("Wrong hilight count, expected 0, got " + device.hilightCount);
            result = false;
        }

        camera.sendCommand(GoProCamera.HILIGHT);
        device.processRequests();

        if (device.hilightCount != 1) {
            logger.error("Wrong hilight count, expected 1, got " + device.hilightCount);
            result = false;
        }

        camera.sendCommand(GoProCamera.HILIGHT);
        camera.sendCommand(GoProCamera.HILIGHT);
        device.processRequests();

        if (device.hilightCount != 3) {
            logger.error("Wrong hilight count, expected 3, got " + device.hilightCount);
            result = false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();

        if (camera.isRecording()) {
            logger.error("Camera should not be recording anymore");
            result = false;
        }

        return result;
    }

    (:test)
    function testPhotoMode(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        var device = TestInit.initFake(FakeGoProSpecs.getSpecsM1Pro());
        TestInit.initConnection(GoProCamera.GP_MISSION1PRO);
        
        var camera = getApp().gopro;
        device.processRequests();

        if (camera.getStatus(GoProCamera.PHOTOS_TAKEN) != null) {
            logger.error("Camera photos taken status should still be null");
        }

        camera.sendCommand(GoProCamera.SWITCH_MODE);
        device.processRequests();

        if (camera.getStatus(GoProCamera.CAPTURE_MODE) != GoProCamera.MODE_PHOTO) {
            logger.error("Camera should be in photo mode");
            result = false;
        }

        var photosTaken = camera.getStatus(GoProCamera.PHOTOS_TAKEN);
        if (photosTaken != 1234) {
            logger.error("There should be 1234 photos taken, got: " + photosTaken);
            result = false;
        }

        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();

        if (camera.isRecording()) {
            logger.error("Camera is in photo mode, it shouuld not be recording");
            result = false;
        }

        photosTaken = camera.getStatus(GoProCamera.PHOTOS_TAKEN);
        if (photosTaken != 1235) {
            logger.error("There should be 1235 photos taken, got: " + photosTaken);
            result = false;
        }


        camera.sendCommand(GoProCamera.SHUTTER);
        camera.sendCommand(GoProCamera.SHUTTER);
        camera.sendCommand(GoProCamera.SHUTTER);
        camera.sendCommand(GoProCamera.SHUTTER);
        device.processRequests();

        photosTaken = camera.getStatus(GoProCamera.PHOTOS_TAKEN);
        if (photosTaken != 1239) {
            logger.error("There should be 1239 photos taken, got: " + photosTaken);
            result = false;
        }

        return result;
    }


    (:test)
    function testRecordingCamera(logger as Logger) as Boolean {
        TestInit.initDefaults();
        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;
        
        TestInit.initStatuses.put(GoProCamera.ENCODING, 1);
        TestInit.initStatuses.put(GoProCamera.ENCODING_DURATION, 42);

        device.onSend([GPM.UUID_COMMAND_CHAR, [3, 1, 1, 1]b]);
        device.processRequests();

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
        device.processRequests();

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
        TestInit.initSettings[GoProSettings.PHOTO_LENS] = GoProSettings.WIDE_27MP; 
        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;
        device.processRequests();
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
        var expected = ["4K", "16:9", Rez.Strings._WIDE, "60 fps", "", Rez.Strings.On, "", Rez.Strings.Low];

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

        camera.sendCommand(GoProCamera.SWITCH_MODE);
        device.processRequests();

        label = camera.getLabel(GoProCamera.PHOTO_LENS, null);
        if (!label.equals("27MP Wide")) {
            logger.error("Wrong label, expected: '27MP Wide', got :" + label);
            result = false;
        }

        label = camera.getDescription();
        if (!label.equals("27MP Wide")) {
            logger.error("Wrong description, expected '27MP Wide', got :" + label);
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
        TestInit.initSettings.put(GoProSettings.PHOTO_LENS, 91);

        var device = TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;
        device.processRequests();
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
            GoProSettings.PHOTO_LENS,
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

        camera.sendCommand(GoProCamera.SWITCH_MODE);
        device.processRequests();

        label = camera.getDescription();
        if (!label.equals("")) {
            logger.error("Expected empty placeholder description got :" + label);
            return false;
        }

        return true;
    }
}