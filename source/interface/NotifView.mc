import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

using InterfaceComponentsManager as ICM;


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
        dc.fillRectangle(0, 0, ICM.screenW, 90*ICM.kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(ICM.halfW, 20*ICM.kMult, 10*ICM.kMult);
        dc.drawText(ICM.halfW, 60*ICM.kMult, ICM.adaptFontSmall(), message, ICM.JTEXT_MID);
        dc.setColor(type ? 0xFF5500 : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ICM.halfW, 20*ICM.kMult, ICM.adaptFontMid() , type ? "!" : "i", ICM.JTEXT_MID);
    }

    function onHide() as Void {
    }

}

class NotifDelegate extends WatchUi.BehaviorDelegate {

    private var stillExists as Boolean;

    public function initialize() {
        self.stillExists = true;

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