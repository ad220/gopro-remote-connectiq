import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

class ProtuneMenuDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize(menu as CustomMenu) {
        Menu2InputDelegate.initialize();

        menu.setTitle(new PickerTitle(Rez.Strings.Protune));

        var ids = [
            GoProSettings.PROTUNE,
            GoProSettings.WHITE_BL,
            GoProSettings.COLOR,
            GoProSettings.SHARPNESS,
            GoProSettings.EV_COMP,
            GoProSettings.ISO_MAX,
            GoProSettings.ISO_MIN
        ];
        var labels = [
            Rez.Strings.Protune,
            Rez.Strings.WhiteBalance,
            Rez.Strings.EvComp,
            Rez.Strings.Color,
            Rez.Strings.Sharpness,
            Rez.Strings.IsoMax,
            Rez.Strings.IsoMin,
        ];
        
        for (var i=0; i<6; i++) { menu.addItem(new ProtuneMenuItem(ids[i], labels[i])); }
    }

    public function onSelect(item) {
        var id = item.getId() as GoProSettings.SettingId;
        var newMenu = ICM.newCustomMenu(0.1, 0.3);
        getApp().viewController.push(newMenu, new SettingPickerDelegate(newMenu, id), SLIDE_LEFT);
    }

    public function onBack() as Void {
        getApp().viewController.pop(SLIDE_RIGHT);
    }
}