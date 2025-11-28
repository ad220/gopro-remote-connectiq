import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

using InterfaceComponentsManager as ICM;


class NotifView extends WatchUi.View {

    public enum NotifType {
        NOTIF_INFO,
        NOTIF_ERROR
    }

    private var msg as String;
    private var type as NotifType;

    function initialize(msg as String or ResourceId, type as NotifType) {
        View.initialize();
        
        self.msg = msg instanceof String ? msg : loadResource(msg);
        self.type = type;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(type == NOTIF_INFO ? Rez.Layouts.NotifInfoLayout(dc) : Rez.Layouts.NotifErrorLayout(dc));
        (findDrawableById("NotifMsg") as Text).setText(msg);
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