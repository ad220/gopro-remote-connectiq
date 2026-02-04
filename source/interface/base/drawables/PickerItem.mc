import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;


class PickerItem extends WatchUi.CustomMenuItem {

    private static var selected as Char;


    public function initialize(label as String or ResourceId, id as Char, selected as Char) {
        CustomMenuItem.initialize(id, {});
        self.selected = selected;

        setLabel(label);
    }

    public function draw(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(0.08*width, 0.1*height, 0.84*width, 0.8*height, 0xFF);
        dc.setColor(getId()==selected ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.5*width, 0.46*height, ICM.fontSmall, getLabel(), ICM.JTEXT_MID);
    }

    public function select() as Void {
        selected = getId() as Char;
    }
}
