import Toybox.Lang;
import Toybox.WatchUi;


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
 *      CAM  (0x80) -> gopro unexpected behavior, 7 LSB for suberror type and index
 *      MSG  (0x40) -> unexpected message decoding error, 6 LSB for suberror type and index
 *      EXT  (0x30) -> extended error code, reserved for future use
 *      COMM (0x20) -> communication error, context depends on build flag (ble / mobile)
 *      SYS  (0x10) -> unexpected system exception
 *      NULL (0x00) -> unexpected null exception
 */

module ErrorManager {

    (:ble)              const BUILD_FLAGS = 0;
    (:mobile :highend)  const BUILD_FLAGS = 1 << 30;
    (:mobile :lowend)   const BUILD_FLAGS = 3 << 30;

    const   ERR_CAM     = 0x80 << 16;
    const   ERR_MSG     = 0x40 << 16;
    const   ERR_EXT     = 0x30 << 16;
    const   ERR_COMM    = 0x20 << 16;
    const   ERR_SYS     = 0x10 << 16;
    const   ERR_NULL    = 0;
    
    var shuttingDown as Boolean = false;
    // var errorQueue as Array<Number> = [];


    /**
     * Adds the error to the errorQueue for future report and 
     * warns the user about the error
     *
     * @param code      prefix of the error code as defined above
     * @param gopro     gopro advertised model id
     * @param level     error level, should be on of {:SilentErr, :WarningErr, :CriticalErr} 
     */
    function raise(code as Number, gopro as Number, data as Number, level as Symbol) as Void {
        if (shuttingDown) { return; }

        code |= BUILD_FLAGS | (0x3F & gopro << 24);

        // errorQueue.add(code);
        // if (errorQueue.size() > 64) { errorQueue = errorQueue.slice(1, null); }

        if (level != :SilentErr) {
            var app = getApp();
            var msg = getMsgTemplate(level);
            var format = "%04X";
            var errMsg = msg + (code >> 16).format(format) + \
                         "_" + (code & 0xFFFF).format(format);
            
            var view = new NotifView(errMsg, NotifView.NOTIF_ERROR);

            if (level == :WarningErr) {
                app.viewController.push(view, null, WatchUi.SLIDE_UP);
            } else {
                shuttingDown = true;
                app.viewController.returnHome(null, null);
                app.viewController.switchTo(view, null, WatchUi.SLIDE_IMMEDIATE);

                if (app.gopro instanceof GoProCamera) { app.gopro.disconnect(); }
            }
        }
    }

    (:typecheck(false) :inline)
    function getMsgTemplate(level as Symbol) as String {
        return WatchUi.loadResource(Rez.Strings[level]);
    }

}