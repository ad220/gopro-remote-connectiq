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
