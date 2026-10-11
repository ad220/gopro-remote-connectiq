import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

class RemoteMenuDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize(menu as Menu2) {
        Menu2InputDelegate.initialize();

        menu.setTitle(Rez.Strings.AdvancedSettings);

        var bmpOptions = {
            :locX   => LAYOUT_HALIGN_CENTER,
            :locY   => LAYOUT_VALIGN_CENTER
        };

        bmpOptions[:rezId] = Rez.Drawables.CaptureMode;
        var icon = new Bitmap(bmpOptions);
        var item = new IconMenuItem(Rez.Strings.SwitchMode, null, :switchMode, icon, null);
        menu.addItem(item);

        if (getApp().gopro.getId() < GoProCamera.GP_MAX) { return; }

        bmpOptions[:rezId] = Rez.Drawables.Protune;
        icon = new Bitmap(bmpOptions);
        item = new IconMenuItem(Rez.Strings.Protune, null, :protune, icon, null);
        menu.addItem(item);
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        var app = getApp();

        if      (id == :switchMode) {
            app.gopro.sendCommand(GoProCamera.LOAD_PGRP);
            onBack();
        }
        else if (id == :protune) {
            var newMenu = new ProtuneMenu();
            app.viewController.switchTo(newMenu, new ProtuneMenuDelegate(newMenu), SLIDE_LEFT);
        }
    }

    public function onBack() as Void {
        getApp().viewController.pop(SLIDE_RIGHT);
    }

    public function onBack() as Void {
        getApp().viewController.pop(SLIDE_LEFT);
    }
}
