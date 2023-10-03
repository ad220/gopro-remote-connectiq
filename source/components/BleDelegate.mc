import Toybox.BluetoothLowEnergy;
import Toybox.Lang;


// const GOPRO_SERVICE_UUID = BluetoothLowEnergy.stringToUuid("0000fea6-0000-1000-8000-00805f9b34fb");

class BleDelegate extends BluetoothLowEnergy.BleDelegate {
    var device as BluetoothLowEnergy.ScanResult?;

    function onScanResults(scanResults as Iterator) {
        var device = scanResults.next(); //as ScanResult?
        var gopros = []; //as Array<ScanResult>
        var serviceUuids; // as Iterator<Uuid>
        var uuid; // as Uuid
        // while (device != null) {
        //     serviceUuids = device.getServiceUuids();
        //     uuid = serviceUuids.next();
        //     while (uuid != null) {
        //         if (uuid == GOPRO_SERVICE_UUID) {
        //             gopros.add(device);
        //             break;
        //         }
        //         uuid = serviceUuids.next();
        //     }
        //     device = scanResults.next();
        // }
        
        // call ui to draw scan results
    }


}