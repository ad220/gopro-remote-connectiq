import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


class SettingPickerMenu extends WatchUi.CustomMenu {
    public function initialize(gp as GoProSettings, id as Number) {
        var title="GoPro";
        if (id<3) {
            title=MainResources.labels[UI_PRESETMENU][id];
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
        var m_halfW = dc.getWidth()/2;
        var m_halfH = dc.getHeight()/2;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(m_halfW-100, m_halfH-30, 200, 60, 30);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(m_halfW+22, m_halfH-14, MainResources.fontSmall, MainResources.labels[UI_SETTINGS][id], JTEXT_MID);
        dc.drawText(m_halfW+22, m_halfH+16, MainResources.fontTiny, MainResources.settingLabels[id][gp.getSetting(id)], JTEXT_MID);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(m_halfW-36, m_halfH+2, m_halfW+80, m_halfH+2);
        dc.drawBitmap(36, m_halfH-14, MainResources.icons[UI_SETTINGS][id]);
    }
    public function getId() {
        return id;
    }
}

class SettingPickerDelegate extends WatchUi.Menu2InputDelegate {
    protected var gp;

    public function initialize(_gp as GoProSettings) {
        gp = _gp;
        MainResources.loadIcons(UI_SETTINGS);
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        var setting = item.getId() as Number;
        // WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        gp.save();
        MainResources.loadIcons(UI_PRESETMENU);
        // maybe should pop 2 views if camera edit
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}