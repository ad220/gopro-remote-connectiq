import Toybox.Lang;
import Toybox.Communications;

(:ble)
module CommApiWrapper {
    // prevent warnings caused by using statements with ble builds
}

(:mobile :release)
module CommApiWrapper {

    (:inline)
    function registerForPhoneAppMessages(method as PhoneMessageCallback?) as Void {
        Communications.registerForPhoneAppMessages(method);
    }

    (:inline)
    function transmit(content as TransmitType, options as Dictionary?, listener as ConnectionListener) as Void {
        Communications.transmit(content, options, listener);
    }
}