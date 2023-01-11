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
        CustomMenu.initialize(80, Graphics.COLOR_BLACK, {:title=> new GoProMenuTitle(settingsLabel)});
        for (var i=0; i<settingsList.size(); i++) {
            CustomMenu.addItem(new SettingChooseItem(settingsList[i], gp.getSetting(settingsList[i])));
        }
    }
}

class SettingChooseItem extends WatchUi.CustomMenuItem {
    private var id;
    private var selected;

    public function initialize(_id, _selected) {
        id=_id;
        selected = _selected;
        CustomMenuItem.initialize(_id, {});
    }

    public function draw(dc as Dc) as Void {
        var halfW = dc.getWidth()/2;
        var halfH = dc.getHeight()/2;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(halfW-90, halfH-30, 180, 60, 30);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(halfW, halfH-14, fontSohneSmall, settingTitle.get(id), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(halfW, halfH+16, fontSohneSmall, settingLabel.get(selected), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(halfW-60, halfH+2, halfW+60, halfH+2);
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