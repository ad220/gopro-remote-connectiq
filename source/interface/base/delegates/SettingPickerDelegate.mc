import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

using ErrorManager as EM;


class SettingPickerDelegate extends WatchUi.Menu2InputDelegate {

    private var setting as GoProSettings.SettingId;


    public function initialize(menu as CustomMenu, setting as GoProSettings.SettingId) {

        self.setting = setting;

        var titleId;
        var comparator = null;
        var items = getApp().gopro.getAvailableSettings(setting);
        
        var selected = getApp().gopro.getSetting(setting);
        if (selected == null) {
            selected = 0xFF as Char;
            EM.raise(EM.ERR_CAM | EM.SUB_CAM_NULL | 0x00 << 16, setting, :WarningErr);
        }

        if      (setting == GoProSettings.RESOLUTION)   { titleId = Rez.Strings.Resolution;     comparator = new ResolutionComparator(); }
        else if (setting == GoProSettings.RATIO)        { titleId = Rez.Strings.Ratio;          comparator = new RatioComparator(); }
        else if (setting == GoProSettings.LENS)         { titleId = Rez.Strings.Lens; }
        else if (setting == GoProSettings.FRAMERATE)    { titleId = Rez.Strings.Framerate;      comparator = new FramerateComparator(); }
        else if (setting == GoProSettings.LED)          { titleId = Rez.Strings.Led; }
        else if (setting == GoProSettings.HYPERSMOOTH)  { titleId = Rez.Strings.HyperSmooth; }
        else {
            // System.println("[WARNING]   Unknown Setting id");
            EM.raise(EM.ERR_CAM | EM.SUB_CAM_ID | 0x01 << 16, setting, :CriticalErr);
            return;
        }

        menu.setTitle(new PickerTitle(titleId));
        Helper.sort(items as Array, comparator);
        for (var i=0; i<items.size(); i++) {
            menu.addItem(new PickerItem(GoProSettings.getLabel(setting, items[i]), items[i] as Char, selected));
        }
        menu.setFocus(items.indexOf(selected));

        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        getApp().gopro.sendSetting(setting==GoProSettings.RATIO ? GoProSettings.RESOLUTION : setting, item.getId() as Char);
        (item as PickerItem).select();
        requestUpdate();
    }

    public function onBack() as Void {
        getApp().viewController.pop(SLIDE_RIGHT);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }

    (:debug)
    public function getId() as GoProSettings.SettingId {
        return setting;
    }
}
