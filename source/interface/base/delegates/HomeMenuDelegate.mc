import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;


class HomeMenuDelegate extends Menu2InputDelegate {

    private var parent as ConnectDelegate;

    public function initialize(menu as Menu2, parent as ConnectDelegate) {
        Menu2InputDelegate.initialize();
        
        self.parent = parent;

        menu.setTitle(Rez.Strings.AppName);
        menu.addItem(new MenuItem(Rez.Strings.StartScan, null, null, null));
        menu.addItem(new ToggleMenuItem(Rez.Strings.ToggleReports, null, null, getApp().reportsEnabled, null));
        menu.setFooter("v4.2.3");
    }

    public function onSelect(item as MenuItem) as Void {
        var app = getApp();

        // toggle reports
        if (item instanceof ToggleMenuItem) {
            app.reportsEnabled = item.isEnabled();
        }
        // start scan
        else {
            getApp().viewController.pop(SLIDE_IMMEDIATE);
            parent.startScan();
        }
    }
}