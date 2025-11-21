import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;


class PickerTitle extends WatchUi.Drawable {
    
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
        dc.drawText(0.5*dc.getWidth(), 0.6*dc.getHeight(), ICM.fontMedium, title, ICM.JTEXT_MID);
    }

    public function setTitle(title as String) as Void {
        self.title = title;
    }
}
