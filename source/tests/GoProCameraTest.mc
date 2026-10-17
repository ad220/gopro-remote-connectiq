import Toybox.Lang;
import Toybox.Test;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using GattProfileManager as GPM;

(:test :ble)
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

    class UnpairOrderDelegate extends MockBluetoothDelegate {

        var unpairSeenWhileConnected as Boolean = false;

        function initialize() {
            MockBluetoothDelegate.initialize();
        }

        function onConnectedStateChanged(device as Ble.Device, state as Ble.ConnectionState) as Void {
            if (state == Ble.CONNECTION_STATE_DISCONNECTED) {
                // Records whether the link was still up when the
                // unpair callback fired. With the correct order
                // (unpair before CameraDelegate.disconnect), the
                // delegate is still connected here; with the reversed
                // order it is already torn down.
                unpairSeenWhileConnected = isConnected();
            }
            BluetoothDelegate.onConnectedStateChanged(device, state);
        }
    }

    const expectedPairingFinish = [0x0C, 0x03, 0x01, 0x08, 0x00, 0x12, 0x06, 0x67, 0x61, 0x72, 0x6D, 0x69, 0x6E]b;

    (:test)
    function testModelIds(logger as Logger) as Boolean {
        return GoProCamera.modelIdTable.size() == GoProCamera.modelStringTable.size(); 
    }


    (:test)
    function testConnectionSuccess(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);

        BleAPI.pairedDevices = [];
        
        var result = true;
        var delegate = new MockBluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0, null, GoProCamera.GP_HERO11M) as Ble.ScanResult);

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
    function testDisconnect(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);

        BleAPI.pairedDevices = [];

        var delegate = new UnpairOrderDelegate();
        delegate.connect(new BleAPI.MockScanResult(0, null, GoProCamera.GP_HERO11M) as Ble.ScanResult);

        var device = delegate.getDevice();
        if (device == null) {
            logger.error("Delegate's BLE device is null after connection");
            return false;
        }

        delegate.disconnect();

        var result = true;

        if (device.isConnected()) {
            logger.error("BLE device is still connected after disconnect");
            result = false;
        }

        if (BleAPI.pairedDevices.indexOf(device) != -1) {
            logger.error("BLE device was not unpaired after disconnect");
            result = false;
        }

        if (delegate.getDevice() != null) {
            logger.error("Delegate's BLE device is not null after disconnect");
            result = false;
        }

        if (delegate.getQueue() != null) {
            logger.error("Request queue should be null after disconnect");
            result = false;
        }

        // Regression check for the glance ghost keep-alive: unpairing must
        // happen before CameraDelegate.disconnect(), because the latter
        // triggers System.exit when launched from the glance, so anything
        // placed after it (e.g. unpairDevice) never runs.
        if (!delegate.unpairSeenWhileConnected) {
            logger.error("Device was unpaired after teardown instead of before it");
            result = false;
        }

        return result;
    }


    (:test)
    function testPairingFail(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);

        BleAPI.pairedDevices = [];
        BleAPI.connectionStatus = Ble.CONNECTION_STATE_REJECTED;
        
        var result = true;
        var delegate = new MockBluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0, null, GoProCamera.GP_HERO11) as Ble.ScanResult);

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
        TestInit.initFake(null);

        BleAPI.pairedDevices = [];
        
        var result = true;
        var delegate = new MockBluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0, null, GoProCamera.GP_HERO11M) as Ble.ScanResult);
        
        BleAPI.delegate.onConnectedStateChanged(
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
    function testPairingFinish(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);

        BleAPI.pairedDevices = [];

        var delegate = new MockBluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0, null, GoProCamera.GP_HERO11M) as Ble.ScanResult);

        var device = BleAPI.device as FakeGoProDevice;

        if (device.requests.size() > 0 && device.requests[0][0].equals(GPM.UUID_NETWORK_CHAR)) {
            logger.error("Pairing finish should not be sent unless connecting from the scan menu");
            delegate.disconnect();
            return false;
        }

        delegate.disconnect();
        return true;
    }


    (:test)
    function testPairingFinishOnScan(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);

        BleAPI.pairedDevices = [];

        var delegate = new MockBluetoothDelegate();
        delegate.setNeedsSetup(true);
        delegate.connect(new BleAPI.MockScanResult(0, null, GoProCamera.GP_HERO11M) as Ble.ScanResult);

        var device = BleAPI.device as FakeGoProDevice;

        if (device.requests.size() < 1) {
            logger.error("No request queued for pairing finish");
            delegate.disconnect();
            return false;
        }

        var sent = device.requests[0];
        if (!sent[0].equals(GPM.UUID_NETWORK_CHAR) or !sent[1].equals(expectedPairingFinish)) {
            logger.error("Wrong pairing finish request, expected: " \
                            + [GPM.UUID_NETWORK_CHAR, expectedPairingFinish] + ", got: " + sent);
            delegate.disconnect();
            return false;
        }

        delegate.disconnect();
        return true;
    }


    (:test)
    function testPairingFinishNotRepeatedOnReconnect(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);

        BleAPI.pairedDevices = [];

        var delegate = new MockBluetoothDelegate();
        delegate.setNeedsSetup(true);
        delegate.connect(new BleAPI.MockScanResult(0, null, GoProCamera.GP_HERO11M) as Ble.ScanResult);

        var device = BleAPI.device as FakeGoProDevice;
        if (device.requests.size() < 1 or !device.requests[0][0].equals(GPM.UUID_NETWORK_CHAR)) {
            logger.error("Pairing finish was not sent on the scan menu connection");
            delegate.disconnect();
            return false;
        }

        // reconnect from the stored device, without going through the scan menu
        delegate.disconnect();
        BleAPI.pairedDevices = [];
        device.requests = [];
        delegate.connect(new BleAPI.MockScanResult(0, null, GoProCamera.GP_HERO11M) as Ble.ScanResult);

        if (device.requests.size() > 0 && device.requests[0][0].equals(GPM.UUID_NETWORK_CHAR)) {
            logger.error("Pairing finish should not be repeated on reconnect");
            delegate.disconnect();
            return false;
        }

        delegate.disconnect();
        return true;
    }


    (:test)
    function testKeepAlive(logger as Logger) as Boolean {
        var result = true;

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        TestInit.initFake(testDeviceSpecs[k].invoke());

        BleAPI.pairedDevices = [];

        var delegate = new MockBluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0, null, testDeviceIds[k]) as Ble.ScanResult);

        var device = BleAPI.device as FakeGoProDevice;
        var camera = getApp().gopro;
        device.processRequests();

        device.requests = [];

        delegate.keepAlive();

        if (device.requests.size() != 1) {
            logDeviceError(logger, "Keep alive should queue exactly 1 request, got: " + device.requests.size(), k);
            delegate.disconnect();
            return false;
        }

        var expected = [GPM.UUID_SETTINGS_CHAR, expectedSettingRequest(GoProSettings.LED, 0x42, k)];
        var sent = device.requests[0];
        if (!sent[0].equals(expected[0]) or !sent[1].equals(expected[1])) {
            logDeviceError(logger, "Wrong keep alive request, expected: " + expected + ", got: " + sent, k);
            result = false;
        }

        device.processRequests();

        var led = camera.getSetting(GoProSettings.LED);
        if (led != TestInit.defaultSettings[GoProSettings.LED]) {
            logDeviceError(logger, "Keep alive should not change the LED setting, expected: " \
                                    + TestInit.defaultSettings[GoProSettings.LED] as Number + ", got: " + led, k);
            result = false;
        }

        delegate.disconnect();

        } // end of testDevice loop

        return result;
    }


    (:test)
    function testSendSetting(logger as Logger) as Boolean {

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var device = BleAPI.device as FakeGoProDevice;
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
        TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var device = BleAPI.device as FakeGoProDevice;
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
        TestInit.initFake(testDeviceSpecs[k].invoke());
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
            k == 0 ? GoProSettings.LINEAR : GoProSettings.SUPERVIEW,
            k == 1 ? GoProSettings.HZ50 : GoProSettings.PAL,
            6,
            GoProSettings.HS_OFF,
        ]; // 1080p 50fps
        
        for (var i=0; i<ids.size(); i+=1) {
            BleAPI.device.setSetting(ids[i], values[i]);
        }

        BleAPI.device.processRequests();

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
        TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;

        camera.queryValues(GoProDecoder.GET_STATUS, [GoProCamera.BATTERY, GoProCamera.SD_REMAINING]b);

        BleAPI.device.processRequests();
        
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
        TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;

        camera.queryValues(GoProDecoder.REGISTER_STATUS, [
            GoProCamera.BATTERY,
            GoProCamera.SD_REMAINING
        ]b);

        BleAPI.device.processRequests();
        
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
        
        BleAPI.device.setStatus(GoProCamera.BATTERY, 90);
        BleAPI.device.setStatus(GoProCamera.SD_REMAINING, 7200);

        BleAPI.device.processRequests();
        
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
        TestInit.initFake(testDeviceSpecs[k].invoke());
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

        BleAPI.device.processRequests();

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
        TestInit.initFake(testDeviceSpecs[k].invoke());
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

        BleAPI.device.processRequests();

        BleAPI.device.setSetting(GoProSettings.RESOLUTION, 9);
        BleAPI.device.setSetting(GoProSettings.LENS, GoProSettings.LINEAR);
        BleAPI.device.setSetting(GoProSettings.FLICKER, GoProSettings.HZ60);
        BleAPI.device.setSetting(GoProSettings.FRAMERATE, 5);

        BleAPI.device.processRequests();

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
        
        BleAPI.device = new FakeGoProDevice(
            TestInit.initSettings,
            TestInit.initStatuses,
            new FakeGoProSpecs.SpecsUnknown()
        );

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

        BleAPI.device.processRequests();

        BleAPI.device.setSetting(GoProSettings.RESOLUTION, 42);
        BleAPI.device.setSetting(GoProSettings.LENS, 220);
        BleAPI.device.setSetting(GoProSettings.FRAMERATE, 28);

        BleAPI.device.processRequests();

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
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;
        BleAPI.device.processRequests();

        if (camera.isRecording()) {
            logger.error("Default camera is not supposed to be recording after init");
            return false;
        }

        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();

        if (!camera.isRecording()) {
            logger.error("Camera should be recording after shutter command");
            return false;
        }

        if (camera.getStatus(GoProCamera.ENCODING_DURATION) == null) {
            logger.error("Encoding duration should not be null while recording");
            return false;
        }

        if (BleAPI.device.hilightCount != 0) {
            logger.error("Wrong hilight count, expected 0, got " + BleAPI.device.hilightCount);
            result = false;
        }

        camera.sendCommand(GoProCamera.HILIGHT);
        BleAPI.device.processRequests();

        if (BleAPI.device.hilightCount != 1) {
            logger.error("Wrong hilight count, expected 1, got " + BleAPI.device.hilightCount);
            result = false;
        }

        camera.sendCommand(GoProCamera.HILIGHT);
        camera.sendCommand(GoProCamera.HILIGHT);
        BleAPI.device.processRequests();

        if (BleAPI.device.hilightCount != 3) {
            logger.error("Wrong hilight count, expected 3, got " + BleAPI.device.hilightCount);
            result = false;
        }
        
        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();

        if (camera.isRecording()) {
            logger.error("Camera should not be recording anymore");
            result = false;
        }

        return result;
    }

    (:test)
    function testPhotoMode(logger as Logger) as Boolean {
        var result = true;

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        TestInit.initFake(testDeviceSpecs[k].invoke());
        TestInit.initConnection(testDeviceIds[k]);
        
        var camera = getApp().gopro;
        BleAPI.device.processRequests();

        if (camera.getStatus(GoProCamera.PHOTOS_TAKEN) != null) {
            logDeviceError(logger, "Camera photos taken status should still be null", k);
            result = false;
        }

        camera.sendCommand(GoProCamera.LOAD_PGRP);
        BleAPI.device.processRequests();

        if (camera.getStatus(GoProCamera.PRESET_GRP) != GoProCamera.PGRP_PHOTO) {
            logDeviceError(logger, "Camera should be in photo mode", k);
            result = false;
        }

        var photosTaken = camera.getStatus(GoProCamera.PHOTOS_TAKEN);
        if (photosTaken != 1234) {
            logDeviceError(logger, "There should be 1234 photos taken, got: " + photosTaken, k);
            result = false;
        }

        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();

        if (camera.isRecording()) {
            logDeviceError(logger, "Camera is in photo mode, it shouuld not be recording", k);
            result = false;
        }

        photosTaken = camera.getStatus(GoProCamera.PHOTOS_TAKEN);
        if (photosTaken != 1235) {
            logDeviceError(logger, "There should be 1235 photos taken, got: " + photosTaken, k);
            result = false;
        }


        camera.sendCommand(GoProCamera.SHUTTER);
        camera.sendCommand(GoProCamera.SHUTTER);
        camera.sendCommand(GoProCamera.SHUTTER);
        camera.sendCommand(GoProCamera.SHUTTER);
        BleAPI.device.processRequests();

        photosTaken = camera.getStatus(GoProCamera.PHOTOS_TAKEN);
        if (photosTaken != 1239) {
            logDeviceError(logger, "There should be 1239 photos taken, got: " + photosTaken, k);
            result = false;
        }

        } // end of testDevice loop

        return result;
    }


    (:test)
    function testTimelapseMultishotFallback(logger as Logger) as Boolean {
        var result = true;

        for (var k=0; k<testDeviceIds.size(); k+=1)
        { // start of testDevice loop

        TestInit.initDefaults();
        TestInit.initFake(testDeviceSpecs[k].invoke());

        var device = BleAPI.device as FakeGoProDevice;

        if (testDeviceIds[k] < GoProCamera.GP_HERO8) {
            device.statuses.put(GoProCamera.CAPTURE_MODE, GoProCamera.MODE_MULTISHOT);
        } else {
            device.statuses.put(GoProCamera.PRESET_GRP, GoProCamera.PGRP_TIMELAPSE);
        }

        TestInit.initConnection(testDeviceIds[k]);

        var camera = getApp().gopro;
        BleAPI.device.processRequests();

        camera.sendCommand(GoProCamera.LOAD_PGRP);
        BleAPI.device.processRequests();
        var mode = camera.getStatus(GoProCamera.PRESET_GRP) as Number;

        if (mode != GoProCamera.PGRP_VIDEO and mode != GoProCamera.PGRP_PHOTO) {
            logDeviceError(logger, "Switching capture mode should have fallback to video or video: " \
                                    + mode, k);
            result = false;
        }
        
        camera.sendCommand(GoProCamera.LOAD_PGRP);
        BleAPI.device.processRequests();
        var newMode = camera.getStatus(GoProCamera.PRESET_GRP);

        if (newMode != mode ^ 1) {
            logDeviceError(logger, "Switching capture mode again should have switch between photo and video, prev: " \
                                    + mode + ", now: " + newMode, k);
            result = false;
        }

        } // end of testDevice loop

        return result;
    }


    (:test)
    function testRecordingCamera(logger as Logger) as Boolean {
        TestInit.initDefaults();
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;
        
        TestInit.initStatuses.put(GoProCamera.ENCODING, 1);
        TestInit.initStatuses.put(GoProCamera.ENCODING_DURATION, 42);

        BleAPI.device.onSend([GPM.UUID_COMMAND_CHAR, [3, 1, 1, 1]b]);
        BleAPI.device.processRequests();

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
        BleAPI.device.processRequests();

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
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;
        BleAPI.device.processRequests();
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

        camera.sendCommand(GoProCamera.LOAD_PGRP);
        BleAPI.device.processRequests();

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
    function testToggleSetting(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        TestInit.initSettings.put(GoProSettings.PROTUNE, 0);
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);

        var camera = getApp().gopro;
        camera.queryValues(
            GoProDecoder.REGISTER_SETTING,
            [GoProSettings.PROTUNE]b
        );
        camera.queryValues(
            GoProDecoder.GET_AVAILABLE,
            [GoProSettings.PROTUNE, GoProSettings.WHITE_BL]b
        );
        BleAPI.device.processRequests();

        if (camera.getSetting(GoProSettings.PROTUNE) != 0) {
            logger.error("Protune should be 0 before toggle, got: " + camera.getSetting(GoProSettings.PROTUNE));
            return false;
        }

        // settings with anything but 2 available values can't be toggled
        if (camera.toggleSetting(GoProSettings.WHITE_BL) != null) {
            logger.error("Toggling white balance should return null, it has " \
                + camera.getAvailableSettings(GoProSettings.WHITE_BL).size() + " available values");
            result = false;
        }

        if (camera.toggleSetting(GoProSettings.PROTUNE) != 1 or camera.getSetting(GoProSettings.PROTUNE) != 1) {
            logger.error("Protune should have been toggled to 1, got: " + camera.getSetting(GoProSettings.PROTUNE));
            result = false;
        }

        BleAPI.device.processRequests();

        if (camera.toggleSetting(GoProSettings.PROTUNE) != 0 or camera.getSetting(GoProSettings.PROTUNE) != 0) {
            logger.error("Protune should have been toggled back to 0, got: " + camera.getSetting(GoProSettings.PROTUNE));
            result = false;
        }

        BleAPI.device.processRequests();

        return result;
    }


    (:test)
    function testToggleSettingOutOfAvailable(logger as Logger) as Boolean {
        // current setting isn't part of the available values: warn instead of
        // writing an out of bounds value
        TestInit.initDefaults();
        TestInit.initSettings.put(GoProSettings.PROTUNE, 1);
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);

        var camera = getApp().gopro;
        camera.queryValues(GoProDecoder.REGISTER_SETTING, [GoProSettings.PROTUNE]b);
        camera.queryValues(GoProDecoder.GET_AVAILABLE, [GoProSettings.PROTUNE]b);
        BleAPI.device.processRequests();

        // 42 isn't in the available values, which are 0 and 1. The fake device
        // refuses out of range writes, so its state is changed directly.
        BleAPI.device.settings.put(GoProSettings.PROTUNE, 42);
        camera.queryValues(GoProDecoder.REGISTER_SETTING, [GoProSettings.PROTUNE]b);
        BleAPI.device.processRequests();

        if (camera.getSetting(GoProSettings.PROTUNE) != 42) {
            logger.error("Protune should be 42 before toggle, got: " + camera.getSetting(GoProSettings.PROTUNE));
            return false;
        }

        if (camera.toggleSetting(GoProSettings.PROTUNE) != null) {
            logger.error("Toggling a setting which isn't in the available values should return null");
            return false;
        }

        if (camera.getSetting(GoProSettings.PROTUNE) != 42) {
            logger.error("Protune should not have been changed, got: " + camera.getSetting(GoProSettings.PROTUNE));
            return false;
        }

        BleAPI.device.processRequests();

        return true;
    }


    (:test)
    function testProtuneLabels(logger as Logger) as Boolean {
        var result = true;
        TestInit.initDefaults();
        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);

        var camera = getApp().gopro;
        BleAPI.device.processRequests();

        var ids = [
            GoProSettings.PROTUNE,
            GoProSettings.PROTUNE,
            GoProSettings.WHITE_BL,
            GoProSettings.WHITE_BL,
            GoProSettings.WHITE_BL,
            GoProSettings.WHITE_BL,
            GoProSettings.COLOR,
            GoProSettings.COLOR,
            GoProSettings.COLOR,
            GoProSettings.COLOR,
            GoProSettings.SHARPNESS,
            GoProSettings.SHARPNESS,
            GoProSettings.SHARPNESS,
            GoProSettings.EV_COMP,
            GoProSettings.EV_COMP,
            GoProSettings.EV_COMP,
            GoProSettings.ISO_MAX,
            GoProSettings.ISO_MAX,
            GoProSettings.ISO_MAX,
            GoProSettings.ISO_MIN,
            GoProSettings.ISO_MIN,
        ];
        var values = [
            1, 0,
            0, 4, 3, 8,
            GoProSettings.COLOR_GOPRO, GoProSettings.COLOR_FLAT,
            GoProSettings.COLOR_NATURAL, GoProSettings.COLOR_VIBRANT,
            GoProSettings.SHARP_HIGH, GoProSettings.SHARP_MEDIUM, GoProSettings.SHARP_LOW,
            0, 4, 8,
            9, 0, 8,
            9, 8,
        ];
        var expected = [
            Rez.Strings.Enabled, Rez.Strings.Disabled,
            Rez.Strings.Auto, Rez.Strings.Native, "6500K", "2300K",
            Rez.Strings.GoPro, Rez.Strings.Flat, Rez.Strings.Natural, Rez.Strings.Vibrant,
            Rez.Strings.High, Rez.Strings.Medium, Rez.Strings.Low,
            "2.0", "0.0", "-2.0",
            Rez.Strings.Auto, "6400", "100",
            Rez.Strings.Auto, "100",
        ];

        for (var i=0; i<ids.size(); i+=1) {
            var label = camera.getLabel(ids[i], values[i]);
            if (!label.equals(expected[i])) {
                logger.error("Wrong label for setting id: " + ids[i] + ", value: " + values[i] \
                    + ", expected: " + expected[i] + ", got: " + label);
                result = false;
            }
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

        TestInit.initFake(null);
        TestInit.initConnection(GoProCamera.GP_HERO11M);
        
        var camera = getApp().gopro;
        BleAPI.device.processRequests();
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

        camera.sendCommand(GoProCamera.LOAD_PGRP);
        BleAPI.device.processRequests();

        label = camera.getDescription();
        if (!label.equals("")) {
            logger.error("Expected empty placeholder description got :" + label);
            return false;
        }

        return true;
    }
}