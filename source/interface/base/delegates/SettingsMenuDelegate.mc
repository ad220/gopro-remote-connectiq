import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;


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
        menu.setTitle(new PickerTitle(title as String));
        
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
            getApp().gopro.subscribeChanges(
                CameraDelegate.REGISTER_AVAILABLE,
                [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE]b
            );

            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.RESOLUTION as Char, Rez.Strings.Resolution, Rez.Drawables.Resolution));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.RATIO as Char, Rez.Strings.Ratio, Rez.Drawables.Ratio));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.LENS as Char, Rez.Strings.Lens, Rez.Drawables.Lens));
            menu.addItem(new SettingsMenuItem(menuId, GoProSettings.FRAMERATE as Char, Rez.Strings.Framerate, Rez.Drawables.Framerate));
        }
    }

    public function onSelect(item) {
        var id = item.getId() as Number;
        
        if (menuId == CAMERA) {
            var newMenu = new CustomMenu((0.1*Screen.HEIGHT).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.30*Screen.HEIGHT).toNumber()});
            viewController.push(newMenu, new SettingPickerDelegate(newMenu, id as GoProSettings.SettingId), SLIDE_UP);
        } else if (id == SettingsMenuItem.MANUALLY) {
            var newMenu = new CustomMenu((0.15*Screen.HEIGHT).toNumber()<<1, Graphics.COLOR_BLACK, null);
            viewController.switchTo(newMenu, new SettingsMenuDelegate(newMenu, CAMERA, []), SLIDE_LEFT);
        } else if (id == SettingsMenuItem.SAVEAS) {
            var newMenu = new CustomMenu((0.15*Screen.HEIGHT).toNumber()<<1, Graphics.COLOR_BLACK, null);
            viewController.switchTo(newMenu, new SettingsMenuDelegate(newMenu, PRESET, items), SLIDE_LEFT);
        } else if (menuId == PRESET) {
            ((item as SettingsMenuItem).gopro as GoProPreset).sync();
            toRemote();
        } else {
            getApp().gopro.sendPreset((item as SettingsMenuItem).gopro as GoProPreset);
            toRemote();
        }
    }

    public function onBack() as Void {
        if (menuId==MAIN) {
            toRemote();
        }
        else if (menuId == CAMERA) {
            unsubscribeAvailable();
            var menu = new CustomMenu((0.15*Screen.HEIGHT).toNumber()<<1, Graphics.COLOR_BLACK, {});
            var delegate = new SettingsMenuDelegate(menu, SettingsMenuDelegate.MAIN, []);
            menu.setFocus(3);
            viewController.switchTo(menu, delegate, SLIDE_DOWN);
        } else {
            viewController.pop(SLIDE_DOWN);
        }
    }

    private function toRemote() as Void {
        viewController.switchTo(new RemoteView(), new RemoteDelegate(), WatchUi.SLIDE_RIGHT);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }

    private function unsubscribeAvailable() as Void {
        getApp().gopro.subscribeChanges(
            CameraDelegate.UNREGISTER_AVAILABLE,
            [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE]b
        );
    }

    (:debug)
    public function getId() as MenuId {
        return menuId;
    }
}