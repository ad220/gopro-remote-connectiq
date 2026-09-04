import Toybox.Lang;
import Toybox.Test;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;


(:test :ble)
module GoProCameraBleTest {

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
}