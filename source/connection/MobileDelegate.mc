import Toybox.Lang;
import Toybox.System;
import Toybox.Communications;
import Toybox.StringUtil;

using Toybox.BluetoothLowEnergy as Ble;


(:mobile)
class MobileDelegate extends CameraDelegate {

    private var queue as Array<Object>;
    private var failCount = 0;

    public function initialize() {
        CameraDelegate.initialize();
        queue = [];
    }

    public function connect(device as Ble.ScanResult?) as Void {
        CameraDelegate.connect(device);
        Communications.registerForPhoneAppMessages(method(:onReceive) as Communications.PhoneMessageCallback);
        transmit(true);
    }

    protected function onDisconnect() as Void {
        if (connected) {
            transmit(false);
        }
        queue = [];
        Communications.registerForPhoneAppMessages(null);
        CameraDelegate.onDisconnect();
    }
    
    protected function onPairingFailed() as Void {
        CameraDelegate.onPairingFailed();
        onDisconnect();
    }

    public function onReceive(message as Communications.PhoneAppMessage) as Void {
        var data = message.data;
        if (data instanceof Boolean) {
            if (data) {
                onConnect(null);
            } else {
                onPairingFailed();
            }
            return;
        }
        
        System.println("Received: " + data);
        if (data instanceof Array) {
            var uuid = data[0];
            data.remove(uuid);
            if (uuid == GattProfileManager.UUID_QUERY_RESPONSE_CHAR) {
                decodeQuery([]b.addAll(data));
            }
        }
    }

    private function transmit(data as Object) {
        System.println("sending data: "+data.toString());
        queue.add(data);
        if (queue.size() == 1) { processQueue(); }
    }

    public function send(
        type as GattRequest.RequestType,
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
                onDisconnect();
                return;
            }
            failCount++;
            Communications.transmit(
                queue[0],
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

    public function onComplete() as Void {
        System.println("Succesfully sent message");
        getApp().timerController.start(completeCallback, 1, false);
    }

    public function onError() {
        System.println("Error while sending message");
        errorCallback.invoke();
    }
}