import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// TODO: replace preset edit with camera settings save as preset
class SettingsMenu extends WatchUi.CustomMenu {
    public enum SettingsMenuType {
        SM_MENU,
        SM_PSETS,
        SM_EDIT
    }

    public function initialize(menuType as SettingsMenuType, presetId as Number) {
        var title;
        if (menuType == SM_EDIT) {
            MainResources.loadIcons(UI_SETTINGEDIT);
            MainResources.loadLabels(UI_SETTINGEDIT);

            title = "GoPro";
        } else if (menuType == SM_MENU) {
            // MainResources.freeIcons(UI_HILIGHT);
            // MainResources.freeIcons(UI_MENUS);
            MainResources.loadIcons(UI_SETTINGSMENU);
            MainResources.loadLabels(UI_MENUS);
            MainResources.loadLabels(UI_SETTINGSMENU);

            title = MainResources.labels[UI_MENUS][SETTINGS];
        } else {
            title = MainResources.labels[UI_MENUS][PRESETS];
        }

        CustomMenu.initialize((80*kMult).toNumber(), Graphics.COLOR_BLACK, {:title=> new CustomMenuTitle(title)});
        
        if (menuType == SM_EDIT) {
            CustomMenu.addItem(new SettingsMenuItem(-1, GoProSettings.RESOLUTION));
            CustomMenu.addItem(new SettingsMenuItem(-1, GoProSettings.RATIO));
            CustomMenu.addItem(new SettingsMenuItem(-1, GoProSettings.LENS));
            CustomMenu.addItem(new SettingsMenuItem(-1, GoProSettings.FRAMERATE));
        } else {
            for (var id=0; id < (menuType==SM_PSETS ? 3 : 5); id++) { // id => presetId
                CustomMenu.addItem(new SettingsMenuItem(id, -1)); // i => enum Editables
            }
        }
    }
}

class SettingsMenuItem extends WatchUi.CustomMenuItem {
    private var presetId as Editables;
    private var settingId as GoProSettings.SettingId;
    private var gp as GoProPreset?;

    public function initialize(pId, sId) {
        presetId = pId;
        settingId = sId;
        var itemId;
        if (pId == -1) {
            itemId = sId;
            gp = cam;
        } else {
            itemId = pId;
            if (pId < 3) {gp = new GoProPreset(pId);}
        }
        CustomMenuItem.initialize(itemId, {});
    }

    public function draw(dc as Dc) as Void {
        var m_halfW = dc.getWidth()/2;
        var m_halfH = dc.getHeight()/2;
        var isEdit = (presetId == -1);
        var id = getId() as Number;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(m_halfW-100*kMult, m_halfH-30*kMult, 200*kMult, 60*kMult, 30*kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawBitmap(m_halfW-84*kMult-imgOff, m_halfH-14*kMult-imgOff, MainResources.icons[isEdit ? UI_SETTINGEDIT : UI_SETTINGSMENU][id]);
        
        if (isEdit or presetId<3) {
            dc.drawText(m_halfW+22*kMult, m_halfH-14*kMult, adaptFontMid(), MainResources.labels[isEdit ? UI_SETTINGEDIT : UI_SETTINGSMENU][id], JTEXT_MID);
            dc.drawText(m_halfW+22*kMult, m_halfH+16*kMult, adaptFontSmall(), isEdit ? GoProSettings.getLabel(id, gp.getSetting(id)) : gp.getDescription(), JTEXT_MID);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(m_halfW-36*kMult, m_halfH+2*kMult, m_halfW+80*kMult, m_halfH+2*kMult);
        } else {
            dc.drawText(m_halfW+22*kMult, m_halfH, adaptFontMid(), MainResources.labels[UI_SETTINGSMENU][id], JTEXT_MID);
        }
    }

    public function getPreset() as GoProPreset {
        return gp;
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var menuType as SettingsMenu.SettingsMenuType;

    public function initialize(_menuType as SettingsMenu.SettingsMenuType) {
        menuType = _menuType;
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        var id = item.getId() as Number;
        // WARNING: popping view unloads mandatory icons and loads unnecessary ones in simulator while the problem doesn't appear on device and lower (<4.1.7 beta) SDK versions
        // NOTE: issue unseen with SDK 6.3.0 and 7.3.0
        if (menuType == SettingsMenu.SM_EDIT) {
            GoProRemoteApp.pushView(new SettingEditMenu(id), new SettingEditDelegate(id), WatchUi.SLIDE_UP, false);
        } else {
            if (id == CAM) {
                GoProRemoteApp.pushView(new SettingsMenu(SettingsMenu.SM_EDIT, id), new SettingsMenuDelegate(SettingsMenu.SM_EDIT), WatchUi.SLIDE_LEFT, true);
            } else if (id == SAVEP7) {
                GoProRemoteApp.pushView(new SettingsMenu(SettingsMenu.SM_PSETS, -1), new SettingsMenuDelegate(SettingsMenu.SM_PSETS), WatchUi.SLIDE_LEFT, false);
            } else if (menuType == SettingsMenu.SM_PSETS) {
                (item as SettingsMenuItem).getPreset().save();
                // Pop two views to remove old preset from menu memory
                GoProRemoteApp.popView(WatchUi.SLIDE_IMMEDIATE);
                GoProRemoteApp.popView(WatchUi.SLIDE_DOWN);
            } else {
                cam.setPreset((item as SettingsMenuItem).getPreset());
                GoProRemoteApp.popView(WatchUi.SLIDE_DOWN);
            }
        }
    }

    public function onBack() as Void {
        GoProRemoteApp.popView(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}