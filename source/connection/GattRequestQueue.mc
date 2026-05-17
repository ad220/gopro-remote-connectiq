import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using ErrorManager as EM;


(:ble)
class GattRequestQueue {

    static const ALREADY_FAIL_CNTR_FLAG = 1 << 16; 

    enum RequestType {
        REGISTER_NOTIFICATION,
        WRITE_CHARACTERISTIC,
    }

    typedef GattRequest as {
        :type           as RequestType,
        :uuid           as Ble.Uuid,
        :data           as ByteArray,
        :timer          as TimerCallback?,
    };


    private var service         as Ble.Service;
    protected var queue         as Array<GattRequest>;
    protected var isProcessing  as Boolean;
    protected var failCounter   as Number;


    public function initialize(service as Ble.Service) {
        self.service = service;
        self.queue = [];
        self.isProcessing = false;
        self.failCounter = 0;
    }


    public function add(type as RequestType, uuid as Ble.Uuid, data as ByteArray) as Void {
        var request = {:type => type, :uuid => uuid, :data => data, :timer => null} as GattRequest;
        queue.add(request);
        if (!isProcessing) {
            failCounter = 0;
            sendRequest();
        }
    }


    private function sendRequest() as Void {
        isProcessing = true;
        var request = queue[0];
        var characteristic = service.getCharacteristic(request[:uuid] as Ble.Uuid);
        if (characteristic == null) {
            onRequestFail(EM.SUB_BLE_BADSCD | 0x01);
            return;
        }

        request[:timer] = getApp().timerController.start(method(:onRequestTimeout), 5, false);

        // Register notifications for characteristic
        if (request[:type] == GattRequestQueue.REGISTER_NOTIFICATION) {
            var descriptor = characteristic.getDescriptor(Ble.cccdUuid());
            if (descriptor == null) {
                onRequestFail(EM.SUB_BLE_BADSCD | 0x02);
                return;
            }

            try         { descriptor.requestWrite(request[:data] as ByteArray); }
            catch (ex)  { onRequestFail(EM.SUB_BLE_WRITE | 0x00); }

        // Write request.data in characteristic
        } else {
            try {
                characteristic.requestWrite(request[:data] as ByteArray, {:writeType => Ble.WRITE_TYPE_DEFAULT});
            }
            catch (ex)  { onRequestFail(EM.SUB_BLE_WRITE | 0x00); }
        }
        
        // System.println("[DEBUG]     Write data " + request.getData() + " to char " + request.getUuid());
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
        
        if (
            type != GattRequestQueue.REGISTER_NOTIFICATION and
            !uuid.equals(request[:uuid]) or request[:timer] == null
        ) {
            // System.println("[WARNING]   Desynchronized request queue
            onRequestFail(EM.SUB_BLE_NULLQ | 0x05);
            return;
        }
        
        (request[:timer] as TimerCallback).stop();
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
        // TODO(test)
        failCounter++;
        EM.raise(EM.ERR_COMM, errCode, failCounter < 3 ? :SilentErr : :WarningErr);

        if (errCode != EM.SUB_BLE_TO) {
            failCounter ^= ALREADY_FAIL_CNTR_FLAG;
        }
        // System.println("[WARNING]   GATT write operation failed");
    }


    public function close() as Void {
        if (isProcessing) {
            if (queue.size()<1 or queue[0][:timer] == null) {
                EM.raise(EM.ERR_COMM, EM.SUB_BLE_NULLQ | 0x06, :SilentErr);
            } else {
                (queue[0][:timer] as TimerCallback).stop();
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
