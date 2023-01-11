import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

var fontSohneSmall = WatchUi.loadResource(Rez.Fonts.SohneSmall);

const settingTitle = {
    :resolution => WatchUi.loadResource(Rez.Strings.Resolution),
    :ratio => WatchUi.loadResource(Rez.Strings.Ratio),
    :lens => WatchUi.loadResource(Rez.Strings.Lens),
    :framerate => WatchUi.loadResource(Rez.Strings.Framerate),
};

const settingLabel = {
    // Resolutions
    :_5K => WatchUi.loadResource(Rez.Strings._5K),
    :_4K => WatchUi.loadResource(Rez.Strings._4K),
    :_3K => WatchUi.loadResource(Rez.Strings._3K),
    :_2K => WatchUi.loadResource(Rez.Strings._2K),
    // Aspect Ratios
    :_8R7 => WatchUi.loadResource(Rez.Strings._8R7),
    :_4R3 => WatchUi.loadResource(Rez.Strings._4R3),
    :_16R9 => WatchUi.loadResource(Rez.Strings._16R9),
    // Framerates
    :_240 => WatchUi.loadResource(Rez.Strings._240),
    :_200 => WatchUi.loadResource(Rez.Strings._200),
    :_120 => WatchUi.loadResource(Rez.Strings._120),
    :_100 => WatchUi.loadResource(Rez.Strings._100),
    :_60 => WatchUi.loadResource(Rez.Strings._60),
    :_50 => WatchUi.loadResource(Rez.Strings._50),
    :_30 => WatchUi.loadResource(Rez.Strings._30),
    :_25 => WatchUi.loadResource(Rez.Strings._25),
    :_24 => WatchUi.loadResource(Rez.Strings._24),
    // Lenses 
    :_HyperView => WatchUi.loadResource(Rez.Strings.HyperView),
    :_SuperView => WatchUi.loadResource(Rez.Strings.SuperView),
    :_Large => WatchUi.loadResource(Rez.Strings.Large),
    :_Linear => WatchUi.loadResource(Rez.Strings.Linear),
    :_LinearLock => WatchUi.loadResource(Rez.Strings.LinearLock)
};

class SettingChangeMenu extends WatchUi.CustomMenu {
    public function initialize(setting as Symbol, gp as GoProSettings) {
        CustomMenu.initialize(60, Graphics.COLOR_BLACK, {:title=> new $.GoProMenuTitle(settingTitle.get(setting))});
        var items;
        var selected;
        switch (setting) {
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
            CustomMenu.addItem(new SettingChangeItem(items[i], selected));
        }
    }
}

class SettingChangeItem extends WatchUi.CustomMenuItem {
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
        dc.fillRoundedRectangle(dc.getWidth()/2-90, dc.getHeight()/2-20, 180, 40, 20);
        if (preselected and !modified or isSelected()) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2-2, fontSohneSmall, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    public function setModified() as Void {
        modified = true;
    }

    public function getId() as Symbol {
        return id;
    }
}

class SettingChangeDelegate extends WatchUi.Menu2InputDelegate {
    private var setting;
    private var gp;

    public function initialize(_setting as Symbol, _gp as GoProSettings) {
        setting = _setting;
        gp = _gp;
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as SettingChangeItem) as Void {
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
