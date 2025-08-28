import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

using InterfaceComponentsManager as ICM;


class CustomMenuTitle extends WatchUi.Drawable {
    
    private var title as String;


    //! Constructor
    public function initialize(title as String) {
        self.title = title;
        Drawable.initialize({});
    }

    //! Draw the application icon and main menu title
    //! @param dc Device Context
    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // dc.drawBitmap(bitmapX, bitmapY, appIcon);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2+8, ICM.fontLarge, title, ICM.JTEXT_MID);
    }
}