import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;

class PopUpView extends WatchUi.View{
    var message as String;
    var type as Number;

    function initialize(_message as String, _type as PopUpType) {
        message = _message;
        type = _type;
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // MainResources.load
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor([Graphics.COLOR_DK_GRAY, 0xFF5500][type], Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, 240, 90);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(120, 20, 10);
        dc.drawText(120, 60, MainResources.fontTiny, message, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor([Graphics.COLOR_DK_GRAY, 0xFF5500][type], Graphics.COLOR_TRANSPARENT);
        dc.drawText(120, 20, MainResources.fontSmall, ["i", "!"][type], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class PopUpDelegate extends WatchUi.BehaviorDelegate {
    var view as PopUpView;
    var timer as Timer.Timer;

    public function initialize(_view) {
        BehaviorDelegate.initialize();
        view = _view;
        timer = new Timer.Timer();
        timer.start(method(:fadeOut), 5000, false);
    }

    public function onBack() {
        timer.stop();
        WatchUi.popView(SLIDE_DOWN);
        return true;
    }

    public function fadeOut() as Void {
        WatchUi.popView(SLIDE_DOWN);
    }
}