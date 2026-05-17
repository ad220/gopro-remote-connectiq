import Toybox.Lang;
import Toybox.Test;
import Toybox.System;

using ErrorManager as EM;

(:test)
module ErrorManagerTest {
    
    (:test)
    function testRaise(logger as Logger) as Boolean {
        var result = true;

        TestInit.initSink();
        TestInit.initConnection();

        var viewController = new ViewDebugController();
        getApp().viewController = viewController;

        if (EM.errorQueue.size() != 0) {
            logger.error("ErrorManager not properly inntialized, queue is not empty");
            return false;
        }

        EM.raise(EM.ERR_COMM, EM.SUB_BLE_API | 0x05, :SilentErr);
        EM.raise(EM.ERR_CAM | EM.SUB_CAM_VAL | 0x07 << 16, GoProSettings.HS_AUTO_BOOST << 8 + GoProSettings.HYPERSMOOTH, :SilentErr);
        EM.raise(EM.ERR_NULL, 220, :WarningErr);

        if (EM.errorQueue.size() != 3) {
            logger.error("Error queue should have a length of 3");
            result = false;
        }

        if (viewController.stack.size() != 1) {
            logger.error("Raising a warning error should have pushed a notif view, view stack size=" + viewController.stack.size());
            result = false;
        }

        if (!(viewController.stack[0][0] instanceof NotifView)) {
            logger.error("Current view ain't a notif view after raising a warning error");
            result = false;
        }
        
        viewController.pop($.Toybox.WatchUi.SLIDE_IMMEDIATE);

        EM.raise(EM.ERR_NULL, 221, :WarningErr);
        
        if (viewController.stack.size() != 0) {
            logger.error("Raising a second warning error should not push a notif view, view stack size=" + viewController.stack.size());
            result = false;
        }

        EM.raise(EM.ERR_SYS, 42, :CriticalErr);
        
        if (viewController.stack.size() != 1) {
            logger.error("Raising a critical error should have pushed a notif view, view stack size=" + viewController.stack.size());
            result = false;
        }

        if (!(viewController.stack[0][0] instanceof NotifView)) {
            logger.error("Current view ain't a notif view after raising a critical error");
            result = false;
        }
        
        viewController.pop($.Toybox.WatchUi.SLIDE_IMMEDIATE);
        EM.raise(EM.ERR_SYS, 67, :CriticalErr);
        
        if (viewController.stack.size() != 0) {
            logger.error("Raising a second critical error should not push a notif view, view stack size=" + viewController.stack.size());
            result = false;
        }

        if (EM.errorQueue.size() != 5) {
            logger.error("Expected error queue length was 5, is actually: " + EM.errorQueue.size());
            return false;
        }

        var expectedQueue = [
            0x102000F5,
            0x10970487,
            0x100000DC,
            0x100000DD,
            0x1010002A,
        ] as Array;

        if (!TestInit.haveSameData(expectedQueue, EM.errorQueue as Array)) {
            logger.error("Error queue data differ with expected error codes:\nexpected=" + expectedQueue + "\nerror queue=" + EM.errorQueue);
            result = false;
        }

        return result;
    }
}