import Toybox.Graphics;
import Toybox.WatchUi;

class GoProRemoteView extends WatchUi.View {
    var gp;
    var settingIcon;

    function initialize(_gp as GoProCamera) {
        gp = _gp;
        View.initialize();
    }
    
    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        settingIcon = WatchUi.loadResource(Rez.Drawables.Setting);
        //TODO: change with mode icon
        //TODO: edit preset view with icon for each preset, gear cheel for settings and pen for preset edit
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.clear();
        dc.fillRoundedRectangle(80, 70, 80, 80, 8);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(80, 70, 80, 80, 8);
        dc.setPenWidth(4);
        dc.drawArc(120, 120, 108, Graphics.ARC_CLOCKWISE, 100, 80);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(120, 110, 25);


        // Preset Button
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(40, 180, 160, 40, 20);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(132, 200, GoProResources.fontTiny, gp.getDescription(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawBitmap(49, 188, settingIcon);

        if (gp.isRecording()) { // draw recording + record time
            //TODO: set timer for update every second


        }
        // Call the parent onUpdate function to redraw the layout
        // View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        settingIcon = null;
    }

}
