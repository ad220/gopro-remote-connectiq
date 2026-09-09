import Toybox.Lang;
import Toybox.System;
import Toybox.Communications;
import Toybox.StringUtil;

using Toybox.BluetoothLowEnergy as Ble;
using CommApiWrapper as CommAPI;
using ErrorManager as EM;
using GattProfileManager as GPM;

(:mobile)
class MobileDelegate extends CameraDelegate {

    private var queue as Array<Object>;
    private var failCount as Number;

    public function initialize() {
        CameraDelegate.initialize();
        queue = [];
        failCount = 0;
    }

    public function connect(device as Ble.ScanResult?) as Void {
        CameraDelegate.connect(device);
        CommAPI.registerForPhoneAppMessages(method(:onReceive) as Communications.PhoneMessageCallback);
        transmit(true);
    }

    protected function disconnect() as Void {
        if (connected) {
            transmit(false);
        }
        queue = [];
        CommAPI.registerForPhoneAppMessages(null);
        CameraDelegate.disconnect();
    }
    
    protected function onPairingFailed(errCode as Number) as Void {
        CameraDelegate.onPairingFailed(errCode);
        disconnect();
    }

    public function onReceive(message as Communications.PhoneAppMessage) as Void {
        var data = message.data;
        if (data instanceof Boolean) {
            if (data) {
                onConnect(null);
            } else {
                if (isPairing())    { onPairingFailed(EM.SUB_BLE_STATUS | 0x0F);  }
                else                { disconnect(); }
            }
            return;
        }
        if (data instanceof Number) {
            goproId = data;
            onConnect(null);
        }
        
        // System.println("[DEBUG]     Received from mobile: " + data);
        if (data instanceof Array) {
            var uuid = data[0] as GPM.GoProUuid;
            data.remove(uuid);
            onMessage(uuid, []b.addAll(data));
        }
    }

    private function transmit(data as Object) as Void {
        // System.println("[DEBUG]     Sending to mobile: "+data.toString());
        queue.add(data);
        if (queue.size() == 1) { processQueue(); }
    }

    public function send(
        type as GattRequestQueue.RequestType,
        uuid as GattProfileManager.GoProUuid,
        data as ByteArray
    ) as Void {
        var packet = [type, uuid];
        for (var i=0; i<data.size(); i++) { packet.add(data[i]); }
        transmit(packet);
    }

    public function processQueue() as Void {
        if (queue.size()>0) {
            if (failCount>3) {
                connected = false;
                disconnect();
                return;
            }
            failCount++;
            CommAPI.transmit(
                queue[0] as TransmitType,
                {},
                new MobileConnection(
                    method(:onSent),
                    method(:processQueue)
                )
            );
        } 
    }

    public function onSent() as Void {
        failCount = 0;
        queue.remove(queue[0]);
        processQueue();
    }
}

(:mobile)
class MobileConnection extends Communications.ConnectionListener {

    private var completeCallback as Method;
    private var errorCallback as Method;

    public function initialize(
        completeCallback as Method,
        errorCallback as Method
    ) {
        ConnectionListener.initialize();

        self.completeCallback = completeCallback;
        self.errorCallback = errorCallback;
    }

    (:release)
    public function onComplete() as Void {
        getApp().timerController.start(completeCallback, 1, false);
    }

    (:debug)
    public function onComplete() as Void {
        completeCallback.invoke();
    }

    public function onError() {
        // System.println("[WARNING]   Error while sending message");
        errorCallback.invoke();
    }
}