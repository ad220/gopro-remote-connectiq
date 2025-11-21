import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;


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
        menu.setTitle(new PickerTitle(title));
        
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
            var newMenu = new CustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {});
            viewController.push(newMenu, new SettingsMenuDelegate(newMenu, CAMERA, []), SLIDE_LEFT);
        } else if (id == SettingsMenuItem.SAVEAS) {
            var newMenu = new CustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {});
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
        getApp().gopro.subscribeChanges(
            CameraDelegate.UNREGISTER_AVAILABLE,
            [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE]b
        );
    }
}