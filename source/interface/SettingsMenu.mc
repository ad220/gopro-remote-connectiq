import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

using InterfaceComponentsManager as ICM;


// TODO: replace preset edit with camera settings save as preset
class SettingsMenu extends WatchUi.CustomMenu {
    public enum SettingsMenuType {
        SM_MENU,
        SM_PSETS,
        SM_EDIT
    }

    public enum Menus {
        SETTINGS,
        PRESETS,
        EDIT
    }


    public function initialize(menuType as SettingsMenuType, presetId as Number, gopro as GoProCamera?) {
        var title;
        if (menuType == SM_EDIT) {
            title = "GoPro";
        } else {
            title = WatchUi.loadResource(Rez.Strings.Settings);
        }

        CustomMenu.initialize((80*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {:title=> new CustomMenuTitle(title)});
        
        if (menuType == SM_EDIT) {
            CustomMenu.addItem(new SettingsMenuItem(-1, GoProSettings.RESOLUTION, gopro));
            CustomMenu.addItem(new SettingsMenuItem(-1, GoProSettings.RATIO, gopro));
            CustomMenu.addItem(new SettingsMenuItem(-1, GoProSettings.LENS, gopro));
            CustomMenu.addItem(new SettingsMenuItem(-1, GoProSettings.FRAMERATE, gopro));
        } else {
            for (var id=0; id < (menuType==SM_PSETS ? 3 : 5); id++) { // id => presetId
                CustomMenu.addItem(new SettingsMenuItem(id, -1, null)); // i => enum Editables
            }
        }
    }
}

class SettingsMenuItem extends WatchUi.CustomMenuItem {

    public enum Editables {
        PSET1,
        PSET2,
        PSET3,
        CAM,
        SAVEP7
    }


    private var presetId as Editables;
    private var label as String?;
    private var icon as BitmapResource?;
    private var gp as GoProPreset?;


    public function initialize(presetId, settingId, gopro) {
        self.presetId = presetId;

        var itemId;
        if (presetId == -1) {
            itemId = settingId;
            loadResources(SettingsMenu.SM_EDIT, itemId);
            self.gp = gopro;
        } else {
            itemId = presetId;
            loadResources(SettingsMenu.SM_MENU, itemId);
            if (presetId < 3) {self.gp = new GoProPreset(presetId);}
        }
        CustomMenuItem.initialize(itemId, {});
    }

    public function draw(dc as Dc) as Void {
        var m_halfW = dc.getWidth()/2;
        var m_halfH = dc.getHeight()/2;
        var isEdit = (presetId == -1);
        var id = getId() as Number;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(m_halfW-100*ICM.kMult, m_halfH-30*ICM.kMult, 200*ICM.kMult, 60*ICM.kMult, 30*ICM.kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawBitmap(m_halfW-84*ICM.kMult-ICM.imgOff, m_halfH-14*ICM.kMult-ICM.imgOff, icon);
        
        if (isEdit or presetId<3) {
            dc.drawText(m_halfW+22*ICM.kMult, m_halfH-14*ICM.kMult, ICM.adaptFontMid(), label, ICM.JTEXT_MID);
            dc.drawText(m_halfW+22*ICM.kMult, m_halfH+16*ICM.kMult, ICM.adaptFontSmall(), isEdit ? GoProSettings.getLabel(id, gp.getSetting(id)) : gp.getDescription(), ICM.JTEXT_MID);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(m_halfW-36*ICM.kMult, m_halfH+2*ICM.kMult, m_halfW+80*ICM.kMult, m_halfH+2*ICM.kMult);
        } else {
            dc.drawText(m_halfW+22*ICM.kMult, m_halfH, ICM.adaptFontMid(), label, ICM.JTEXT_MID);
        }
    }

    public function getPreset() as GoProPreset {
        return gp;
    }

    private function loadResources(menuType as SettingsMenu.SettingsMenuType, item as Number) as Void {
        if (menuType==SettingsMenu.SM_MENU) {
            switch (item as Editables) {
                case PSET1:
                    label = WatchUi.loadResource(Rez.Strings.Cinema);
                    icon = WatchUi.loadResource(Rez.Drawables.Cinema);
                    break;
                case PSET2:
                    label = WatchUi.loadResource(Rez.Strings.Sport);
                    icon = WatchUi.loadResource(Rez.Drawables.Sport);
                    break;
                case PSET3:
                    label = WatchUi.loadResource(Rez.Strings.Eco);
                    icon = WatchUi.loadResource(Rez.Drawables.Eco);
                    break;
                case CAM:
                    label = WatchUi.loadResource(Rez.Strings.Manually);
                    icon = WatchUi.loadResource(Rez.Drawables.Camera);
                    break;
                case SAVEP7:
                    label = WatchUi.loadResource(Rez.Strings.SaveP7);
                    icon = WatchUi.loadResource(Rez.Drawables.Edit);
                    break;
                default:
                    System.println("Unknown Editable id: "+item);
                    throw new Exception();
            } 
        } else if (menuType==SettingsMenu.SM_PSETS) {
            System.println("Editable SM_P7 should not be used");
            throw new Exception();
        } else {
            switch (item as GoProSettings.SettingId) {
                case GoProSettings.RESOLUTION:
                    label = WatchUi.loadResource(Rez.Strings.Resolution);
                    icon = WatchUi.loadResource(Rez.Drawables.Resolution);
                    break;
                case GoProSettings.RATIO:
                    label = WatchUi.loadResource(Rez.Strings.Ratio);
                    icon = WatchUi.loadResource(Rez.Drawables.Ratio);
                    break;
                case GoProSettings.LENS:
                    label = WatchUi.loadResource(Rez.Strings.Lens);
                    icon = WatchUi.loadResource(Rez.Drawables.Lens);
                    break;
                case GoProSettings.FRAMERATE:
                    label = WatchUi.loadResource(Rez.Strings.Framerate);
                    icon = WatchUi.loadResource(Rez.Drawables.Framerate);
                    break;
                default:
                    System.println("Unknown Setting id");
                    throw new Exception();
            }
        }
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var menuType as SettingsMenu.SettingsMenuType;
    private var gopro as GoProCamera;
    private var viewController as ViewController;

    public function initialize(menuType as SettingsMenu.SettingsMenuType, gopro as GoProCamera, viewController as ViewController) {
        self.menuType = menuType;
        self.gopro = gopro;
        self.viewController = viewController;
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        var id = item.getId() as Number;
        // WARNING: popping view unloads mandatory icons and loads unnecessary ones in simulator while the problem doesn't appear on device and lower (<4.1.7 beta) SDK versions
        // NOTE: issue unseen with SDK 6.3.0 and 7.3.0
        if (menuType == SettingsMenu.SM_EDIT) {
            viewController.push(new SettingEditMenu(id as GoProSettings.SettingId, gopro), new SettingEditDelegate(id as GoProSettings.SettingId, viewController, gopro), WatchUi.SLIDE_UP);
        } else {
            if (id == SettingsMenuItem.CAM) {
                viewController.switchTo(new SettingsMenu(SettingsMenu.SM_EDIT, id, gopro), new SettingsMenuDelegate(SettingsMenu.SM_EDIT, gopro, viewController), WatchUi.SLIDE_LEFT);
            } else if (id == SettingsMenuItem.SAVEP7) {
                viewController.push(new SettingsMenu(SettingsMenu.SM_PSETS, -1, gopro), new SettingsMenuDelegate(SettingsMenu.SM_PSETS, gopro, viewController), WatchUi.SLIDE_LEFT);
            } else if (menuType == SettingsMenu.SM_PSETS) {
                (item as SettingsMenuItem).getPreset().save();
                // Pop two views to remove old preset from menu memory
                viewController.pop(WatchUi.SLIDE_IMMEDIATE);
                viewController.pop(WatchUi.SLIDE_DOWN);
            } else {
                gopro.sendPreset((item as SettingsMenuItem).getPreset().getSettings());
                viewController.pop(WatchUi.SLIDE_DOWN);
            }
        }
    }

    public function onBack() as Void {
        viewController.pop(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}