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
        if (content instanceof Lang.Boolean) {
            var msg = new Communications.PhoneAppMessage();
            msg.data = content;

            if (eventCallback != null) { eventCallback.invoke(msg); }
        }
        
        if (content instanceof Lang.Array) {
            var gpxx = content[0] as GPM.GoProUuid;
            content.remove(gpxx);
            var data = []b.addAll(content as Array);

            listener.onComplete();
            device.onSend([gpxx, data]);
        }
    }

}