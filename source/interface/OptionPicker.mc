import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;


class OptionPickerTitle extends WatchUi.Drawable {
    
    private var title as String;


    public function initialize(title as String or ResourceId) {
        Drawable.initialize({});

        self.title = title instanceof String ? title : loadResource(title) as String;
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.5*dc.getWidth(), 0.6*dc.getHeight(), ICM.fontMedium, title, ICM.JTEXT_MID);
    }

    public function setTitle(title as String) as Void {
        self.title = title;
    }
}


class OptionPickerItem extends WatchUi.CustomMenuItem {

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
