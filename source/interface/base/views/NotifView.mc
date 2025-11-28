import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;


(:highend)
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
