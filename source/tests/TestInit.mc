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

    class MockPreset extends GoProPreset {
        function initialize(settings as Dictionary<GoProSettings.SettingId, Number>) {
            GoProPreset.initialize(0);

            self.settings = settings;
        }
    }

    const defaultSettings = {
        GoProSettings.RESOLUTION        => 1,
        GoProSettings.LENS              => GoProSettings.WIDE,
        GoProSettings.FRAMERATE         => 5,
        GoProSettings.FLICKER           => GoProSettings.HZ60,
        GoProSettings.HYPERSMOOTH       => GoProSettings.HS_LOW,
        GoProSettings.LED               => GoProSettings.LED_ON,
        GoProSettings.PHOTO_LENS        => GoProSettings.WIDE_FULL,
    };

    const defaultStatuses = {
        GoProCamera.ENCODING            => 0,
        GoProCamera.ENCODING_DURATION   => 0,
        GoProCamera.SD_REMAINING        => 6942,
        GoProCamera.BATTERY             => 42,
        GoProCamera.PHOTOS_TAKEN        => 1234,
        GoProCamera.PRESET_GRP          => GoProCamera.PGRP_VIDEO,
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

    function initFake(specs as FakeGoProSpecs.ISpecs?) as Void {
        if (specs == null) { specs = FakeGoProSpecs.getSpecsH11M(); }

        if (specs.cameraId < GoProCamera.GP_MAX) {
            initStatuses[GoProCamera.PRESET_GRP] = Helper.createNullObject() as Number;
            initStatuses[GoProCamera.CAPTURE_MODE] = GoProCamera.MODE_VIDEO;
        }

        BleAPI.device = new FakeGoProDevice(
            initSettings,
            initStatuses,
            specs
        );
    }

    function initConnection(goproId as Number) as Void {
        var delegate = new BluetoothDelegate();
        delegate.connect(new BleAPI.MockScanResult(0, null, goproId) as Ble.ScanResult);
        BleAPI.device.processRequests();
    }

}