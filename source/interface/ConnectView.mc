import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

using Toybox.BluetoothLowEnergy as Ble;
using InterfaceComponentsManager as ICM;


class ConnectView extends WatchUi.View {

    private var connectLabel as String?;


    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        connectLabel = WatchUi.loadResource(Rez.Strings.Connect);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(0x00AAFF, Graphics.COLOR_BLACK);
        dc.clear();
        dc.fillRoundedRectangle(ICM.halfW-75*ICM.kMult, ICM.halfH+50*ICM.kMult, 150*ICM.kMult, 40*ICM.kMult, 20*ICM.kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ICM.halfW, ICM.halfH+70*ICM.kMult, ICM.adaptFontMid(), connectLabel, ICM.JTEXT_MID);
        drawRectWithBorder(dc, -32, -63, 26, 10, 4, 2, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, -51, -58, 102, 92, 16, 4, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, -7, -58, 58, 58, 16, 4, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, -40, -25, 25, 25, 6, 3, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, -39, -46, 20, 9, 4, 3, 0xFF5500);
        drawRectWithBorder(dc, +4, +7, 36, 16, 8, 3, 0x00AAFF);
        drawRectWithBorder(dc, +6, -45, 32, 32, 16, 10, Graphics.COLOR_LT_GRAY);
    }

    public function onHide() as Void {
        connectLabel = null;
    }

    private function drawRectWithBorder(dc, offx, offy, w, h, rad, thick, color) as Void{
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(ICM.halfW+offx*ICM.kMult, ICM.halfH+offy*ICM.kMult, w*ICM.kMult, h*ICM.kMult, rad*ICM.kMult);
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(ICM.halfW+(offx+thick)*ICM.kMult, ICM.halfH+(offy+thick)*ICM.kMult, (w-2*thick)*ICM.kMult, (h-2*thick)*ICM.kMult, (rad-thick)*ICM.kMult);
    }
}

var delegate as GoProDelegate?;


class ConnectDelegate extends WatchUi.BehaviorDelegate {
    private var timerController as TimerController;
    private var viewController as ViewController;
    private var connectingLabel as String;
    private var connectErrorLabel as String;


    public function initialize(timerController, viewController) {
        self.timerController = timerController;
        self.viewController = viewController;
        self.connectingLabel = WatchUi.loadResource(Rez.Strings.Connecting);
        self.connectErrorLabel = WatchUi.loadResource(Rez.Strings.ConnectFail);

        BehaviorDelegate.initialize();
    }

    public function onSelect() {
        // mobile.connect();
        // mobile.send([MobileDevice.COM_CONNECT, 0]);
        // viewController.push(new NotifView(connectingLabel, notifView.NOTIF_INFO), new NotifDelegate(), WatchUi.SLIDE_BLINK, false);
        var scanMenu = new WatchUi.Menu2({});
        var menuDelegate = new ScanMenuDelegate(scanMenu, viewController, timerController, method(:onScanResult));
        delegate = new GoProDelegateStub(timerController, viewController);
        Ble.setDelegate(delegate);
        GattProfileManager.registerProfiles();
        delegate.setScanStateChangeCallback(menuDelegate.method(:setScanState));
        delegate.setScanResultCallback(menuDelegate.method(:onScanResults));
        // Ble.setConnectionStrategy(Ble.CONNECTION_STRATEGY_SECURE_PAIR_BOND);

        // viewController.push(scanMenu, menuDelegate, WatchUi.SLIDE_IMMEDIATE);
        onScanResult(null);
        return true;
    }

    public function onScanResult(device as Ble.ScanResult?) as Void {
        delegate.setScanStateChangeCallback(null);
        delegate.setScanResultCallback(null);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
        delegate.pair(device);
        viewController.push(new NotifView(connectingLabel, NotifView.NOTIF_INFO), new NotifDelegate(), WatchUi.SLIDE_DOWN);
    }
}