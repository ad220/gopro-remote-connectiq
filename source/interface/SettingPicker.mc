import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


class SettingPickerMenu extends WatchUi.CustomMenu {
    public function initialize(gp as GoProSettings, id as Number) {
        GoProResources.loadLabels(UI_SETTINGS);
        var title="GoPro";
        if (id<3) {
            title=GoProResources.labels[UI_EDITABLES][id];
        }
        CustomMenu.initialize(80, Graphics.COLOR_BLACK, {:title=> new CustomMenuTitle(title)});
        for (var i=0; i<N_SETTINGS; i++) {
            CustomMenu.addItem(new SettingPickerItem(i, gp)); // i => enum Settings
        }
    }
}

class SettingPickerItem extends WatchUi.CustomMenuItem {
    private var id;
    private var gp;

    public function initialize(_id as Number, _gp as GoProSettings) {
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
        dc.drawText(halfW+22, halfH-14, GoProResources.fontSmall, GoProResources.labels[UI_SETTINGS][id], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(halfW+22, halfH+16, GoProResources.fontTiny, GoProResources.settingLabels[id][gp.getSetting(id)], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(halfW-36, halfH+2, halfW+80, halfH+2);
        dc.drawBitmap(36, halfH-14, GoProResources.icons[UI_SETTINGS][id]);
    }

    public function getId() {
        return id;
    }
}

class SettingPickerDelegate extends WatchUi.Menu2InputDelegate {
    protected var gp;

    public function initialize(_gp as GoProSettings) {
        gp = _gp;
        GoProResources.loadIcons(UI_SETTINGS);
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        var setting = item.getId() as Number;
        WatchUi.pushView(new SettingEditMenu(setting, gp), new SettingEditDelegate(setting, gp), WatchUi.SLIDE_UP);
        // WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        gp.save();
        GoProResources.loadIcons(UI_EDITABLES);
        // maybe should pop 2 views if camera edit
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}