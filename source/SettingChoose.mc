import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const settingsLabel = WatchUi.loadResource(Rez.Strings.Settings);

const settingsList = [:resolution, :ratio, :lens, :framerate];


// const settingTitle = {
//     :resolution => WatchUi.loadResource(Rez.Strings.Resolution),
//     :ratio => WatchUi.loadResource(Rez.Strings.Ratio),
//     :lens => WatchUi.loadResource(Rez.Strings.Lens),
//     :framerate => WatchUi.loadResource(Rez.Strings.Framerate),
// };

class SettingChooseMenu extends WatchUi.CustomMenu {
    public function initialize(gp as GoProSettings) {
        CustomMenu.initialize(60, Graphics.COLOR_BLACK, {:title=> new GoProMenuTitle(settingsLabel)});
        for (var i=0; i<settingsList.size(); i++) {
            CustomMenu.addItem(new SettingChooseItem(settingsList[i]));

        }
    }
}

class SettingChooseItem extends WatchUi.CustomMenuItem {
    private var id;
    private var label;

    public function initialize(_id) {
        id=_id;
        label=settingTitle.get(_id);
        CustomMenuItem.initialize(_id, {});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dc.getWidth()/2-90, dc.getHeight()/2-20, 180, 40, 20);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2-2, fontSohneSmall, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    public function getId() as Symbol {
        return id;
    }
}

class SettingChooseDelegate extends WatchUi.Menu2InputDelegate {
    private var gp;

    public function initialize(_gp as GoProSettings) {
        gp = _gp;
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as SettingChangeItem) as Void {
        var setting = item.getId();
        WatchUi.pushView(new SettingChangeMenu(setting, gp), new SettingChangeDelegate(setting, gp), WatchUi.SLIDE_UP);
        // WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}