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

        var titleId;
        var comparator = null;
        var items = gopro.getAvailableSettings(setting);
        var selected = gopro.getSetting(setting);
        switch (setting) {
            case GoProSettings.RESOLUTION:
                titleId = Rez.Strings.Resolution;
                comparator = new ResolutionComparator();
                break;
            case GoProSettings.RATIO:
                titleId = Rez.Strings.Ratio;
                comparator = new ResolutionComparator();
                break;
            case GoProSettings.LENS:
                titleId = Rez.Strings.Lens;
                comparator = new LensComparator();
                break;
            case GoProSettings.FRAMERATE:
                titleId = Rez.Strings.Framerate;
                comparator = new FramerateComparator();
                break;
            case GoProSettings.LED:
                titleId = Rez.Strings.Led;
                break;
            case GoProSettings.HYPERSMOOTH:
                titleId = Rez.Strings.HyperSmooth;
                break;
            default:
                System.println("Unknown Setting id");
                throw new Exception();
        }
        menu.setTitle(new OptionPickerTitle(titleId));
        items.sort(comparator);
        for (var i=0; i<items.size(); i++) {
            menu.addItem(new OptionPickerItem(GoProSettings.getLabel(setting, items[i]), items[i] as Char, selected));
        }

        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        gopro.sendSetting(setting==GoProSettings.RATIO ? GoProSettings.RESOLUTION : setting, item.getId() as Char);
        (item as OptionPickerItem).select();
        requestUpdate();
    }

    public function onBack() as Void {
        viewController.pop(SLIDE_RIGHT);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}
