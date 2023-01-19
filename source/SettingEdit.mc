import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


class SettingEditMenu extends WatchUi.CustomMenu {
    public function initialize(setting as Symbol, gp as GoProSettings) {
        CustomMenu.initialize(70, Graphics.COLOR_BLACK, {:title=> new $.GoProMenuTitle(settingTitle.get(setting))});
        var items;
        var selected;
        switch (setting) {
            //TODO: gp.possibleOptions();
            case :resolution:
                items = gp.possibleResolutions();
                selected = gp.getResolution();
                break;
            case :framerate:
                items = gp.possibleFramerates();
                selected = gp.getFramerate();
                break;
            case :ratio:
                items = gp.possibleRatios();
                selected = gp.getRatio();
                break;
            case :lens:
                items = gp.possibleLenses();
                selected = gp.getLens();
                break;
            default:
                items = [];
                selected = null;
        }
        for (var i=0; i<items.size(); i++) {
            CustomMenu.addItem(new SettingEditItem(items[i], selected));
        }
    }
}

class SettingEditItem extends WatchUi.CustomMenuItem {
    private var id;
    private var label;
    private var preselected;
    private static var modified;

    public function initialize(_id, selected as Symbol) {
        id = _id;
        label = settingLabel.get(_id);
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

    public function getId() as Symbol {
        return id;
    }
}

class SettingEditDelegate extends WatchUi.Menu2InputDelegate {
    private var setting;
    private var gp;

    public function initialize(_setting as Symbol, _gp as GoProSettings) {
        setting = _setting;
        gp = _gp;
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as SettingEditItem) as Void {
        switch(setting) {
            case :resolution :
                gp.setResolution(item.getId());
                break;
            case :ratio :
                gp.setRatio(item.getId());
                break;
            case :lens :
                gp.setLens(item.getId());
                break;
            case :framerate :
                gp.setFramerate(item.getId());
                break;
            default:
        }
        item.setModified();
        WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}
