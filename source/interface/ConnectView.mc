import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

using Toybox.BluetoothLowEnergy as Ble;
using InterfaceComponentsManager as ICM;


class ConnectView extends WatchUi.View {

    private var label as String;


    function initialize(label as String) {
        View.initialize();

        self.label = label;
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(0x00AAFF, Graphics.COLOR_BLACK);
        dc.clear();
        dc.fillRoundedRectangle(ICM.halfW-75*ICM.kMult, ICM.halfH+50*ICM.kMult, 150*ICM.kMult, 40*ICM.kMult, 20*ICM.kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ICM.halfW, ICM.halfH+70*ICM.kMult, ICM.adaptFontMid(), label, ICM.JTEXT_MID);
        drawRectWithBorder(dc, -32, -63, 26, 10, 4, 2, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, -51, -58, 102, 92, 16, 4, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, -7, -58, 58, 58, 16, 4, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, -40, -25, 25, 25, 6, 3, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, -39, -46, 20, 9, 4, 3, 0xFF5500);
        drawRectWithBorder(dc, +4, +7, 36, 16, 8, 3, 0x00AAFF);
        drawRectWithBorder(dc, +6, -45, 32, 32, 16, 10, Graphics.COLOR_LT_GRAY);
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
    private const CONNECTING_NOTIF      = WatchUi.loadResource(Rez.Strings.Connecting);
    private const CONNECT_ERROR_NOTIF   = WatchUi.loadResource(Rez.Strings.ConnectFail);

    private var lastPairedDevice as Ble.ScanResult?;
    private var timerController as TimerController;
    private var viewController as ViewController;
    private var delegate as GoProDelegate;


    public function initialize(lastPairedDevice as Ble.ScanResult?, timerController as TimerController, viewController as ViewController) {
        BehaviorDelegate.initialize();

        self.lastPairedDevice = lastPairedDevice;
        self.timerController = timerController;
        self.viewController = viewController;
        // self.delegate = new GoProDelegateStub(timerController, viewController);
        self.delegate = new GoProDelegate(timerController, viewController);
        Ble.setDelegate(delegate);
        GattProfileManager.registerProfiles();
    }

    public function onSelect() {
        // onScanResult(null);
        if (lastPairedDevice instanceof Ble.ScanResult) {
            onScanResult(lastPairedDevice);
        } else {
            startScan();
        }
        return true;
    }

    public function onMenu() {
        startScan();
        return true;
    }

    private function startScan() as Void {
        var scanMenu = new CustomMenu((50*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {:titleItemHeight => (80*ICM.kMult).toNumber()});
        var menuDelegate = new ScanMenuDelegate(scanMenu, viewController, timerController, method(:onScanResult));
        delegate.setScanStateChangeCallback(menuDelegate.method(:setScanState));
        delegate.setScanResultCallback(menuDelegate.method(:onScanResults));
        viewController.push(scanMenu, menuDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    public function onScanResult(device as Ble.ScanResult?) as Void {
        if (device!=null and !device.equals(lastPairedDevice)) {
            Storage.setValue("lastPairedDevice", device as Application.PropertyValueType);
        }
        delegate.setScanStateChangeCallback(null);
        delegate.setScanResultCallback(null);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
        viewController.push(new NotifView(CONNECTING_NOTIF, NotifView.NOTIF_INFO), new NotifDelegate(), WatchUi.SLIDE_DOWN);
        delegate.pair(device);
    }
}