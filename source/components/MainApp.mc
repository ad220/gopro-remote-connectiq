import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

var cam as GoProCamera?;
var mobile as MobileStub?;


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
        cam = new GoProCamera();
        mobile = new MobileStub();
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
        return [ new ConnectView(), new GoProConnectDelegate(viewController, timerController) ];
    }

}

function getApp() as GoProRemoteApp {
    return Application.getApp() as GoProRemoteApp;
}