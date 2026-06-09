import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Communications;
import Toybox.PersistedContent;

using InterfaceComponentsManager as ICM;


/**
 * ErrorManager module
 * 
 * Used to raise and warn the user about unexpected errors with a 32-bit code
 * Code format is defined as:
 * | 31 -- BF -- 30 | 29 -- GP ID -- 24 | 23 -- EC -- 16 | 15 -- data1 -- 8 | 7 -- data0 -- 0 |
 * 
 * - BF (build flags):
 *      MSB -> highend UI (0) / lowend UI (1)
 *      LSB -> ble comm (0) / mobile comm (1)
 * - GP ID:
 *      Internal GoPro model id, check CameraDelegate.mc for more info
 * - EC (error code):
 *      check ERR constants below for more information
 */

module ErrorManager {

    (:ble)              const BUILD_FLAGS = 0;
    (:mobile :highend)  const BUILD_FLAGS = 1 << 30;
    (:mobile :lowend)   const BUILD_FLAGS = 3 << 30;

    const   ERR_CAM         = 0x80 << 16;   // gopro settings error
    const   ERR_MSG         = 0x40 << 16;   // message encoding / decoding error
    const   ERR_EXT         = 0x30 << 16;   // reserved for extended error codes
    const   ERR_COMM        = 0x20 << 16;   // communication error (ble or mobile)
    const   ERR_SYS         = 0x10 << 16;   // system api exception
    const   ERR_NULL        = 0x00;         // unexpected null exception

    const   SUB_BLE_STATUS  = 0x00;         // status != success
    const   SUB_BLE_CONN    = 0x10;         // not connected
    const   SUB_BLE_NULLQ   = 0x40;         // null queue (maybe too many bits reserved)
    const   SUB_BLE_BADSCD  = 0x80;         // bad service, characteristic or descriptor
    const   SUB_BLE_WRITE   = 0x90;         // write fail
    const   SUB_BLE_TO      = 0xA0;         // timeout
    const   SUB_BLE_API     = 0xF0;         // ble api exception

    const   SUB_CAM_ID      = 0x00 << 16;   // unknown setting / status id
    const   SUB_CAM_VAL     = 0x10 << 16;   // unknown setting / status value
    const   SUB_CAM_NULL    = 0x20 << 16;   // null settings / status / available
    const   SUB_CAM_AVAIL   = 0x30 << 16;   // settings not in available

    const   SUB_MSG_STATUS  = 0x00 << 16;   // camera status != 0
    const   SUB_MSG_QUERY   = 0x10 << 16;   // unknown query
    const   SUB_MSG_STRUCT  = 0x20 << 16;   // bad message structure
    // const   SUB_MSG_        = 0x30 << 16;

    
    var stable as Boolean = true;
    var running as Boolean = true;
    (:initialized :glance) var errorQueue as Array<Number>;


    /**
     * Adds the error to the errorQueue for future report and 
     * warns the user about the error
     *
     * @param code      prefix of the error code as defined above
     * @param data      16-bit error context
     * @param level     error level, should be on of {:SilentErr, :WarningErr, :CriticalErr} 
     */
    function raise(code as Number, data as Number, level as Symbol) as Void {
        if (!running) { return; } // don't raise an error if a critical one already occured
        
        var app = getApp();
        var goproId = app.gopro != null ? app.gopro.getGoProId() : 0;

        code |= BUILD_FLAGS | (0x3F & goproId.toNumber() << 24) | (0xFFFF & data);

        errorQueue.add(code);
        if (errorQueue.size() > 64) { errorQueue = errorQueue.slice(1, null); }

        if (level != :SilentErr and (stable or level == :CriticalErr)) {
            if (level != :ConnectErr) { stable = false; }
            if (level == :CriticalErr) { running = false; }

            var msg = ICM.loadString(level);
            var format = "%04X";
            var errMsg = msg + (code >> 16).format(format) + \
                         "_" + (code & 0xFFFF).format(format);
            
            var view = new NotifView(errMsg, NotifView.NOTIF_ERROR);

            if (level != :CriticalErr) {
                app.viewController.push(view, null, WatchUi.SLIDE_UP);
            } else {
                app.viewController.returnHome(null, null);
                app.viewController.switchTo(view, null, WatchUi.SLIDE_IMMEDIATE);

                if (app.gopro instanceof GoProCamera) { app.gopro.disconnect(); }
            }
        }
    }

    (:glance)
    function report() as Void {
        if (errorQueue.size() == 0) { return; }

        var url = "";
        for (var i = 0; i < Secrets.API_URL.size(); i++) {
            url += (Secrets.API_URL[i] ^ Secrets.API_KEY[i & 0x1F]).toChar();
        }

        var hexKey = "";
        for (var i = 0; i < Secrets.API_KEY.size(); i++) {
            hexKey += Secrets.API_KEY[i].format("%02x");
        }

        Communications.makeWebRequest(
            url,
            {"errors" => errorQueue},
            {
                :method       => Communications.HTTP_REQUEST_METHOD_POST,
                :headers      => {
                    "X-API-Key"    => hexKey,
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_URL_ENCODED
            },
            new Method(self, :reportCallback)
        );
    }

    (:glance)
    function reportCallback(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (responseCode == 200) {
            errorQueue = [];
        }
    }
}