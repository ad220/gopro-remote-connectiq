import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using CommApiWrapper as CommAPI;
using GattProfileManager as GPM;

(:debug :ble)
class FakeGoProInterface {

    var gpControlService as Ble.Service;
    var gpQueryResponseChar as Ble.Characteristic;

    function initialize() {
        var device = new BleAPI.MockDevice();
        gpControlService = new BleAPI.MockService(Ble.stringToUuid(GPM.GOPRO_CONTROL_SERVICE), device);
        gpQueryResponseChar = new BleAPI.MockCharacteristic(
            GPM.getUuid(GPM.UUID_QUERY_RESPONSE_CHAR),
            gpControlService as BleAPI.MockService
        );
    }

    function disconnect() as Void {
        BleAPI.delegate.onConnectedStateChanged(
            gpControlService.getDevice(),
            Ble.CONNECTION_STATE_DISCONNECTED
        );
    }

    function sendMessage(charId as GPM.GoProUuid, msg as ByteArray) as Void {
        var char = gpControlService.getCharacteristic(GPM.getUuid(charId));
        if (char != null) { BleAPI.delegate.onCharacteristicChanged(char, msg); }
    }

}

(:debug :mobile)
class FakeGoProInterface {
    function disconnect() as Void {
        transmit(false);
    }

    function sendMessage(charId as GPM.GoProUuid, msg as ByteArray) as Void {

        var packet = [GattRequestQueue.WRITE_CHARACTERISTIC, charId];
        for (var i=0; i<msg.size(); i++) { packet.add(msg[i]); }
        transmit(packet);
    }

    function transmit(data as Object) as Void {
        var msg = new Communications.PhoneAppMessage();
        msg.data = data;

        var callback = CommAPI.eventCallback;
        if (callback != null) { callback.invoke(msg); }
    }
}