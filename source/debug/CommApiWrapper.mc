import Toybox.Lang;
import Toybox.Communications;

using GattProfileManager as GPM;

(:mobile :debug)
module CommApiWrapper {

    (:initialized) var delegate as MobileDelegate;
    (:initialized) var device as FakeGoProDevice;

    var eventCallback as PhoneMessageCallback?;


    function registerForPhoneAppMessages(method as PhoneMessageCallback?) as Void {
        eventCallback = method;
    }

    function transmit(content as TransmitType, options as Dictionary?, listener as ConnectionListener) as Void {
        listener.onComplete();

        if (content instanceof Lang.Boolean) {
            var msg = new Communications.PhoneAppMessage();
            msg.data = content ? device.specs.cameraId : false;

            if (eventCallback != null) { eventCallback.invoke(msg); }
        }
        
        if (content instanceof Lang.Array) {
            if (content [0]) {
                var gpxx = content[1] as GPM.GoProUuid;
                var data = []b.addAll(content.slice(2, null) as Array);

                device.onSend([gpxx, data]);
            }
        }
    }

}