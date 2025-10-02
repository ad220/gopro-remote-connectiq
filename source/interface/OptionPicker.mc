import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;


class OptionPickerTitle extends WatchUi.Drawable {
    
    private var title as String;


    public function initialize(title as String or ResourceId) {
        Drawable.initialize({});

        if (title instanceof ResourceId) {
            self.title = loadResource(title);
        } else {
            self.title = title;
        }
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2+8, ICM.fontMedium, title, ICM.JTEXT_MID);
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
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(dc.getWidth()/2-90*ICM.kMult, dc.getHeight()/2-20*ICM.kMult, 180*ICM.kMult, 40*ICM.kMult, 20*ICM.kMult);
        dc.setColor(getId()==selected ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2-2*ICM.kMult, ICM.fontSmall, getLabel(), ICM.JTEXT_MID);
    }

    public function select() as Void {
        selected = getId() as Char;
    }
}
