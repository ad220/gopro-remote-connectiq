import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// inspired from Menu2Sample/MenuTestDelegate/DrawableMenuTitle

class CustomMenuTitle extends WatchUi.Drawable {
    private var title;

    //! Constructor
    public function initialize(_title as String) {
        title = _title;
        Drawable.initialize({});
    }

    //! Draw the application icon and main menu title
    //! @param dc Device Context
    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // dc.drawBitmap(bitmapX, bitmapY, appIcon);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2+8, MainResources.fontLarge, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}