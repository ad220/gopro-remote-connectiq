import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

//button ids : preset1, preset2, preset3, camera, edit
//editing presets pushes another PresetPickerMenu view over the first one
//edit icon and label in connect iq app settings

class PresetPickerMenu extends WatchUi.CustomMenu {

    public function initialize(editPreset as Number) {
        GoProResources.freeIcons(HILIGHT);
        GoProResources.freeIcons(MODES);
        CustomMenu.initialize(80, Graphics.COLOR_BLACK, {:title=> new CustomMenuTitle("Presets")}); //TODO: add in strings.xml
        GoProResources.loadIcons(EDITABLES);
        GoProResources.loadLabels(EDITABLES);
        for (var i=0; i<N_EDITABLES-2*editPreset; i++) {
            CustomMenu.addItem(new PresetPickerItem(i)); // i => enum Editables
        }
    }
}

class PresetPickerItem extends WatchUi.CustomMenuItem {
    private var id as Number;
    private var gp as GoProPreset?;

    public function initialize(_id) {
        id=_id;
        if (_id < 3) {
            gp = new GoProPreset(_id);
        }
        CustomMenuItem.initialize(_id, {});
    }

    public function draw(dc as Dc) as Void {
        var halfW = dc.getWidth()/2;
        var halfH = dc.getHeight()/2;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(halfW-100, halfH-30, 200, 60, 30);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        dc.drawBitmap(36, halfH-14, GoProResources.icons[EDITABLES][id]);
        if (id<3) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(halfW-36, halfH+2, halfW+80, halfH+2);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(halfW+22, halfH+16, GoProResources.fontTiny, gp.getDescription(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(halfW+22, halfH-14, GoProResources.fontSmall, GoProResources.labels[EDITABLES][id], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(halfW+22, halfH, GoProResources.fontSmall, GoProResources.labels[EDITABLES][id], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

    }

    public function getId() as Number {
        return id;
    }

    public function getPreset() as GoProPreset {
        return gp;
    }
}

class PresetPickerDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as PresetPickerItem) as Void {
        var id = item.getId();
        if (id == CAM) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(new SettingPickerMenu(cam, id), new SettingPickerDelegate(cam), WatchUi.SLIDE_LEFT);
        } else if (id == EDITP7) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(new PresetPickerMenu(1), new PresetPickerDelegate(), WatchUi.SLIDE_LEFT);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            cam.setPreset(item.getPreset());
        }
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}