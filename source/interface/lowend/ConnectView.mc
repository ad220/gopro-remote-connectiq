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
        dc.setColor(0x00AAFF, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(0.2*width, 0.7*height, 0.6*width, 0.16*height, 255);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.5*width, 0.78*height, ICM.fontSmall, label, ICM.JTEXT_MID);
        dc.drawText(0.5*width, 0.45*width, ICM.fontMedium, loadResource(Rez.Strings.AppName), ICM.JTEXT_MID);
    }
}
