import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;

class NotifView extends WatchUi.View{

    public enum NotifType {
        NOTIF_INFO,
        NOTIF_ERROR
    }

    private var message as String;
    private var type as Number;


    function initialize(message as String, type as NotifType) {
        self.message = message;
        self.type = type;
        View.initialize();
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

    function onHide() as Void {
    }

}

class NotifDelegate extends WatchUi.BehaviorDelegate {

    private var stillExists as Boolean;
    private var timer as Timer.Timer;

    public function initialize() {
        self.stillExists = true;
        self.timer = new Timer.Timer();
        self.timer.start(method(:pop), 4000, false);

        BehaviorDelegate.initialize();
    }

    public function onBack() {
        pop();
        return true;
    }

    public function pop() as Void {
        if (stillExists) {
            stillExists = false;
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }
}