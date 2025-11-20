import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

using InterfaceComponentsManager as ICM;


class NotifView extends WatchUi.View {

    public enum NotifType {
        NOTIF_INFO,
        NOTIF_ERROR
    }

    private var message as String;
    private var type as NotifType;

    function initialize(message as String, type as NotifType) {
        View.initialize();
        
        self.message = message;
        self.type = type;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(type == NOTIF_INFO ? Rez.Layouts.NotifInfoLayout(dc) : Rez.Layouts.NotifErrorLayout(dc));
        (findDrawableById("NotifMsg") as Text).setText(message);
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