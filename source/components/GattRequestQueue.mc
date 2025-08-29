import Toybox.System;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;

class GattRequestQueue {

    private var service as Ble.Service;
    private var timer as TimerController;
    private var queue as Array<GattRequest>;
    private var isProcessing as Boolean;


    public function initialize(service as Ble.Service, timer as TimerController) {
        self.service = service;
        self.timer = timer;
        self.queue = [];
        self.isProcessing = false;
    }

    public function add(type as GattRequest.RequestType, uuid as Ble.Uuid, data as ByteArray) {
        var request = new GattRequest(type, uuid, data, timer);
        request.setCallbacks(method(:sendRequest), method(:onRequestFail));
        queue.add(request);
        if (!isProcessing) {
            isProcessing = true;
            sendRequest();
        }
    }

    public function onRequestProcessed(uuid as Ble.Uuid, status as Ble.Status) {
        var request = queue[0];
        if (request != null and uuid.equals(request.getUuid()) and status==Ble.STATUS_SUCCESS) {
            queue.remove(queue[0]);
            if (queue.size()>0) {
                sendRequest();
            } else {
                isProcessing = false;
            }
        } else {
            System.println("Write operation failed or queue is not synchronized");
        }
    }

    public function sendRequest() as Void {
        isProcessing = true;
        var request = queue[0];
        var characteristic = service.getCharacteristic(request.getUuid());
        if (request.getType() == GattRequest.REGISTER_NOTIFICATION) {
            var descriptor = characteristic.getDescriptor(Ble.cccdUuid());
            descriptor.requestWrite(request.getData());
        } else {
            characteristic.requestWrite(request.getData(), {:writeType => Ble.WRITE_TYPE_DEFAULT});
        }
        request.startTimer();
    }

    public function onRequestFail() as Void {
        System.println("GATT write operation failed");
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
    private var timer as TimerController;
    private var done as Boolean;
    private var failCounter as Number;

    private var retryCallback as (Method() as Void)?;
    private var tooManyFailsCallback as (Method() as Void)?;


    public function initialize(type as RequestType, uuid as Ble.Uuid, data as ByteArray, timer as TimerController) {
        self.type = type;
        self.uuid = uuid;
        self.data = data;
        self.timer = timer;
        self.done = false;
        self.failCounter = 0;
    }

    public function getType() as RequestType {
        return type;
    }

    public function getUuid() as Ble.Uuid {
        return uuid;
    }

    public function getData() as ByteArray{
        return data;
    }

    public function isAnswered() as Boolean {
        return done;
    }

    public function setCallbacks(retryCallback as Method() as Void, tooManyFailsCallback as Method() as Void) as Void {
        self.retryCallback = retryCallback;
        self.tooManyFailsCallback = tooManyFailsCallback;
    }

    public function startTimer() as Void {
        if (failCounter==0) {
            timer.start(method(:onTimeOut), 2, false);
        }
    }

    public function onTimeOut() as Void {
        if (!done) {
            failCounter++;
            if (failCounter<3) {
                retryCallback.invoke();
            } else {
                tooManyFailsCallback.invoke();
            }
        }
    }

    public function onResponse() as Void {
        done = true;
    }


}