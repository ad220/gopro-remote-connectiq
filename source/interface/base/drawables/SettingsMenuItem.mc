import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;


class SettingsMenuItem extends WatchUi.CustomMenuItem {

    public enum MenuItemId {
        PRESET1,
        PRESET2,
        PRESET3,
        MANUALLY,
        SAVEAS,
    }

    private var menuId as SettingsMenuDelegate.MenuId;
    private var label as String;
    private var icon as BitmapResource;
    
    public var gopro as GoProSettings?;


    public function initialize(menuId as SettingsMenuDelegate.MenuId, itemId as Char, labelId as ResourceId, iconId as ResourceId) {
        self.menuId = menuId;
        self.label = loadResource(labelId);
        self.icon = loadResource(iconId);

        if (menuId == SettingsMenuDelegate.CAMERA) {
            self.gopro = getApp().gopro;
        } else if (itemId<3) {
            self.gopro = new GoProPreset(itemId);
        }

        CustomMenuItem.initialize(itemId, {});
    }

    public function draw(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var id = getId() as Char;
        var isMenuCamera = menuId == SettingsMenuDelegate.CAMERA;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(0.05*width, 0.125*height, 0.9*width, 0.75*height, 0xFF);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawBitmap(0.125*width, 0.333*height, icon);
        
        if (isMenuCamera or id<3) {
            var subText;
            if (isMenuCamera) {
                subText = GoProSettings.getLabel(id as GoProSettings.SettingId, gopro.getSetting(id as GoProSettings.SettingId));
                if (subText instanceof ResourceId) {
                    subText = loadResource(subText);
                }
            } else {
                subText = gopro.getDescription();
            }
            dc.drawText(0.6*width, 0.325*height, ICM.fontSmall, label, ICM.JTEXT_MID);
            dc.drawText(0.6*width, 0.675*height, ICM.fontTiny, subText, ICM.JTEXT_MID);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(0.016*height);
            dc.drawLine(0.35*width, 0.525*height, 0.85*width, 0.525*height);
        } else {
            dc.drawText(0.6*width, 0.5*height, ICM.fontSmall, label, ICM.JTEXT_MID);
        }
    }

}
