import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

(:lowend)
class ConnectView extends WatchUi.View {

    private var label as String;
    private var delegate as ConnectDelegate;

    function initialize(label as String, delegate as ConnectDelegate) {
        View.initialize();

        self.label = label;
        self.delegate = delegate;
    }

    function onShow() as Void {
        if (getApp().fromGlance) {
            delegate.onSelect();
        }
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.setPenWidth(0.05*ICM.screenW);

        // Draw button background and inner arc
        dc.setColor(0x00AAFF, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(0.2*width, 0.7*height, 0.6*width, 0.16*height, 255);
        dc.drawArc(0.33*ICM.screenW, 0.58*ICM.screenH, 0.13*ICM.screenW, Graphics.ARC_CLOCKWISE, 90, 0);
        
        // Draw middle arc
        dc.setColor(0x0055AA, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(0.33*ICM.screenW, 0.58*ICM.screenH, 0.23*ICM.screenW, Graphics.ARC_CLOCKWISE, 90, 0);

        // Draw outer arc
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(0.33*ICM.screenW, 0.58*ICM.screenH, 0.33*ICM.screenW, Graphics.ARC_CLOCKWISE, 90, 0);

        // Draw button label and logo circle
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.5*width, 0.78*height, ICM.fontSmall, label, ICM.JTEXT_MID);
        dc.fillCircle(0.34*ICM.screenW, 0.57*ICM.screenH, 0.042*ICM.screenW);
    }
}
