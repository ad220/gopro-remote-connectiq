import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;
using ErrorManager as EM;


class ProtuneMenuItem extends WatchUi.CustomMenuItem {

    public function initialize(settingId as GoProSettings.SettingId, label as ResourceId) {
        CustomMenuItem.initialize(settingId, {});

        mLabel = loadResource(label) as String;
    }

    public function updateValue() as Void {
        var subLabel = GoProSettings.getLabel(mIdentifier as GoProSettings.SettingId, null);
        if (subLabel instanceof ResourceId) { subLabel = loadResource(subLabel) as String; }
        mSubLabel = subLabel;
    }

    public function draw(dc as Dc) as Void {
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(0.05*width, 0.125*height, 0.9*width, 0.75*height, 0.38*height);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(0.5*width, 0.325*height, ICM.fontSmall, mLabel, ICM.JTEXT_MID);
        dc.drawText(0.5*width, 0.675*height, ICM.fontTiny, mSubLabel, ICM.JTEXT_MID);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(0.016*height);
        dc.drawLine(0.15*width, 0.525*height, 0.85*width, 0.525*height);
    }
}
