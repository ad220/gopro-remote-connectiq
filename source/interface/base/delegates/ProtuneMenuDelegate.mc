import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;
using ErrorManager as EM;

class ProtuneMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var menu as ProtuneMenu;

    public function initialize(menu as ProtuneMenu) {
        Menu2InputDelegate.initialize();
        self.menu = menu;

        var gopro = getApp().gopro;
        gopro.queryValues(GoProDecoder.REGISTER_SETTING, menu.ids);
        gopro.queryValues(GoProDecoder.GET_AVAILABLE, menu.ids);
    }

    public function update() as Void {
        menu.update();
        WatchUi.requestUpdate();
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as GoProSettings.SettingId;
        if (getApp().gopro.getSetting(id) != null) {
            ICM.toggleOrPick(id);
        }
    }

    public function onBack() as Void {
        var app = getApp();
        app.gopro.queryValues(GoProDecoder.UNREGISTER_SETTING, menu.ids);
        app.viewController.pop(SLIDE_RIGHT);
    }
}