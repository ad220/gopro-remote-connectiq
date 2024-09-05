import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// TODO: adapt item size to screen size

class SettingEditMenu extends WatchUi.CustomMenu {
    public function initialize(setting as Number, gp as GoProSettings) {
        CustomMenu.initialize(70, Graphics.COLOR_BLACK, {:title=> new $.CustomMenuTitle(MainResources.labels[UI_SETTINGS][setting])});
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
        label = MainResources.settingLabels[setting][_id];
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
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2-2, MainResources.fontMedium, label, JTEXT_MID);
    }

    public function setModified() as Void {
        modified = true;
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
        (item as SettingEditItem).setModified();
        WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        MainResources.loadIcons(UI_SETTINGS);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}
