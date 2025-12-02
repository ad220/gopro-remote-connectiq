import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

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

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    public enum MenuId {
        MAIN,
        CAMERA,
        PRESET,
    }

    private var menuId as MenuId;
    private var items as Array<SettingsMenuItem>;
    private var viewController as ViewController;

    public function initialize(menu as CustomMenu, menuId as MenuId, items as Array<SettingsMenuItem>) {
        Menu2InputDelegate.initialize();

        self.menuId = menuId;
        self.items = items;
        self.viewController = getApp().viewController;

        var title = menuId == CAMERA ? loadResource(Rez.Strings.GoPro) : loadResource(Rez.Strings.Settings);
        menu.setTitle(new OptionPickerTitle(title));
        
        if (menuId != CAMERA) {
            if (menuId == MAIN) {
                var labels = [Rez.Strings.Cinema, Rez.Strings.Sport, Rez.Strings.Eco, Rez.Strings.Manually, Rez.Strings.SaveP7];
                var icons = [Rez.Drawables.Cinema, Rez.Drawables.Sport, Rez.Drawables.Eco, Rez.Drawables.Camera, Rez.Drawables.Save];
                for (var id=0; id<5; id++) {
                    items.add(new SettingsMenuItem(menuId, id as Char, labels[id], icons[id]));
                }
            }
            for (var id=0; id < (menuId==PRESET ? 3 : 5); id++) {
                menu.addItem(items[id]);
            }
        } else {
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.RESOLUTION as Char, Rez.Strings.Resolution, Rez.Drawables.Resolution));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.RATIO as Char, Rez.Strings.Ratio, Rez.Drawables.Ratio));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.LENS as Char, Rez.Strings.Lens, Rez.Drawables.Lens));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.FRAMERATE as Char, Rez.Strings.Framerate, Rez.Drawables.Framerate));
        }
    }

    public function onSelect(item) {
        var id = item.getId() as Number;
        
        if (menuId == CAMERA) {
            var newMenu = new CustomMenu((0.1*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.30*ICM.screenH).toNumber()});
            viewController.push(newMenu, new SettingPickerDelegate(newMenu, id as GoProSettings.SettingId), SLIDE_UP);
        } else if (id == SettingsMenuItem.MANUALLY) {
            var newMenu = new CustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, null);
            viewController.push(newMenu, new SettingsMenuDelegate(newMenu, CAMERA, []), SLIDE_LEFT);
        } else if (id == SettingsMenuItem.SAVEAS) {
            var newMenu = new CustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, null);
            viewController.switchTo(newMenu, new SettingsMenuDelegate(newMenu, PRESET, items), SLIDE_LEFT);
        } else if (menuId == PRESET) {
            ((item as SettingsMenuItem).gopro as GoProPreset).sync();
            unsubscribeAvailable();
            viewController.pop(SLIDE_DOWN);
        } else {
            getApp().gopro.sendPreset((item as SettingsMenuItem).gopro as GoProPreset);
            unsubscribeAvailable();
            viewController.pop(SLIDE_DOWN);
        }
    }

    public function onBack() as Void {
        if (menuId==MAIN) {
            unsubscribeAvailable();
        }
        viewController.pop(SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }

    (:inline)
    private function unsubscribeAvailable() as Void {
        getApp().gopro.subscribeChanges(GoProDelegate.UNREGISTER_AVAILABLE, [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE]b);
    }
}