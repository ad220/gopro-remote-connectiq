import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;

class GattProfileManager {
    public static const GOPRO_CONTROL_SERVICE              = Ble.stringToUuid("0000FEA6-0000-1000-8000-00805F9B34FB");
    public static const COMMAND_CHARACTERISTIC             = Ble.stringToUuid("B5F90072-AA8D-11E3-9046-0002A5D5C51B");
    public static const COMMAND_RESPONSE_CHARACTERISTIC    = Ble.stringToUuid("B5F90073-AA8D-11E3-9046-0002A5D5C51B");
    public static const SETTINGS_CHARACTERISTIC            = Ble.stringToUuid("B5F90074-AA8D-11E3-9046-0002A5D5C51B");
    public static const SETTINGS_RESPONSE_CHARACTERISTIC   = Ble.stringToUuid("B5F90075-AA8D-11E3-9046-0002A5D5C51B");
    public static const QUERY_CHARACTERISTIC               = Ble.stringToUuid("B5F90076-AA8D-11E3-9046-0002A5D5C51B");
    public static const QUERY_RESPONSE_CHARACTERISTIC      = Ble.stringToUuid("B5F90077-AA8D-11E3-9046-0002A5D5C51B");
    
    public static const GOPRO_MANAGE_SERVICE               = Ble.stringToUuid("B5F90090-AA8D-11E3-9046-0002A5D5C51B");
    public static const NETWORK_CHARACTERISTIC             = Ble.stringToUuid("B5F90091-AA8D-11E3-9046-0002A5D5C51B");
    public static const NETWORK_RESPONSE_CHARACTERISTIC    = Ble.stringToUuid("B5F90092-AA8D-11E3-9046-0002A5D5C51B");

    private static const goproControlProfileDef = {
        :uuid => GOPRO_CONTROL_SERVICE,
        :characteristics => [{
            :uuid => COMMAND_CHARACTERISTIC,
            :descriptors => [Ble.cccdUuid()]
        }, {
            :uuid => COMMAND_RESPONSE_CHARACTERISTIC,
            :descriptors => [Ble.cccdUuid()]
        }, {
            :uuid => SETTINGS_CHARACTERISTIC,
            :descriptors => [Ble.cccdUuid()]
        }, {
            :uuid => SETTINGS_RESPONSE_CHARACTERISTIC,
            :descriptors => [Ble.cccdUuid()]
        }, {
            :uuid => QUERY_CHARACTERISTIC,
            :descriptors => [Ble.cccdUuid()]
        }, {
            :uuid => QUERY_RESPONSE_CHARACTERISTIC,
            :descriptors => [Ble.cccdUuid()]
        }]
    };

    private static const goproManageProfileDef = {
        :uuid => GOPRO_MANAGE_SERVICE,
        :characteristics => [{
            :uuid => NETWORK_CHARACTERISTIC,
            :descriptors => [Ble.cccdUuid()]
        }, {
            :uuid => NETWORK_RESPONSE_CHARACTERISTIC,
            :descriptors => [Ble.cccdUuid()]
        }]
    };

    public static function registerProfiles() as Void {
        System.println("register");
        try {
            Ble.registerProfile(goproControlProfileDef);
            Ble.registerProfile(goproManageProfileDef);
        } catch (ex) {
            System.println(ex.getErrorMessage());
        }
    }

}