import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Test;

using GattProfileManager as GPM;
using BleApiWrapper as BleAPI;
using Toybox.BluetoothLowEnergy as Ble;

(:test)
module TestInit {

    function haveSameData(a as Array, b as Array) as Boolean {
        if (a.size() != b.size()) { return false; }

        for (var i=0; i<a.size(); i+=1) {
            if (!(a[i] as Object).equals(b[i] as Object)) { return false; }
        }

        return true;
    }

    class MockKeyEvent extends WatchUi.KeyEvent {
        var key as Key;
        var pressType as KeyPressType;

        (:typecheck(false))
        function initialize(key as Key, pressType as KeyPressType) {
            self.key = key;
            self.pressType = pressType;
        }

        function getKey() as Key {
            return key;
        }

        function getType() as KeyPressType {
            return pressType;
        }
    }

    class DebugCustomMenu extends WatchUi.CustomMenu {

        var debugItems as Array<MenuItem>;

        (:typecheck(false))
        function initialize(itemHeight, backgroundColor, options) {
            CustomMenu.initialize(itemHeight, backgroundColor, options);

            self.debugItems = mItems;
        }
    }

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
        GoProSettings.HYPERSMOOTH       => GoProSettings.HS_BOOST,
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
        delegate.connect(new BleAPI.MockScanResult(0, null) as Ble.ScanResult);
    }

}