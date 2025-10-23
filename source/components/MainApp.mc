import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.BluetoothLowEnergy;

(:glance)
class GoProRemoteApp extends Application.AppBase {

    public var fromGlance as Boolean;

    (:initialized) public var timerController as TimerController;
    (:initialized) public var viewController as ViewController;
    (:initialized) public var gopro as GoProCamera;
    private var lastPairedDevice as BluetoothLowEnergy.ScanResult?;

    function initialize() {
        AppBase.initialize();
        self.fromGlance = false;
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        lastPairedDevice = Storage.getValue("lastPairedDevice") as BluetoothLowEnergy.ScanResult;
        if (state!=null) {
            fromGlance = state.get(:launchedFromGlance) == true;
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        if (viewController!=null) {
            viewController.returnHome(null, null);
        }
        if (timerController!=null) {
            timerController.stopAll();
        }
    }

    // Return the initial view of your application here
    function getInitialView() {
        self.timerController = new TimerController(500);
        self.viewController = new ViewController();
        InterfaceComponentsManager.computeInterfaceConstants();
        InterfaceComponentsManager.loadFonts();
        var label = lastPairedDevice==null ? WatchUi.loadResource(Rez.Strings.Pair) : WatchUi.loadResource(Rez.Strings.Connect);
        var delegate = new ConnectDelegate(lastPairedDevice);
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