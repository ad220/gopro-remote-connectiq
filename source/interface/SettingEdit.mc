import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


class SettingEditMenu extends WatchUi.CustomMenu {
    public function initialize(setting as Number, gp as GoProSettings) {
        CustomMenu.initialize((70*kMult).toNumber(), Graphics.COLOR_BLACK, {:title=> new $.CustomMenuTitle(MainResources.labels[UI_SETTINGEDIT][setting])});
        var items;
        var selected;
        items = gp.possibleSettings(setting);
        selected = gp.getSetting(setting);
        for (var i=0; i<items.size(); i++) {
            CustomMenu.addItem(new SettingEditItem(setting, items[i], selected));
        }
    }
}

class SettingEditItem extends WatchUi.CustomMenuItem {
    private var id;
    private var label;
    private static var selected;

    public function initialize(setting, _id, _selected as Number) {
        id = _id;
        label = MainResources.settingLabels[setting][_id];
        selected = _selected;
        CustomMenuItem.initialize(id, {});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dc.getWidth()/2-100*kMult, dc.getHeight()/2-25*kMult, 200*kMult, 50*kMult, 25*kMult);
        if (id == selected) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2-2*kMult, MainResources.fontMedium, label, JTEXT_MID);
    }

    public function select() as Void {
        selected = id;
    }

    public function getId() {
        return id;
    }
}

class SettingEditDelegate extends WatchUi.Menu2InputDelegate {
    private var setting;
    private var gp;

    public function initialize(_setting as Number, _gp as GoProSettings) {
        setting = _setting;
        gp = _gp;
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        gp.setSetting(setting, item.getId());
        (item as SettingEditItem).select();
        WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        MainResources.loadIcons(UI_SETTINGEDIT);
        GoProRemoteApp.popView(WatchUi.SLIDE_RIGHT);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}
