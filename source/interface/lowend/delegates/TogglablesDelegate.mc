import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;
using ErrorManager as EM;


(:lowend)
class TogglablesDelegate extends WatchUi.Menu2InputDelegate {

    private var menu as Menu2;
    private var gopro as GoProCamera;
    private var selected as MenuItem?;

    public function initialize(menu as Menu2) {
        Menu2InputDelegate.initialize();

        self.menu = menu;
        self.gopro = getApp().gopro;
        gopro.queryValues(GoProDecoder.GET_STATUS, [GoProCamera.BATTERY, GoProCamera.SD_REMAINING]b);

        var flicker = gopro.getSetting(GoProSettings.FLICKER);
        if (flicker == null) { flicker = 0; }
        var flickerSub = flicker & 1 ? "50Hz" : "60Hz";

        var gps = gopro.getSetting(GoProSettings.GPS);

        menu.addItem(new MenuItem(      Rez.Strings.HyperSmooth,    gopro.getLabel(GoProSettings.HYPERSMOOTH, null),    :onStab,                            null));
        menu.addItem(new MenuItem(      Rez.Strings.Led,            gopro.getLabel(GoProSettings.LED, null),            :onLed,                             null));
        menu.addItem(new ToggleMenuItem(Rez.Strings.AntiFlicker,    flickerSub,                                         :onFlicker,     flicker&1 != 0,     null));
        menu.addItem(new ToggleMenuItem(Rez.Strings.Gps,            null,                                               :onGps,         gps == 1,           null));
        menu.addItem(new MenuItem(      Rez.Strings.PowerOff,       null,                                               :onPower,                           null));

        updateTitle();
        getApp().timerController.start(method(:updateTitle), 5, false);
    }

    public function updateTitle() as Void {
        var gopro = getApp().gopro;

        var sdRemaining = gopro.getStatus(GoProCamera.SD_REMAINING);
        sdRemaining = sdRemaining ? sdRemaining / 3600 + ":" + (sdRemaining % 3600 / 60).format("%02d") : "--:--";

        var battery = gopro.getStatus(GoProCamera.BATTERY);
        battery = (battery ? battery : "--") + "%";
        
        menu.setTitle("Settings\n" + sdRemaining + " | " + battery);
    }

    public function onSelect(item as MenuItem) as Void {
        selected = item;
        method(item.getId() as Symbol).invoke();
    }

    public function onStab() as Void {
        var stab = ICM.toggleOrPick(GoProSettings.HYPERSMOOTH);
        if (stab != null) {
            selected.setSubLabel(GoProSettings.getLabel(GoProSettings.HYPERSMOOTH, stab));
        }
        // TODO(mobile): update stab sublabel on change
    }
    
    public function onLed() as Void {
        var led = ICM.toggleOrPick(GoProSettings.LED);
        if (led != null) {
            selected.setSubLabel(GoProSettings.getLabel(GoProSettings.LED, led));
        }
    }
    
    public function onFlicker() as Void {
        var flicker = gopro.getSetting(GoProSettings.FLICKER);
        if (flicker != null) { // expected behavior with MAX2
            (selected as ToggleMenuItem).setEnabled(flicker & 0x01 == 0);
            selected.setSubLabel(flicker & 1 ? "60Hz" : "50Hz");
            gopro.sendSetting(GoProSettings.FLICKER, flicker ^ 0x01);
        }

    }
    
    public function onGps() as Void {
        var gps = gopro.getSetting(GoProSettings.GPS) as Number?;       
        (selected as ToggleMenuItem).setEnabled(gps & 0x01 == 0);
        gopro.sendSetting(GoProSettings.GPS, gps ^ 0x01);
    }
    
    public function onPower() as Void {
        gopro.sendCommand(GoProCamera.SLEEP);
    }
    

    public function onBack() {
        getApp().viewController.pop(SLIDE_UP);
    }
}
