import Toybox.BluetoothLowEnergy;
import Toybox.Lang;

// COMMAND IDs
const BLE_SHUTTER = 1;
const BLE_SLEEP = 5;
const BLE_HILIGHT = 24;

// SETTINGS IDs
const BLE_RESOLUTION = 2;
const BLE_FRAMERATE = 3;
const BLE_LENS = 121;
const BLE_FLICKER = 134;
const BLE_HYPERSMOOTH = 135;

// STATUS IDs
const BLE_HOT = 6;
const BLE_BUSY = 8;
const BLE_ENCODING = 10;
const BLE_PROGRESS = 13;
const BLE_BATTERY = 70;
const BLE_READY = 82;
const BLE_COLD = 85;

// QUERY IDs
const GET_SETTINGS = 18;            // 0x12
const GET_STATUS = 19;              // 0x13
const GET_AVAILABLE = 50;           // 0x32
const REGISTER_SETTINGS = 82;       // 0x52
const REGISTER_STATUS = 83;         // 0x53
const REGISTER_AVAILABLE = 98;      // 0x62
const UNREGISTER_SETTINGS = 114;    // 0x72
const UNREGISTER_STATUS = 115;      // 0x73
const UNREGISTER_AVAILABLE = 130;   // 0x82
const NOTIF_SETTINGS = 146;         // 0x92
const NOTIF_STATUS = 147;           // 0x93
const NOTIF_AVAILABLE = 162;        // 0xA2


class BleInterface {
    private var bleDelegate as BleDelegate;

    public function initialize() {
        bleDelegate = new BleDelegate();
        BluetoothLowEnergy.setDelegate(bleDelegate);
    }

    public function connect() {
        
    }

    public static function scanForGoPros() {
        BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_SCANNING);
    }
}