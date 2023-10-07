import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Timer;
import Toybox.Lang;


class GoProRemoteDelegate extends WatchUi.BehaviorDelegate {
    var view;

    public function initialize(_view) {
        BehaviorDelegate.initialize();
        view = _view;
    }

    public function onTap(tap as ClickEvent) {
        var coord = tap.getCoordinates();
        //TODO: other buttons
        if (coord[0]<190 and coord[0]>85 and coord[1]<150 and coord[1]>40) {
            mobile.send([COM_SHUTTER, 0]);
        } else if (cam.isRecording() and coord[0]<75 and coord[0]>15 and coord[1]<120 and coord[1]>60) {
            mobile.send([COM_HIGHLIGHT, 0]);
        } else if (!cam.isRecording() and coord[0]<200 and coord[0]>40 and coord[1]<220 and coord[1]>160) {
            onSettings();
        }
        return true;
    }

    public function onSettings() {
        WatchUi.pushView(new PresetPickerMenu(0), new PresetPickerDelegate(false), WatchUi.SLIDE_UP);
        return true;
    }

    public function onBack() {
        mobile.send([COM_CONNECT, 1]);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}


class GoProRemoteView extends WatchUi.View {
    var settingsButton;
    var recordingTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
        recordingTimer = new Timer.Timer();
    }
    
    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        GoProResources.loadSettingLabels();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        onRemoteView = true;
        GoProResources.loadIcons(UI_HILIGHT);
        GoProResources.loadIcons(UI_MODES);
        GoProResources.freeIcons(UI_EDITABLES);
        GoProResources.freeIcons(UI_STATES);
        //TODO: Edit with mode icon
        //TODO: edit preset view with icon for each preset, gear cheel for settings and pen for preset edit
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // var enabled;
        // if (cam.isRecording()) {
        //     enabled=Graphics.COLOR_DK_GRAY;
        // } else {
        //     enabled=Graphics.COLOR_LT_GRAY;
        // }
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.clear();
        dc.fillCircle(48, 95, 22);
        dc.fillRoundedRectangle(90, 50, 90, 90, 18);
        if (!cam.isRecording()) {
            dc.fillRoundedRectangle(40, 165, 160, 40, 20);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(132, 185, GoProResources.fontTiny, cam.getDescription(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawBitmap(37, 84, GoProResources.icons[UI_HILIGHT] as WatchUi.BitmapResource);
        dc.drawBitmap(49, 173, GoProResources.icons[UI_MODES][WHEEL]);
        dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(8);
        dc.drawCircle(135, 95, 28);
        dc.setPenWidth(1);


        // Preset Button
        if (cam.isRecording()) {
            var recDurationSeconds = cam.getProgress();
            if (recordingTimer==null) {
                recordingTimer = new Timer.Timer();
                recordingTimer.start(method(:recordingTimerCallback), 1000, true);
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            // Draw the recording duration 
            var minutes = Math.floor(recDurationSeconds / 60);
            var seconds = recDurationSeconds % 60;
            var timeString = (minutes/100).toString() + (minutes%60).toString() + ":" + (seconds/10).toString() + (seconds%10).toString();
            dc.drawText(120, 20, GoProResources.fontTiny, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Draw the recording circle, blinks every second
            if (recDurationSeconds % 2 == 0) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(85, 20, 6);

        } else {
            if (recordingTimer!=null) {
                recordingTimer.stop();
                recordingTimer = null;
                // recDurationSeconds = 0;
            }
            // For v2, would open states menu on swipe down

            // dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            // dc.setPenWidth(6);
            // dc.drawArc(120, 120, 108, Graphics.ARC_CLOCKWISE, 100, 80);
            // dc.fillCircle(102, 13, 3);
            // dc.fillCircle(138, 13, 3);
            // dc.setPenWidth(1);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        settingsButton = null;
        onRemoteView = false;
    }

    function recordingTimerCallback() as Void {
        cam.incrementProgress();
        WatchUi.requestUpdate();
    }

}
