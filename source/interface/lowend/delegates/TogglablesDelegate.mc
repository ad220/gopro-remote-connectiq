import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

(:lowend)
class TogglablesDelegate extends WatchUi.Menu2InputDelegate {

    private var menu as Menu2;
    private var gopro as GoProCamera;
    private var selected as MenuItem?;

    public function initialize(menu as Menu2) {
        Menu2InputDelegate.initialize();

        self.menu = menu;
        self.gopro = getApp().gopro;
        gopro.requestStatuses([GoProCamera.BATTERY, GoProCamera.SD_REMAINING]b);

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
        sdRemaining = sdRemaining ? sdRemaining/3600+":"+sdRemaining%3600/60 : "--:--";

        var battery = gopro.getStatus(GoProCamera.BATTERY);
        battery = (battery ? battery : "--") + "%";
        
        menu.setTitle("Settings\n" + sdRemaining + " | " + battery);
    }

    public function onSelect(item as MenuItem) as Void {
        selected = item;
        method(item.getId() as Symbol).invoke();
    }

    public function onStab() as Void {
        var menu = new CustomMenu((0.1*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.15*ICM.screenH).toNumber()<<1});
        getApp().viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.HYPERSMOOTH), SLIDE_LEFT);
        // TODO: update stab sublabel on change
    }
    
    public function onLed() as Void {
        var available = gopro.getAvailableSettings(GoProSettings.LED);
        if (available.size()>2) {
            var menu = new CustomMenu((0.1*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.15*ICM.screenH).toNumber()<<1});
            getApp().viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.LED), SLIDE_LEFT);
        } else {
            var ledStatus = gopro.getSetting(GoProSettings.LED);
            if (ledStatus != null) {
                var newStatus = available[available.indexOf(ledStatus) ^ 0x01];
                selected.setSubLabel(GoProSettings.getLabel(GoProSettings.LED, newStatus));
                gopro.sendSetting(GoProSettings.LED, newStatus);
            }
            // TODO(error): settings ? not very useful
        }
    }
    
    public function onFlicker() as Void {
        var flicker = gopro.getSetting(GoProSettings.FLICKER);
        if (flicker != null) {
            (selected as ToggleMenuItem).setEnabled(flicker & 0x01 == 0);
            selected.setSubLabel(flicker & 1 ? "60Hz" : "50Hz");
            gopro.sendSetting(GoProSettings.FLICKER, (flicker ^ 0x01) as Char);
        }
        // TODO(error): settings ? not useful
    }
    
    public function onGps() as Void {
        var gps = gopro.getSetting(GoProSettings.GPS) as Number?;
        if (gps!=null) {
            (selected as ToggleMenuItem).setEnabled(gps & 0x01 == 0);
            gopro.sendSetting(GoProSettings.GPS, (gps ^ 0x01) as Char);
        }
        // TODO(error): settings
    }
    
    public function onPower() as Void {
        gopro.sendCommand(GoProCamera.SLEEP);
        getApp().timerController.start(gopro.method(:disconnect), 2, false);
    }
    

    public function onBack() {
        getApp().viewController.pop(SLIDE_UP);
    }
}
