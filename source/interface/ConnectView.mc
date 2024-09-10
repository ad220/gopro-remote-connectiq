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

class GoProConnectDelegate extends WatchUi.BehaviorDelegate {
        var view;

    public function initialize(_view) {
        BehaviorDelegate.initialize();
        view = _view;
    }

    public function onSelect() {
        mobile.connect();
        mobile.send([COM_CONNECT, 0]);
        WatchUi.pushView(new PopUpView(MainResources.labels[UI_CONNECT][CONNECTING], POP_INFO), new PopUpDelegate(), WatchUi.SLIDE_BLINK);
        return true;
    }
}