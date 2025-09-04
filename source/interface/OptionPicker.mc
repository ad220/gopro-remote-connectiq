import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;


class OptionPickerItem extends WatchUi.CustomMenuItem {

    private static var selected as Char;

    private var id as Char;
    private var label as String;


    public function initialize(label as String, id as Char, selected as Char) {
        self.selected = selected;

        self.id = id;
        self.label = label;

        CustomMenuItem.initialize(id, {});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dc.getWidth()/2-100*ICM.kMult, dc.getHeight()/2-25*ICM.kMult, 200*ICM.kMult, 50*ICM.kMult, 25*ICM.kMult);
        dc.setColor(id==selected ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2-2*ICM.kMult, ICM.fontMedium, label, ICM.JTEXT_MID);
    }

    public function select() as Void {
        selected = id;
    }

    public function getId() {
        return id;
    }
}
