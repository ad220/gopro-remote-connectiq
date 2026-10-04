import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;


class RemoteMenuDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize(menu as Menu2) {
        Menu2InputDelegate.initialize();

        menu.setTitle(Rez.Strings.AdvancedSettings);

        var icon = new Bitmap({
            :rezId  => Rez.Drawables.CaptureMode,
            :locX   => LAYOUT_HALIGN_CENTER,
            :locY   => LAYOUT_VALIGN_CENTER
        });
        var item = new IconMenuItem(Rez.Strings.SwitchMode, null, :SwitchMode, icon, null);
        menu.addItem(item);
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();

        if (id == :SwitchMode) {
            getApp().gopro.sendCommand(GoProCamera.LOAD_PGRP);
            onBack();
        }
    }
}
