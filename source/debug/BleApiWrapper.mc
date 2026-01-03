import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;

(:ble :debug)
module BleApiWrapper {
    
    const DUMMY_UUID = "0000A6FE-0000-1000-8000-00805F9B34FB";

    typedef GattProfile as {
        :uuid as Ble.Uuid,
        :characteristics as Array<{
            :uuid as Ble.Uuid,
            :descriptors as Array<Ble.Uuid>
        }>
    };

    typedef ServiceProfile as Array<{:uuid as Ble.Uuid, :descriptors as Array<Ble.Uuid>}>;

    (:initialized) var callbacks    as BleApiCallbacks;
    (:initialized) var device       as FakeGoProDevice;

    var registeredProfiles          as Array<GattProfile>   = [];
    var delegate                    as Ble.BleDelegate?     = null;
    var scanState                   as Ble.ScanState        = Ble.SCAN_STATE_OFF;
    var pairedDevice                as Array<Ble.Device>    = [];
    var scanTimer                   as TimerCallback?       = null;

    // Test options
    var failPairing                 as Boolean              = false;
    var nullPairing                 as Boolean              = false;
    var connectionStatus            as Ble.ConnectionState  = Ble.CONNECTION_STATE_CONNECTED;
    var hasGoProService             as Boolean              = true;
    var scannedDevices              as MockIterator         = new MockIterator([new MockScanResult(0)]);


    function getCallbackInstance(delegate as BluetoothDelegate) as BleApiCallbacks {
        callbacks = new BleApiCallbacks(delegate);
        return callbacks;
    }

    function registerProfile(profile as GattProfile) as Void {
        if (registeredProfiles.size() < 3) {
            self.registeredProfiles.add(profile);
        } else {
            throw new Ble.ProfileRegistrationException();
        }
    }

    function setDelegate(delegate as Ble.BleDelegate) as Void {
        self.delegate = delegate;
    }

    function setScanState(state as Ble.ScanState) as Void {
        if (state == Ble.SCAN_STATE_OFF) {
            if (scanTimer != null) {
                scanTimer.stop();
                scanTimer = null;
            }
        } else if (state == Ble.SCAN_STATE_SCANNING and scanState!=state) {
            scanTimer = getApp().timerController.start(new Method(self, :updateScan), 10, true);
        }

        self.scanState = state;
        callbacks.onScanStateChange(state, Ble.STATUS_SUCCESS);
    }

    function updateScan() as Void {
        callbacks.onScanResults(scannedDevices);
    }

    function pairDevice(device as Ble.ScanResult) as Ble.Device? {
        if (failPairing or pairedDevice.size() >= 3) {
            throw new Ble.DevicePairException();

        } else if (nullPairing) {
            return null;

        } else {
            var result = new MockDevice() as Ble.Device;
            callbacks.onConnectedStateChanged(result, connectionStatus);
            pairedDevice.add(result);
            return result;
        }
    }

    function unpairDevice(device as Ble.Device) as Void {
        // TODO
        Ble.unpairDevice(device);
    }


    class MockScanResult {

        var id as Number;

        function initialize(id as Number) {
            self.id = id;
        }

        function getDeviceName() as String? {
            return "MockResult";
        }

        function getRawData() as ByteArray {
            return []b;
        }

        function getServiceUuids() as Ble.Iterator {
            var uuid = hasGoProService ? GattProfileManager.GOPRO_CONTROL_SERVICE : DUMMY_UUID;
            return new MockIterator([Ble.stringToUuid(uuid)]);
        }

        function isSameDevice(other as Ble.ScanResult) as Boolean {
            return self.id == (other as MockScanResult).id;
        }
    }

    class MockDevice {

        var connected       as Boolean      = false;
        var bonded          as Boolean      = false;

        function getName() as String? {
            return "MockGoPro";
        }

        function getService(uuid as Ble.Uuid) as Ble.Service? {
            var registeredUuids = [];
            for (var i=0; i<registeredProfiles.size(); i+=1) {
                registeredUuids.add(registeredProfiles[i].get(:uuid));
            }
            
            return registeredUuids.indexOf(uuid) > -1 ? new MockService(uuid, self) as Ble.Service : null;
        }

        function getServices() as Ble.Iterator {
            var result = [];
            for (var i=0; i<registeredProfiles.size(); i+=1) {
                result.add(new MockService(registeredProfiles[i].get(:uuid) as Ble.Uuid, self));
            }
            return new MockIterator(result);
        }

        function isBonded() as Boolean {
            return bonded;
        }

        function isConnected() as Boolean {
            return connected;
        }

        function requestBond() as Void {
            bonded = true;
            BleAPI.callbacks.onEncryptionStatus(self as Ble.Device, Ble.STATUS_SUCCESS);
        }
    }

    class MockService {

        var uuid        as Ble.Uuid;
        var device      as MockDevice;
        var profile     as ServiceProfile;

        function initialize(uuid as Ble.Uuid, device as MockDevice) {
            self.uuid = uuid;
            self.device = device;

            var profile = getServiceProfile();
            if (profile == null) { throw new Exception(); }

            self.profile = profile;
        }

        private function getServiceProfile() as ServiceProfile? {
            for (var i=0; i<registeredProfiles.size(); i+=1) {
                if (self.uuid.equals(registeredProfiles[i].get(:uuid))) {
                    return registeredProfiles[i].get(:characteristics);
                }
            }
            return null;
        }

        function getCharacteristic(uuid as Ble.Uuid) as Ble.Characteristic? {
            var registeredUuids = [];
            
            for (var i=0; i<profile.size(); i+=1) {
                registeredUuids.add(profile[i].get(:uuid));
            }

            return registeredUuids.indexOf(uuid) > -1 ? new MockCharacteristic(uuid, self) as Ble.Characteristic : null;
        }
        
        function getCharacteristics() as Ble.Iterator {
            var characteristics = [];

            for (var i=0; i<profile.size(); i+=1) {
                characteristics.add(
                    new MockCharacteristic(profile[i].get(:uuid) as Ble.Uuid,
                    self
                ));
            }

            return new MockIterator(characteristics);
        }

        function getDevice() as Ble.Device {
            return device as Ble.Device;
        }

        function getUuid() as Ble.Uuid {
            return uuid;
        }

    }

    class MockCharacteristic {
        
        var uuid        as Ble.Uuid;
        var service     as MockService;
        var profile     as Array<Ble.Uuid>;

        function initialize(uuid as Ble.Uuid, service as MockService) {
            self.uuid = uuid;
            self.service = service;

            var profile = null;
            for (var i=0; i<service.profile.size(); i+=1) {
                if (uuid.equals(service.profile[i].get(:uuid))) {
                    profile = service.profile[i].get(:descriptors);
                    break;
                }
            }
            if (profile == null) { throw new Exception(); }
            self.profile = profile;
        }

        function getDescriptor(uuid as Ble.Uuid) as Ble.Descriptor? {
            return profile.indexOf(uuid) > -1 ? new MockDescriptor(uuid, self) as Ble.Descriptor : null;
        }

        function getDescriptors() as Ble.Iterator {
            var descriptors = [];

            for (var i=0; i<profile.size(); i+=1) {
                descriptors.add(new MockDescriptor(profile[i], self));
            }

            return new MockIterator(descriptors);
        }

        function getService() as Ble.Service {
            return service as Ble.Service;
        }

        function getUuid() as Ble.Uuid {
            return uuid;
        }

        function requestRead() as Void {
            // TODO
            throw new Exception();
        }

        (:typecheck(false))
        function requestWrite(value as ByteArray, options as { :writeType as Ble.WriteType }) as Void {
            var gpxx = uuid.toString().substring(4,8).toNumber();
            callbacks.onCharacteristicWrite(self as Ble.Characteristic, Ble.STATUS_SUCCESS);
            device.onSend(gpxx, value);
        }

    }


    class MockDescriptor {

        var uuid            as Ble.Uuid;
        var characteristic  as MockCharacteristic;

        function initialize(uuid as Ble.Uuid, characteristic as MockCharacteristic) {
            self.uuid = uuid;
            self.characteristic = characteristic;
        }

        function getCharacteristic() as Ble.Characteristic {
            return characteristic as Ble.Characteristic;
        }

        function getUuid() as Ble.Uuid {
            return uuid;
        }

        function requestRead() as Void {
            // TODO
            throw new Exception();
        }

        (:typecheck(false))
        function requestWrite(value as ByteArray) as Void {
            callbacks.onDescriptorWrite(self as Ble.Characteristic, Ble.STATUS_SUCCESS);
        }
    }


    class MockIterator extends Ble.Iterator {
        var content as Array;
        var counter as Number = 0;

        (:typecheck(false))
        function initialize(content as Array) {
            self.content = content;
        }

        function next() as Object? {
            if (counter < content.size()) {
                var result = content[counter];
                counter += 1;
                return result as Object?;
            }
            else {
                return null;
            }
        }
    }

}
