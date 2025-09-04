import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.BluetoothLowEnergy;


class GoProRemoteApp extends Application.AppBase {
    private var timerController as TimerController?;
    private var viewController as ViewController?;
    private var lastPairedDevice as BluetoothLowEnergy.ScanResult?;

    function initialize() {
        AppBase.initialize();
        
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        System.println("App started");
        InterfaceComponentsManager.computeInterfaceConstants();
        InterfaceComponentsManager.loadFonts();
        timerController = new TimerController();
        viewController = new ViewController(timerController);
        lastPairedDevice = Storage.getValue("lastPairedDevice");
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        System.println("App stopped");
        viewController.returnHome(null, null);
        timerController.stopAll();
    }

    // Return the initial view of your application here
    function getInitialView() {
        var label = lastPairedDevice==null ? WatchUi.loadResource(Rez.Strings.Pair) : WatchUi.loadResource(Rez.Strings.Connect);
        return [ new ConnectView(label), new ConnectDelegate(lastPairedDevice, timerController, viewController) ];
    }

}