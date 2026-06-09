import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

using Toybox.BluetoothLowEnergy as Ble;
using BleApiWrapper as BleAPI;
using ErrorManager as EM;


(:glance)
class GoProRemoteApp extends Application.AppBase {

    public var fromGlance as Boolean;

    (:typecheck(false)) private var appStarted as Boolean;

    (:initialized) public var timerController as TimerController;
    (:initialized) public var viewController as ViewController;
    (:initialized) public var gopro as GoProCamera;
    (:initialized) public var reportsEnabled as Boolean;
    private var lastPairedDevice as Ble.ScanResult?;

    function initialize() {
        AppBase.initialize();
        self.fromGlance = false;
        self.appStarted = false;
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // System.println("[APP DBG]   App started");

        lastPairedDevice = Storage.getValue("lastPairedDevice") as Ble.ScanResult;

        var reportsEnabled = Storage.getValue("reportsEnabled") as Boolean?;
        self.reportsEnabled = reportsEnabled != null ? reportsEnabled : true;

        var errorQueue = Storage.getValue("errorQueue") as Array<Number>?;
        EM.errorQueue = errorQueue != null ? errorQueue : [] as Array<Number>;

        if (reportsEnabled) { EM.report(); }
        
        if (state!=null) {
            fromGlance = state.get(:launchedFromGlance) as Boolean == true;
        }
    }

    // onStop() is called when your application is exiting
    (:ble :typecheck(false))
    function onStop(state as Dictionary?) as Void {
        if (appStarted) {
            if (viewController != null)     { viewController.returnHome(null, null); }
            if (timerController != null)    { timerController.stopAll(); }
            BleAPI.setDelegate(null as Ble.BleDelegate);
        }

        Storage.setValue("reportsEnabled", reportsEnabled);
        Storage.setValue("errorQueue", EM.errorQueue);
        // System.println("[APP DBG]   App stopped");
    }

    (:mobile :typecheck(false))
    function onStop(state as Dictionary?) as Void {
        if (appStarted) {
            if (viewController != null)     { viewController.returnHome(null, null); }
            if (timerController!=null)      { timerController.stopAll(); }
            Communications.registerForPhoneAppMessages(null);
        }
        
        Storage.setValue("reportsEnabled", reportsEnabled);
        Storage.setValue("errorQueue", EM.errorQueue);
        // System.println("[APP DBG]   App stopped");
    }

    // Return the initial view of your application here
    (:typecheck(false))
    function getInitialView() {
        self.appStarted = true;
        self.timerController = new TimerController(200);
        self.viewController = new ViewController();

        InterfaceComponentsManager.loadFonts();
        
        var label = lastPairedDevice==null ? WatchUi.loadResource(Rez.Strings.Pair) : WatchUi.loadResource(Rez.Strings.Connect);
        var delegate = new ConnectDelegate(lastPairedDevice);
        return [ new ConnectView(label, delegate), delegate ];
    }

    (:highend)
    function getGlanceView() as [GlanceView] or [GlanceView, GlanceViewDelegate] or Null {
        var label;
        if (lastPairedDevice==null) {
            label = WatchUi.loadResource(Rez.Strings.GlanceScan) as String;
        } else {
            label = WatchUi.loadResource(Rez.Strings.GlanceConnect) as String + lastPairedDevice.getDeviceName();
        }
        return [new RemoteGlance(label)];
    }
}

public function getApp() as GoProRemoteApp {
    return Application.getApp();
}