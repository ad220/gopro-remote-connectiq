import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

//button ids : preset1, preset2, preset3, camera, edit
//editing presets pushes another PresetPickerMenu view over the first one
//edit icon and label in connect iq app settings

class PresetPickerMenu extends WatchUi.CustomMenu {
    static const presetList = [:preset1, :preset2, :preset3, :camera, :edit];

    public function initialize() {
        CustomMenu.initialize(80, Graphics.COLOR_BLACK, {:title=> new GoProMenuTitle("Presets")}); //TODO: add in strings.xml
        for (var i=0; i<presetList.size(); i++) {
            CustomMenu.addItem(new PresetPickerItem(presetList[i]));
        }
    }
}

class PresetPickerItem extends WatchUi.CustomMenuItem {
    private var id;
    private var gp;

    public function initialize(_id) {
        id=_id;
        if (_id == :camera) {
            gp = cam;
        } else if (_id == :edit) {
            gp = null;
        } else {
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

        var text;
        if (id == :camera) {
            text = "Manually change GoPro settings"; //TODO: write on two lines, don't use line for :camera and :edit
        } else if (id == :edit) {
            text = "Edit presets";
        } else {
            text = gp.getName();
        }
        dc.drawText(halfW+22, halfH-14, GoProResources.fontSmall, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(halfW+22, halfH+16, GoProResources.fontTiny, "some descr.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(halfW-36, halfH+2, halfW+80, halfH+2);
        dc.drawBitmap(36, halfH-14, icon.get(:resolution));
    }

    public function getId() as Symbol {
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
        if (id == :camera) {
            WatchUi.pushView(new SettingPickerMenu(cam), new SettingPickerDelegate(cam), WatchUi.SLIDE_UP);
        } else if (id == :edit) {
            WatchUi.pushView(new PresetPickerMenu(), new PresetPickerDelegate(), WatchUi.SLIDE_UP);
        } else {
            WatchUi.pushView(new PresetEditMenu(item.getPreset()), new PresetEditDelegate(item.getPreset()), WatchUi.SLIDE_UP);
        }
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}