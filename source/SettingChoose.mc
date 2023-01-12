import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const settingsLabel = WatchUi.loadResource(Rez.Strings.Settings);

const settingsList = [:resolution, :ratio, :lens, :framerate];

class SettingChooseMenu extends WatchUi.CustomMenu {
    public function initialize(gp as GoProSettings) {
        CustomMenu.initialize(80, Graphics.COLOR_BLACK, {:title=> new GoProMenuTitle(settingsLabel)});
        for (var i=0; i<settingsList.size(); i++) {
            CustomMenu.addItem(new SettingChooseItem(settingsList[i], gp));
        }
    }
}

class SettingChooseItem extends WatchUi.CustomMenuItem {
    private var id;
    private var gp;

    public function initialize(_id, _gp) {
        id=_id;
        gp = _gp;
        CustomMenuItem.initialize(_id, {});
    }

    public function draw(dc as Dc) as Void {
        var halfW = dc.getWidth()/2;
        var halfH = dc.getHeight()/2;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(halfW-100, halfH-30, 200, 60, 30);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(halfW+22, halfH-14, GoProResources.fontSmall, settingTitle.get(id), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(halfW+22, halfH+16, GoProResources.fontTiny, settingLabel.get(gp.getSetting(id)), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(halfW-36, halfH+2, halfW+80, halfH+2);
        dc.drawBitmap(36, halfH-14, icon.get(id));
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