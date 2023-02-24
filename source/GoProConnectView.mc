import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class GoProConnectView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        GoProResources.loadLabels(CONNECT);
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(0x00AAFF, Graphics.COLOR_BLACK);
        dc.clear();
        dc.fillRoundedRectangle(45, 170, 150, 40, 20);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(120, 190, GoProResources.fontSmall, GoProResources.labels[CONNECT] as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawRectWithBorder(dc, 88, 57, 26, 10, 4, 2, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, 69, 62, 102, 92, 16, 4, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, 113, 62, 58, 58, 16, 4, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, 80, 95, 25, 25, 6, 3, Graphics.COLOR_DK_GRAY);
        drawRectWithBorder(dc, 81, 74, 20, 9, 4, 3, 0xFF5500);
        drawRectWithBorder(dc, 124, 127, 36, 16, 8, 3, 0x00AAFF);
        drawRectWithBorder(dc, 126, 75, 32, 32, 16, 10, Graphics.COLOR_LT_GRAY);
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
        var _view = new GoProRemoteView();
        WatchUi.pushView(_view, new GoProRemoteDelegate(_view), WatchUi.SLIDE_LEFT);
        return true;
    }

/*     public function onSelect() {
        WatchUi.pushView(new PresetPickerMenu(), new PresetPickerDelegate(), WatchUi.SLIDE_UP);
        return false;
    } */
}