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
        dc.setColor(type ? 0xFF5500 : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, screenW, 90*kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(halfW, 20*kMult, 10*kMult);
        dc.drawText(halfW, 60*kMult, adaptFontSmall(), message, JTEXT_MID);
        dc.setColor(type ? 0xFF5500 : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(halfW, 20*kMult, adaptFontMid() , type ? "!" : "i", JTEXT_MID);
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
        WatchUi.popView(WatchUi.SLIDE_BLINK);
        return true;
    }

    public function fadeOut() as Void {
        WatchUi.popView(WatchUi.SLIDE_BLINK);
    }
}