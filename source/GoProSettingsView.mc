import Toybox.Graphics;
import Toybox.WatchUi;

class GoProSettingsView extends WatchUi.View {
    private static var fontSohneSmall;

    function initialize() {
        View.initialize();
    }
    
    // Load your resources here
    function onLayout(dc as Dc) as Void {
        fontSohneSmall = WatchUi.loadResource(Rez.Fonts.SohneSmall);
        setLayout(Rez.Layouts.GoProSettings(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        // 
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var x = dc.getWidth();
        var cx = x/2;
        var y = dc.getHeight();
        var cy = y/2;

        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.fillCircle(25, cy, 20);
        dc.fillRoundedRectangle(cx-60, cy-30, 120, 60, 30);
        dc.fillCircle(x-25, cy, 20);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy-10, fontSohneSmall, "Setting", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(25, cy-16, Graphics.FONT_MEDIUM, "<", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x-25, cy-16, Graphics.FONT_MEDIUM, ">", Graphics.TEXT_JUSTIFY_CENTER);

        // var scrollSetting = new Rez.Drawables.ScrollSetting();
        // scrollSetting.draw(dc);

        // Call the parent onUpdate function to redraw the layout
        // View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}