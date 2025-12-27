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
        
        self.msg = msg instanceof String ? msg : loadResource(msg) as String;
        self.type = type;
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var accentColor = type == NOTIF_ERROR ? 0xFF5500 : Graphics.COLOR_BLACK;
        var textIcon = type == NOTIF_ERROR ? "!" : "i";

        dc.setColor(Graphics.COLOR_WHITE, accentColor);
        dc.clear();
        dc.drawText(ICM.halfW, ICM.halfH, ICM.fontSmall, msg, ICM.JTEXT_MID);
        dc.fillCircle(ICM.halfW, 0.3*ICM.screenH, 0.08*ICM.screenW);
        
        dc.setColor(accentColor, Graphics.COLOR_WHITE);
        dc.drawText(ICM.halfW, 0.3*ICM.screenH, ICM.fontMedium, textIcon, ICM.JTEXT_MID);
    }
}
