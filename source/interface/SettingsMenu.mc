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
    private var gopro as GoProPreset?;


    public function initialize(menuId as MenuId, itemId as Char, gopro as GoProSettings?) {
        self.menuId = menuId;
        self.gopro = gopro;
        loadResources(menuId, itemId);

        if (menuId==MAIN and itemId<3) {
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
            dc.drawText(m_halfW+22*ICM.kMult, m_halfH-14*ICM.kMult, ICM.adaptFontMid(), label, ICM.JTEXT_MID);
            dc.drawText(m_halfW+22*ICM.kMult, m_halfH+16*ICM.kMult, ICM.adaptFontSmall(), \
                        isMenuCamera ? GoProSettings.getLabel(id as GoProSettings.SettingId, gopro.getSetting(id as GoProSettings.SettingId)) \
                                     : gopro.getDescription(), ICM.JTEXT_MID);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(m_halfW-36*ICM.kMult, m_halfH+2*ICM.kMult, m_halfW+80*ICM.kMult, m_halfH+2*ICM.kMult);
        } else {
            dc.drawText(m_halfW+22*ICM.kMult, m_halfH, ICM.adaptFontMid(), label, ICM.JTEXT_MID);
        }
    }

    public function getPreset() as GoProPreset {
        return gopro;
    }

    private function loadResources(menuId as MenuId, item as Char) as Void {
        if (menuId==MAIN) {
            switch (item as MenuItemId) {
                case PRESET1:
                    label = WatchUi.loadResource(Rez.Strings.Cinema);
                    icon = WatchUi.loadResource(Rez.Drawables.Cinema);
                    break;
                case PRESET2:
                    label = WatchUi.loadResource(Rez.Strings.Sport);
                    icon = WatchUi.loadResource(Rez.Drawables.Sport);
                    break;
                case PRESET3:
                    label = WatchUi.loadResource(Rez.Strings.Eco);
                    icon = WatchUi.loadResource(Rez.Drawables.Eco);
                    break;
                case MANUALLY:
                    label = WatchUi.loadResource(Rez.Strings.Manually);
                    icon = WatchUi.loadResource(Rez.Drawables.Camera);
                    break;
                case SAVEAS:
                    label = WatchUi.loadResource(Rez.Strings.SaveP7);
                    icon = WatchUi.loadResource(Rez.Drawables.Edit);
                    break;
                default:
                    System.println("Unknown Editable id: "+item);
                    throw new Exception();
            } 
        } else if (menuId==PRESET) {
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

    private var menuId as SettingsMenuItem.MenuId;
    private var gopro as GoProCamera;
    private var items as Array<SettingsMenuItem>;
    private var viewController as ViewController;

    public function initialize(menu as CustomMenu, menuId as SettingsMenuItem.MenuId, gopro as GoProCamera, items as Array<SettingsMenuItem>, viewController as ViewController) {
        Menu2InputDelegate.initialize();

        self.menuId = menuId;
        self.gopro = gopro;
        self.items = items;
        self.viewController = viewController;

        var title = menuId == SettingsMenuItem.CAMERA ? "GoPro" : WatchUi.loadResource(Rez.Strings.Settings);
        menu.setTitle(new OptionPickerTitle(title));
        
        if (menuId != SettingsMenuItem.CAMERA) {
            if (menuId == SettingsMenuItem.MAIN) {
                for (var itemId=0 as Char; itemId<5; itemId++) {
                    items.add(new SettingsMenuItem(menuId, itemId, null));
                }
            }
            for (var itemId=0; itemId < (menuId==SettingsMenuItem.PRESET ? 3 : 5); itemId++) {
                menu.addItem(items[itemId]);
            }
        } else {
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.RESOLUTION as Char, gopro));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.RATIO as Char, gopro));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.LENS as Char, gopro));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.FRAMERATE as Char, gopro));
        }
    }

    public function onSelect(item) {
        var id = item.getId() as Number;
        if (menuId == SettingsMenuItem.CAMERA) {
            var newMenu = new CustomMenu((70*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {});
            viewController.push(newMenu, new SettingPickerDelegate(newMenu, id as GoProSettings.SettingId, gopro, viewController), WatchUi.SLIDE_UP);
        } else if (id == SettingsMenuItem.MANUALLY) {
            var newMenu = new CustomMenu((80*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {});
            viewController.push(newMenu, new SettingsMenuDelegate(newMenu, SettingsMenuItem.CAMERA, gopro, [], viewController), WatchUi.SLIDE_LEFT);
        } else if (id == SettingsMenuItem.SAVEAS) {
            var newMenu = new CustomMenu((80*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {});
            viewController.switchTo(newMenu, new SettingsMenuDelegate(newMenu, SettingsMenuItem.PRESET, gopro, items, viewController), WatchUi.SLIDE_LEFT);
        } else if (menuId == SettingsMenuItem.PRESET) {
            (item as SettingsMenuItem).getPreset().sync(gopro);
            viewController.pop(WatchUi.SLIDE_DOWN);
        } else {
            gopro.sendPreset((item as SettingsMenuItem).getPreset());
            viewController.pop(WatchUi.SLIDE_DOWN);
        }
    }

    public function onBack() as Void {
        viewController.pop(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}