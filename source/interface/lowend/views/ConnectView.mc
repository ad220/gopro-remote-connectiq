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
        dc.setPenWidth(0.05*Screen.WIDTH);

        // Draw button background and inner arc
        dc.setColor(0x00AAFF, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(0.2*Screen.WIDTH, 0.7*Screen.HEIGHT, 0.6*Screen.WIDTH, 0.16*Screen.HEIGHT, 255);
        dc.drawArc(0.33*Screen.WIDTH, 0.58*Screen.HEIGHT, 0.13*Screen.WIDTH, Graphics.ARC_CLOCKWISE, 90, 0);
        
        // Draw middle arc
        dc.setColor(0x0055AA, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(0.33*Screen.WIDTH, 0.58*Screen.HEIGHT, 0.23*Screen.WIDTH, Graphics.ARC_CLOCKWISE, 90, 0);

        // Draw outer arc
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(0.33*Screen.WIDTH, 0.58*Screen.HEIGHT, 0.33*Screen.WIDTH, Graphics.ARC_CLOCKWISE, 90, 0);

        // Draw button label and logo circle
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.5*Screen.WIDTH, 0.78*Screen.HEIGHT, ICM.fontSmall, label, ICM.JTEXT_MID);
        dc.fillCircle(0.34*Screen.WIDTH, 0.57*Screen.HEIGHT, 0.042*Screen.WIDTH);
    }
}
