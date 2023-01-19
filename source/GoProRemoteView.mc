import Toybox.Graphics;
import Toybox.WatchUi;

class GoProSettingButton extends WatchUi.Button {
    public function initialize(x, y, width, height) {
        var buttonDrawable = new ButtonDrawable(x, y, width, height); 
        Button.initialize({
            :behavior => :onSettings,
            :locX => x,
            :locY => y,
            :width => width,
            :height => height,
            :id => :stateDefault,
            :stateDefault => buttonDrawable
        });
    }

    class ButtonDrawable extends WatchUi.Drawable {
        var icon;
        var w;
        var h;

        function initialize(x, y, w, h) {
            icon = WatchUi.loadResource(Rez.Drawables.Setting);
            Drawable.initialize({});
            Drawable.setLocation(x, y);
            Drawable.setSize(w, h);
        }

        function draw(dc as Dc) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(40, 180, 160, 40, 20);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(132, 200, GoProResources.fontTiny, cam.getDescription(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawBitmap(49, 188, icon);

            

            // var w = dc.getWidth();
            // var h = dc.getHeight();
            // dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            // dc.fillRoundedRectangle(0, 0, w, h, h/2);
            // dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            // dc.drawText(117, h/2, GoProResources.fontTiny, cam.getDescription(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            // dc.drawBitmap(9, 8, icon);
        }
    }
}

class GoProRemoteDelegate extends WatchUi.BehaviorDelegate {
    var view;

    public function initialize(_view) {
        BehaviorDelegate.initialize();
        view = _view;
    }

    public function onTap(tap as ClickEvent) {
        var coord = tap.getCoordinates();
        if (coord[0]<200 and coord[0]>40 and coord[1]<220 and coord[1]>180) {
            onSettings();
        }
        return true;
    }

    public function onSettings() {
        WatchUi.pushView(new PresetPickerMenu(), new PresetPickerDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    public function onSelect() {
        cam.pressShutter();
        return false;
    }
}


class GoProRemoteView extends WatchUi.View {
    var settingsButton;

    function initialize() {
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
        settingsButton = new GoProSettingButton(40, 180, 160, 40);
        //TODO: Edit with mode icon
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
        dc.setPenWidth(1);
        settingsButton.draw(dc);


        // Preset Button


        if (cam.isRecording()) { // draw recording + record time
            //TODO: set timer for update every second


        }
        // Call the parent onUpdate function to redraw the layout
        // View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        settingsButton = null;
    }

}
