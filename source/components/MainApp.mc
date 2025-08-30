import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;


class GoProRemoteApp extends Application.AppBase {
    private var timerController as TimerController?;
    private var viewController as ViewController?;

    function initialize() {
        AppBase.initialize();
        
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        InterfaceComponentsManager.computeInterfaceConstants();
        InterfaceComponentsManager.loadFonts();
        timerController = new TimerController();
        viewController = new ViewController(timerController);
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        viewController.returnHome(null, null);
        timerController.stopAll();
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new ConnectView(), new ConnectDelegate(timerController, viewController) ];
    }

}

function getApp() as GoProRemoteApp {
    return Application.getApp() as GoProRemoteApp;
}