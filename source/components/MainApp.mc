import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.BluetoothLowEnergy;


class GoProRemoteApp extends Application.AppBase {

    public var timerController as TimerController;
    public var viewController as ViewController;
    public var fromGlance as Boolean;

    private var lastPairedDevice as BluetoothLowEnergy.ScanResult?;

    function initialize() {
        AppBase.initialize();
        self.timerController = new TimerController(500);
        self.viewController = new ViewController(timerController);
        self.fromGlance = false;
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        System.println("App started");
        InterfaceComponentsManager.computeInterfaceConstants();
        InterfaceComponentsManager.loadFonts();
        lastPairedDevice = Storage.getValue("lastPairedDevice");
        if (state!=null) {
            fromGlance = state.get(:launchedFromGlance) == true;
        }
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
        var delegate = new ConnectDelegate(lastPairedDevice, timerController, viewController);
        return [ new ConnectView(label, delegate), delegate ];
    }

    function getGlanceView() as [GlanceView] or [GlanceView, GlanceViewDelegate] or Null {
        var label;
        if (lastPairedDevice==null) {
            label = WatchUi.loadResource(Rez.Strings.GlanceScan);
        } else {
            label = WatchUi.loadResource(Rez.Strings.GlanceConnect) + lastPairedDevice.getDeviceName();
        }
        return [new RemoteGlance(label)];
    }
}

public function getApp() as GoProRemoteApp {
    return Application.getApp();
}