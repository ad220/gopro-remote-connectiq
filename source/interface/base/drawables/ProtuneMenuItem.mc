import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;
using ErrorManager as EM;


class ProtuneMenuItem extends WatchUi.CustomMenuItem {

    private var title as String;

    public function initialize(settingId as GoProSettings.SettingId, label as ResourceId) {
        self.title = loadResource(label) as String;

        CustomMenuItem.initialize(settingId, {});
    }

    public function draw(dc as Dc) as Void {
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(0.05*width, 0.125*height, 0.9*width, 0.75*height, 0.38*height);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var id = getId() as GoProSettings.SettingId;
        var subText = GoProSettings.getLabel(id, null);

        dc.drawText(0.6*width, 0.325*height, ICM.fontSmall, title, ICM.JTEXT_MID);
        dc.drawText(0.6*width, 0.675*height, ICM.fontTiny, subText, ICM.JTEXT_MID);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(0.016*height);
        dc.drawLine(0.35*width, 0.525*height, 0.85*width, 0.525*height);
    }
}
