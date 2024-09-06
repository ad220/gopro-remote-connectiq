import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//button ids : preset1, preset2, preset3, camera, edit
//editing presets pushes another SettingsMenu view over the first one
//edit icon and label in connect iq app settings

class SettingsMenu extends WatchUi.CustomMenu {
    public enum SettingsMenuType {
        SM_MENU,
        SM_PSETS,
        SM_EDIT
    }

    // menuType is a boolean indicating if we are editing a preset or not (implies we shouldn't draw last options)
    public function initialize(menuType as SettingsMenuType, presetId as Number, gp as GoProPreset?) {
        // TODO: check if resources are properly freed
        var title;
        if (menuType == SM_EDIT) {
            MainResources.loadIcons(UI_SETTINGEDIT);
            MainResources.loadLabels(UI_SETTINGEDIT); // TODO: move to SM_MENU

            title = "GoPro";
            if (presetId<3) {
                title=MainResources.labels[UI_SETTINGSMENU][presetId];
            }
        } else if (menuType == SM_MENU) {
            MainResources.freeIcons(UI_HILIGHT);
            MainResources.freeIcons(UI_MENUS);
            MainResources.loadIcons(UI_SETTINGSMENU);
            MainResources.loadLabels(UI_MENUS);
            MainResources.loadLabels(UI_SETTINGSMENU);

            title = MainResources.labels[UI_MENUS][SETTINGS];
        } else {
            title = MainResources.labels[UI_MENUS][PRESETS];
        }

        CustomMenu.initialize((80*kMult).toNumber(), Graphics.COLOR_BLACK, {:title=> new CustomMenuTitle(title)});
        
        if (menuType == SM_EDIT) {
            for (var id=0; id<N_SETTINGS; id++) { // id => settingId
                CustomMenu.addItem(new SettingsMenuItem(presetId as Editables, id as Settings, gp));
            }
        } else {
            for (var id=0; id < (menuType==SM_PSETS ? 3 : 5); id++) { // id => presetId
                CustomMenu.addItem(new SettingsMenuItem(id as Editables, -1 as Settings, null)); // i => enum Editables
            }
        }
    }
}

class SettingsMenuItem extends WatchUi.CustomMenuItem {
    private var presetId as Editables;
    private var settingId as Settings;
    private var gp as GoProPreset?;

    public function initialize(pId as Editables, sId as Settings, _gp as GoProPreset?) {
        presetId = pId;
        settingId = sId;
        var itemId;
        if (sId != -1) {
            itemId = sId;
            gp = _gp;
        } else {
            itemId = pId;
            if (pId < 3) {gp = new GoProPreset(pId);}
            else if (pId == 3) {gp = cam;}
        }
        CustomMenuItem.initialize(itemId, {});
    }

    public function draw(dc as Dc) as Void {
        var m_halfW = dc.getWidth()/2;
        var m_halfH = dc.getHeight()/2;
        var isEdit = (settingId != -1);
        var id = getId() as Number;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(m_halfW-100*kMult, m_halfH-30*kMult, 200*kMult, 60*kMult, 30*kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawBitmap(m_halfW-84*kMult-imgOff, m_halfH-14*kMult-imgOff, MainResources.icons[isEdit ? UI_SETTINGEDIT : UI_SETTINGSMENU][id]);
        
        if (isEdit or presetId<3) {
            dc.drawText(m_halfW+22*kMult, m_halfH-14*kMult, adaptFontMid(), MainResources.labels[isEdit ? UI_SETTINGEDIT : UI_SETTINGSMENU][id], JTEXT_MID);
            dc.drawText(m_halfW+22*kMult, m_halfH+16*kMult, adaptFontSmall(), isEdit ? MainResources.settingLabels[id][gp.getSetting(id)] : gp.getDescription(), JTEXT_MID);
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
    protected var gp as GoProPreset?;

    public function initialize(_menuType as SettingsMenu.SettingsMenuType, _gp as GoProPreset?) {
        menuType = _menuType;
        gp = _gp;
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        var id = item.getId() as Number;
        //WARNING: popping view unloads mandatory icons and loads unnecessary ones in simulator while the problem doesn't appear on device and lower (<4.1.7 beta) SDK version
        //TODO: check with lower SDK version and/or fix this shit
        //TODO: think about view tree for preset edit

        if (menuType == SettingsMenu.SM_EDIT) {
            WatchUi.pushView(new SettingEditMenu(id, gp), new SettingEditDelegate(id, gp), WatchUi.SLIDE_UP);
        } else {
            if (id == CAM or menuType == SettingsMenu.SM_PSETS) {
                WatchUi.switchToView(new SettingsMenu(SettingsMenu.SM_EDIT, id, (item as SettingsMenuItem).getPreset()), new SettingsMenuDelegate(SettingsMenu.SM_EDIT, (item as SettingsMenuItem).getPreset()), WatchUi.SLIDE_LEFT);
            } else if (id == EDITP7) {
                WatchUi.switchToView(new SettingsMenu(SettingsMenu.SM_PSETS, -1, null), new SettingsMenuDelegate(SettingsMenu.SM_PSETS, null), WatchUi.SLIDE_LEFT);
            } else {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                cam.setPreset((item as SettingsMenuItem).getPreset());
            }
        }


    }

    public function onBack() as Void {
        if (gp) {gp.save();}
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}