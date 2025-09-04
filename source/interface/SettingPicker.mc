import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;


class SettingPickerDelegate extends WatchUi.Menu2InputDelegate {

    private var setting as GoProSettings.SettingId;
    private var viewController as ViewController;
    private var gopro as GoProCamera;


    public function initialize(menu as CustomMenu, setting as GoProSettings.SettingId, gopro as GoProCamera, viewController as ViewController) {

        self.setting = setting;
        self.gopro = gopro;
        self.viewController = viewController;

        var title;
        var items = gopro.getAvailableSettings(setting);
        var selected = gopro.getSetting(setting);
        switch (setting) {
            case GoProSettings.RESOLUTION:
                title = WatchUi.loadResource(Rez.Strings.Resolution);
                items.sort(new ResolutionComparator() as Lang.Comparator);
                break;
            case GoProSettings.RATIO:
                title = WatchUi.loadResource(Rez.Strings.Ratio);
                System.println(items);
                items.sort(new ResolutionComparator() as Lang.Comparator);
                break;
            case GoProSettings.LENS:
                title = WatchUi.loadResource(Rez.Strings.Lens);
                items.sort(new LensComparator() as Lang.Comparator);
                break;
            case GoProSettings.FRAMERATE:
                title = WatchUi.loadResource(Rez.Strings.Framerate);
                items.sort(new FramerateComparator() as Lang.Comparator);
                break;
            default:
                System.println("Unknown Setting id");
                throw new Exception();
        }
        menu.setTitle(new CustomMenuTitle(title));
        for (var i=0; i<items.size(); i++) {
            menu.addItem(new OptionPickerItem(GoProSettings.getLabel(setting, items[i]), items[i] as Char, selected));
        }

        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        gopro.sendSetting(setting==GoProSettings.RATIO ? GoProSettings.RESOLUTION : setting, item.getId() as Char);
        (item as OptionPickerItem).select();
        WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        viewController.pop(WatchUi.SLIDE_RIGHT);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}
