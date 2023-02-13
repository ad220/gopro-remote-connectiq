import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


class SettingEditMenu extends WatchUi.CustomMenu {
    public function initialize(setting as Number, gp as GoProSettings) {
        CustomMenu.initialize(70, Graphics.COLOR_BLACK, {:title=> new $.CustomMenuTitle(GoProResources.labels[SETTINGS][setting])});
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
    private var preselected;
    private static var modified;

    public function initialize(setting, _id, selected as Number) {
        id = _id;
        label = GoProResources.settingLabels[setting][_id];
        preselected = _id==selected;
        modified = false;
        CustomMenuItem.initialize(id, {});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dc.getWidth()/2-100, dc.getHeight()/2-25, 200, 50, 25);
        if (preselected and !modified or isSelected()) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2-2, GoProResources.fontMedium, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    public function setModified() as Void {
        modified = true;
    }

    public function getId() as Number {
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

    public function onSelect(item as SettingEditItem) as Void {
        gp.setSetting(setting, item.getId());
        item.setModified();
        WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        GoProResources.loadIcons(SETTINGS);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}
