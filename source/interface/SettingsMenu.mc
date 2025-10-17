import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

using InterfaceComponentsManager as ICM;

class SettingsMenuItem extends WatchUi.CustomMenuItem {

    public enum MenuId {
        MAIN,
        CAMERA,
        PRESET,
    }

    public enum MenuItemId {
        PRESET1,
        PRESET2,
        PRESET3,
        MANUALLY,
        SAVEAS,
    }

    private var menuId as MenuId;
    private var label as String?;
    private var icon as BitmapResource?;
    
    public var gopro as GoProSettings?;


    public function initialize(menuId as MenuId, itemId as Char) {
        self.menuId = menuId;
        loadResources(menuId, itemId);

        if (menuId == CAMERA) {
            self.gopro = getApp().gopro;
        } else if (itemId<3) {
            self.gopro = new GoProPreset(itemId);
        }

        CustomMenuItem.initialize(itemId, {});
    }

    public function draw(dc as Dc) as Void {
        var m_halfW = dc.getWidth()/2;
        var m_halfH = dc.getHeight()/2;
        var id = getId() as Char;
        var isMenuCamera = menuId == CAMERA;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(m_halfW-100*ICM.kMult, m_halfH-30*ICM.kMult, 200*ICM.kMult, 60*ICM.kMult, 30*ICM.kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawBitmap(m_halfW-84*ICM.kMult-ICM.imgOff, m_halfH-14*ICM.kMult-ICM.imgOff, icon);
        
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
            dc.drawText(m_halfW+22*ICM.kMult, m_halfH-14*ICM.kMult, ICM.adaptFontMid(), label, ICM.JTEXT_MID);
            dc.drawText(m_halfW+22*ICM.kMult, m_halfH+16*ICM.kMult, ICM.adaptFontSmall(), subText, ICM.JTEXT_MID);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(m_halfW-36*ICM.kMult, m_halfH+2*ICM.kMult, m_halfW+80*ICM.kMult, m_halfH+2*ICM.kMult);
        } else {
            dc.drawText(m_halfW+22*ICM.kMult, m_halfH, ICM.adaptFontMid(), label, ICM.JTEXT_MID);
        }
    }

    private function loadResources(menuId as MenuId, item as Char) as Void {
        if (menuId==MAIN) {
            switch (item as MenuItemId) {
                case PRESET1:
                    label = loadResource(Rez.Strings.Cinema);
                    icon = loadResource(Rez.Drawables.Cinema);
                    break;
                case PRESET2:
                    label = loadResource(Rez.Strings.Sport);
                    icon = loadResource(Rez.Drawables.Sport);
                    break;
                case PRESET3:
                    label = loadResource(Rez.Strings.Eco);
                    icon = loadResource(Rez.Drawables.Eco);
                    break;
                case MANUALLY:
                    label = loadResource(Rez.Strings.Manually);
                    icon = loadResource(Rez.Drawables.Camera);
                    break;
                case SAVEAS:
                    label = loadResource(Rez.Strings.SaveP7);
                    icon = loadResource(Rez.Drawables.Edit);
                    break;
                default:
                    System.println("Unknown Editable id: "+item);
                    throw new Exception();
            } 
        } else if (menuId==PRESET) {
            System.println("SettingsItemId PRESET should not be used to loadResources");
            throw new Exception();
        } else {
            switch (item as GoProSettings.SettingId) {
                case GoProSettings.RESOLUTION:
                    label = loadResource(Rez.Strings.Resolution);
                    icon = loadResource(Rez.Drawables.Resolution);
                    break;
                case GoProSettings.RATIO:
                    label = loadResource(Rez.Strings.Ratio);
                    icon = loadResource(Rez.Drawables.Ratio);
                    break;
                case GoProSettings.LENS:
                    label = loadResource(Rez.Strings.Lens);
                    icon = loadResource(Rez.Drawables.Lens);
                    break;
                case GoProSettings.FRAMERATE:
                    label = loadResource(Rez.Strings.Framerate);
                    icon = loadResource(Rez.Drawables.Framerate);
                    break;
                default:
                    System.println("Unknown Setting id");
                    throw new Exception();
            }
        }
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var menuId as SettingsMenuItem.MenuId;
    private var items as Array<SettingsMenuItem>;
    private var viewController as ViewController;

    public function initialize(menu as CustomMenu, menuId as SettingsMenuItem.MenuId, items as Array<SettingsMenuItem>) {
        Menu2InputDelegate.initialize();

        self.menuId = menuId;
        self.items = items;
        self.viewController = getApp().viewController;

        var title = menuId == SettingsMenuItem.CAMERA ? loadResource(Rez.Strings.GoPro) : loadResource(Rez.Strings.Settings);
        menu.setTitle(new OptionPickerTitle(title));
        
        if (menuId != SettingsMenuItem.CAMERA) {
            if (menuId == SettingsMenuItem.MAIN) {
                for (var itemId=0 as Char; itemId<5; itemId++) {
                    items.add(new SettingsMenuItem(menuId, itemId));
                }
            }
            for (var itemId=0; itemId < (menuId==SettingsMenuItem.PRESET ? 3 : 5); itemId++) {
                menu.addItem(items[itemId]);
            }
        } else {
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.RESOLUTION as Char));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.RATIO as Char));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.LENS as Char));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.FRAMERATE as Char));
        }
    }

    public function onSelect(item) {
        var id = item.getId() as Number;
        if (menuId == SettingsMenuItem.CAMERA) {
            var newMenu = new CustomMenu((50*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {:titleItemHeight => (80*ICM.kMult).toNumber()});
            viewController.push(newMenu, new SettingPickerDelegate(newMenu, id as GoProSettings.SettingId), SLIDE_UP);
        } else if (id == SettingsMenuItem.MANUALLY) {
            var newMenu = new CustomMenu((80*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {});
            viewController.push(newMenu, new SettingsMenuDelegate(newMenu, SettingsMenuItem.CAMERA, []), SLIDE_LEFT);
        } else if (id == SettingsMenuItem.SAVEAS) {
            var newMenu = new CustomMenu((80*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {});
            viewController.switchTo(newMenu, new SettingsMenuDelegate(newMenu, SettingsMenuItem.PRESET, items), SLIDE_LEFT);
        } else if (menuId == SettingsMenuItem.PRESET) {
            ((item as SettingsMenuItem).gopro as GoProPreset).sync();
            viewController.pop(SLIDE_DOWN);
        } else {
            getApp().gopro.sendPreset((item as SettingsMenuItem).gopro as GoProPreset);
            viewController.pop(SLIDE_DOWN);
        }
    }

    public function onBack() as Void {
        viewController.pop(SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}