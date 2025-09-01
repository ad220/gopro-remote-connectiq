import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;


class SettingEditMenu extends WatchUi.CustomMenu {

    private var gopro;

    public function initialize(setting as GoProSettings.SettingId, gopro as GoProCamera) {
        self.gopro = gopro;

        var title;
        switch (setting) {
            case GoProSettings.RESOLUTION:
                title = WatchUi.loadResource(Rez.Strings.Resolution);
                break;
            case GoProSettings.RATIO:
                title = WatchUi.loadResource(Rez.Strings.Ratio);
                break;
            case GoProSettings.LENS:
                title = WatchUi.loadResource(Rez.Strings.Lens);
                break;
            case GoProSettings.FRAMERATE:
                title = WatchUi.loadResource(Rez.Strings.Framerate);
                break;
            default:
                System.println("Unknown Setting id");
                throw new Exception();
        }
        CustomMenu.initialize((70*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {:title=> new $.CustomMenuTitle(title)});

        var items = gopro.getAvailableSettings(setting);
        var selected = gopro.getSetting(setting);
        System.println("Available settings: "+items+", selected: "+selected);
        for (var i=0; i<items.size(); i++) {
            CustomMenu.addItem(new SettingEditItem(setting, items[i], selected));
        }
    }
}


class SettingEditItem extends WatchUi.CustomMenuItem {

    private static var selected as Number;

    private var id as Number;
    private var label as String;


    public function initialize(setting as GoProSettings.SettingId, id as Number, selected as Number) {
        self.selected = selected;

        self.id = id;
        self.label = GoProSettings.getLabel(setting, id);

        CustomMenuItem.initialize(id, {});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dc.getWidth()/2-100*ICM.kMult, dc.getHeight()/2-25*ICM.kMult, 200*ICM.kMult, 50*ICM.kMult, 25*ICM.kMult);
        if (id == selected) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2-2*ICM.kMult, ICM.fontMedium, label, ICM.JTEXT_MID);
    }

    public function select() as Void {
        selected = id;
    }

    public function getId() {
        return id;
    }
}


class SettingEditDelegate extends WatchUi.Menu2InputDelegate {

    private var setting as GoProSettings.SettingId;
    private var viewController as ViewController;
    private var gopro as GoProCamera;


    public function initialize(setting as GoProSettings.SettingId, viewController as ViewController, gopro as GoProCamera) {
        self.setting = setting;
        self.viewController = viewController;
        self.gopro = gopro;

        Menu2InputDelegate.initialize();
    }

    public function onSelect(item) {
        gopro.sendSetting(setting, item.getId() as Number);
        (item as SettingEditItem).select();
        WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        viewController.pop(WatchUi.SLIDE_RIGHT);
    }

    public function onWrap(key as Key) as Boolean {
        return false;
    }
}
