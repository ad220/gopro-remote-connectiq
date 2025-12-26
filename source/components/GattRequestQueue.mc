import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

class GattRequestQueue {

    private var service as Ble.Service;
    protected var queue as Array<GattRequest>;
    protected var isProcessing as Boolean;


    public function initialize(service as Ble.Service) {
        self.service = service;
        self.queue = [];
        self.isProcessing = false;
    }

    public function add(type as GattRequest.RequestType, uuid as Ble.Uuid, data as ByteArray) as Void {
        var request = new GattRequest(type, uuid, data, self);
        System.println("Message added to queue, data: "+data);
        queue.add(request);
        if (!isProcessing) {
            sendRequest();
        }
    }

    public function sendRequest() as Void {
        isProcessing = true;
        var request = queue[0];
        if (!(request.getData() instanceof ByteArray)) {
            System.println("Request data is not a ByteArray: "+request.getData());
            onRequestProcessed(request.getType(), request.getUuid(), Ble.STATUS_SUCCESS);
        }
        var characteristic = service.getCharacteristic(request.getUuid());
        System.println("Sending request");
        try {
            if (request.getType() == GattRequest.REGISTER_NOTIFICATION) {
                var descriptor = characteristic.getDescriptor(Ble.cccdUuid());
                descriptor.requestWrite(request.getData());
            } else {
                characteristic.requestWrite(request.getData(), {:writeType => Ble.WRITE_TYPE_DEFAULT});
            }
        } catch (ex) {
            System.println(ex.getErrorMessage());
        }
        request.startTimer();
    }
    
    public function onRequestProcessed(type as GattRequest.RequestType, uuid as Ble.Uuid, status as Ble.Status) as Void {
        var request = queue[0];
        if (request != null and (type==GattRequest.REGISTER_NOTIFICATION or uuid.equals(request.getUuid())) and status==Ble.STATUS_SUCCESS) {
            System.println("Write op went successfully");
            request.onResponse();
            queue = queue.slice(1, queue.size());
            if (queue.size()>0) {
                sendRequest();
            } else {
                isProcessing = false;
            }
        } else {
            System.println("Write operation failed or queue is not synchronized, status: " + status);
        }
    }

    public function onRequestFail() as Void {
        System.println("GATT write operation failed");
    }

    public function close() as Void {
        while (queue.size()>0) {
            queue[0].onResponse();
            queue = queue.slice(1, queue.size());
        }
        isProcessing = false;
        try {
            Ble.unpairDevice(service.getDevice());
        } catch (ex) {
            System.println("Error while closing GattRequestQueue: "+ex.getErrorMessage());
        }
    }
}

class GattRequest {
    public enum RequestType {
        REGISTER_NOTIFICATION,
        WRITE_CHARACTERISTIC,
    }

    private var type as RequestType;
    private var uuid as Ble.Uuid;
    private var data as ByteArray;
    private var done as Boolean;
    private var failCounter as Number;
    private var queue as WeakReference<GattRequestQueue>;


    public function initialize(type as RequestType, uuid as Ble.Uuid, data as ByteArray, queue as GattRequestQueue) {
        self.type = type;
        self.uuid = uuid;
        self.data = data;
        self.queue = queue.weak();
        self.done = false;
        self.failCounter = 0;
    }

    public function getType() as RequestType {
        return type;
    }

    public function getUuid() as Ble.Uuid {
        return uuid;
    }

    public function getData() as ByteArray {
        return data;
    }

    public function isAnswered() as Boolean {
        return done;
    }

    public function startTimer() as Void {
        if (failCounter==0) {
            getApp().timerController.start(method(:onTimeOut), 2, false);
        }
    }

    public function onTimeOut() as Void {
        if (!done and queue.stillAlive()) {
            failCounter++;
            if (failCounter<3) {
                queue.get().sendRequest();
            } else {
                queue.get().onRequestFail();
            }
        }
    }

    public function onResponse() as Void {
        done = true;
    }
}