import Toybox.Lang;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;

class GattProfileManager {
    public static const GOPRO_CONTROL_SERVICE   = "0000FEA6-0000-1000-8000-00805F9B34FB";

    public enum GP_UUID {
        UUID_COMMAND_CHAR           = 72,
        UUID_COMMAND_RESPONSE_CHAR,
        UUID_SETTINGS_CHAR,
        UUID_SETTINGS_RESPONSE_CHAR,
        UUID_QUERY_CHAR,
        UUID_QUERY_RESPONSE_CHAR,
        UUID_CONTROL_MAX,

        // UUID_MANAGE_SERVICE         = 90,
        // UUID_NETWORK_CHAR,
        // UUID_NETWORK_RESPONSE_CHAR,
        // UUID_MANAGE_MAX,
    }
    
    (:inline)
    public static function getUuid(gpxx as Number) as Ble.Uuid {
        return Ble.stringToUuid("B5F9" + gpxx.format("%04d") + "-AA8D-11E3-9046-0002A5D5C51B");
    }

    (:ble)
    public static function registerProfile(serviceUuid as Ble.Uuid, charMin as Number, charMax as Number) as Void {
        var profile = {
            :uuid => serviceUuid
        };
        var chars = [];
        while(charMin<charMax) {
            chars.add({
                :uuid => getUuid(charMin),
                :descriptors => [Ble.cccdUuid()]
            });
            charMin++;
        }
        profile.put(:characteristics, chars);
        
        try {
            Ble.registerProfile(profile);
        } catch (ex) {
            System.println(ex.getErrorMessage());
        }
    }
}