import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class GoProConnectView extends WatchUi.View {

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
        dc.fillRoundedRectangle(45, 170, 150, 40, 20);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRoundedRectangle(45, 110, 150, 40, 20);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(120, 190, MainResources.fontSmall, MainResources.labels[UI_CONNECT][1] as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(120, 130, MainResources.fontSmall, MainResources.labels[UI_CONNECT][2] as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Drawing of a medium sized GoPro in the middle of a 240x240 screen
        // drawRectWithBorder(dc, 88, 57, 26, 10, 4, 2, Graphics.COLOR_DK_GRAY);
        // drawRectWithBorder(dc, 69, 62, 102, 92, 16, 4, Graphics.COLOR_DK_GRAY);
        // drawRectWithBorder(dc, 113, 62, 58, 58, 16, 4, Graphics.COLOR_DK_GRAY);
        // drawRectWithBorder(dc, 80, 95, 25, 25, 6, 3, Graphics.COLOR_DK_GRAY);
        // drawRectWithBorder(dc, 81, 74, 20, 9, 4, 3, 0xFF5500);
        // drawRectWithBorder(dc, 124, 127, 36, 16, 8, 3, 0x00AAFF);
        // drawRectWithBorder(dc, 126, 75, 32, 32, 16, 10, Graphics.COLOR_LT_GRAY);

        // Drawing of a smaller sized GoPro at the top of a 240x240 screen
        // 25 pixel higher than the medium sized GoPro
        drawRectWithBorder(dc, 104, 32, 13, 5, 2, 1, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, 95, 35, 50, 45, 8, 2, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, 117, 35, 29, 29, 8, 2, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, 101, 51, 12, 12, 3, 2, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, 102, 41, 10, 4, 1, 1, 0xFF5500);
        drawRectWithBorder(dc, 122, 67, 18, 7, 4, 1, 0x00AAFF);
        drawRectWithBorder(dc, 123, 42, 16, 16, 8, 5, Graphics.COLOR_LT_GRAY);
    }

    private function drawRectWithBorder(dc, x, y, w, h, rad, thick, color) as Void{
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x,y,w,h,rad);
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x+thick,y+thick,w-2*thick,h-2*thick,rad-thick);
    }
}

class GoProConnectDelegate extends WatchUi.BehaviorDelegate {
        var view;

    public function initialize(_view) {
        BehaviorDelegate.initialize();
        view = _view;
    }

    public function onTap(tap as ClickEvent) {
        var xy = tap.getCoordinates();
        if (xy[1]>160) {
            var _view = new PopUpView(MainResources.labels[UI_CONNECT][3], POP_INFO);
            WatchUi.pushView(_view, new PopUpDelegate(_view), WatchUi.SLIDE_UP);
        } else if (xy[1]>100) {
            var _view = new PopUpView(MainResources.labels[UI_CONNECT][4], POP_INFO);
            WatchUi.pushView(_view, new PopUpDelegate(_view), WatchUi.SLIDE_UP);
            BleInterface.scanForGoPros();
        }
        // mobile.connect();
        // mobile.send([COM_CONNECT, 0]);
        // var _view = new PopUpView("Connecting to GoPro ...", POP_INFO);
        // WatchUi.pushView(_view, new PopUpDelegate(_view), WatchUi.SLIDE_UP);
        // var _view = new GoProRemoteView();
        // WatchUi.pushView(_view, new GoProRemoteDelegate(_view), WatchUi.SLIDE_LEFT);
        return true;
    }
}