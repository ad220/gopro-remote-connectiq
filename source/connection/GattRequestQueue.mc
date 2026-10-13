import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using ErrorManager as EM;
using GattProfileManager as GPM;


(:ble)
class GattRequestQueue {

    static const ALREADY_FAIL_CNTR_FLAG = 1 << 16; 

    enum RequestType {
        REGISTER_NOTIFICATION,
        WRITE_CHARACTERISTIC,
    }

    enum RequestParams {
        REQ_TYPE,
        REQ_UUID,
        REQ_DATA,
        REQ_TIMER,
    }

    typedef GattRequest as [RequestType, GPM.GoProUuid, ByteArray, TimerCallback?];


    private var device          as Ble.Device;
    protected var queue         as Array<GattRequest>;
    protected var isProcessing  as Boolean;
    protected var failCounter   as Number;


    public function initialize(device as Ble.Device) {
        self.device = device;
        self.queue = [];
        self.isProcessing = false;
        self.failCounter = 0;
    }


    public function add(type as RequestType, gpxx as GPM.GoProUuid, data as ByteArray) as Void {
        var request = [type, gpxx, data, null] as GattRequest;
        queue.add(request);
        if (!isProcessing) {
            failCounter = 0;
            sendRequest();
        }
    }


    private function sendRequest() as Void {
        isProcessing = true;
        var req = queue[0];
        req[REQ_TIMER] = getApp().timerController.start(method(:onRequestTimeout), 5, false);

        var uuid = req[REQ_UUID];
        var service = device.getService(GPM.getServiceUuid(uuid));
        var characteristic = service!=null ? service.getCharacteristic(GPM.getUuid(uuid)) : null;
        if (characteristic == null) {
            onRequestFail(EM.SUB_BLE_BADSCD | 0x01);
            return;
        }

        var data = req[REQ_DATA];
        // Register notifications for characteristic
        if (req[REQ_TYPE] == GattRequestQueue.REGISTER_NOTIFICATION) {
            var descriptor = characteristic.getDescriptor(Ble.cccdUuid());
            if (descriptor == null) {
                onRequestFail(EM.SUB_BLE_BADSCD | 0x02);
                return;
            }

            try         { descriptor.requestWrite(data); }
            catch (ex)  { onRequestFail(EM.SUB_BLE_WRITE | 0x00); }

        // Write request.data in characteristic
        } else {
            try {
                characteristic.requestWrite(data, {:writeType => Ble.WRITE_TYPE_DEFAULT});
            }
            catch (ex)  { onRequestFail(EM.SUB_BLE_WRITE | 0x00); }
        }
        
        // System.println("[DEBUG]     Write data " + req[REQ_DATA] + " to char " + req[REQ_UUID]);
    }


    private function nextRequest() as Void {
        queue = queue.slice(1, queue.size());
        if (queue.size()>0) {
            failCounter = 0;
            sendRequest();
        } else {
            isProcessing = false;
        }
    }

    
    public function onRequestProcessed(type as RequestType, uuid as Ble.Uuid, status as Ble.Status) as Void {
        if (queue.size() < 1) {
            EM.raise(EM.ERR_COMM, EM.SUB_BLE_NULLQ | 0x04, :WarningErr);
            isProcessing = false;
            return;
        }
        var request = queue[0];
        
        if (status != Ble.STATUS_SUCCESS) {
            onRequestFail(EM.SUB_BLE_STATUS | 0x03);
            return;
        }
        
        var timer = request[REQ_TIMER];
        if (
            type != GattRequestQueue.REGISTER_NOTIFICATION and
            !uuid.equals(GPM.getUuid(request[REQ_UUID])) or timer == null
        ) {
            // System.println("[WARNING]   Desynchronized request queue");
            onRequestFail(EM.SUB_BLE_NULLQ | 0x05);
            return;
        }
        
        timer.stop();
        nextRequest();
    }


    public function onRequestTimeout() as Void {
        if (failCounter & ALREADY_FAIL_CNTR_FLAG) {
            failCounter ^= ALREADY_FAIL_CNTR_FLAG;
        } else { 
            onRequestFail(EM.SUB_BLE_TO);
        }

        if (failCounter < 3)    { sendRequest(); /* retry */ }
        else                    { nextRequest(); /* skip */ }
    }


    private function onRequestFail(errCode as Number) as Void {
        failCounter++;
        EM.raise(EM.ERR_COMM, errCode, failCounter < 3 ? :SilentErr : :WarningErr);

        if (errCode != EM.SUB_BLE_TO) {
            failCounter ^= ALREADY_FAIL_CNTR_FLAG;
        }
        // System.println("[WARNING]   GATT write operation failed");
    }


    public function close() as Void {
        if (isProcessing) {
            var timer = queue[0][REQ_TIMER];
            if (queue.size()<1 or timer == null) {
                EM.raise(EM.ERR_COMM, EM.SUB_BLE_NULLQ | 0x06, :SilentErr);
            } else {
                timer.stop();
            }
        }
        queue = [];
        isProcessing = false;
    }
}


(:mobile)
class GattRequestQueue {

    enum RequestType {
        REGISTER_NOTIFICATION,
        WRITE_CHARACTERISTIC,
    }
}
