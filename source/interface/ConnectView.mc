import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class ConnectView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        MainResources.loadLabels(UI_CONNECT);
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(0x00AAFF, Graphics.COLOR_BLACK);
        dc.clear();
        dc.fillRoundedRectangle(halfW-75*kMult, halfH+50*kMult, 150*kMult, 40*kMult, 20*kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(halfW, halfH+70*kMult, adaptFontMid(), MainResources.labels[UI_CONNECT][CONNECT] as String, JTEXT_MID);
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
        dc.fillRoundedRectangle(halfW+offx*kMult, halfH+offy*kMult, w*kMult, h*kMult, rad*kMult);
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(halfW+(offx+thick)*kMult, halfH+(offy+thick)*kMult, (w-2*thick)*kMult, (h-2*thick)*kMult, (rad-thick)*kMult);
    }
}

var delegate as GoProDelegate?;
var profileManager as GattProfileManager?;


class GoProConnectDelegate extends WatchUi.BehaviorDelegate {
    private var viewController;


    public function initialize(viewController) {
        self.viewController = viewController;

        BehaviorDelegate.initialize();
    }

    public function onSelect() {
        // mobile.connect();
        // mobile.send([COM_CONNECT, 0]);
        // viewController.push(new NotifView(MainResources.labels[UI_CONNECT][CONNECTING], notifView.NOTIF_INFO), new NotifDelegate(), WatchUi.SLIDE_BLINK, false);
        var scanMenu = new WatchUi.Menu2({});
        var menuDelegate = new ScanMenuDelegate(scanMenu, viewController);
        delegate = new GoProDelegate();
        profileManager = new GattProfileManager();
        BluetoothLowEnergy.setDelegate(delegate);
        profileManager.registerProfiles();
        delegate.setScanStateChangeCallback(menuDelegate.method(:setScanState));
        delegate.setScanResultCallback(menuDelegate.method(:onScanResults));
        BluetoothLowEnergy.setConnectionStrategy(BluetoothLowEnergy.CONNECTION_STRATEGY_SECURE_PAIR_BOND);

        viewController.push(scanMenu, menuDelegate, WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}