import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Timer;
import Toybox.Lang;

class RemoteView extends WatchUi.View {
    var settingsButton;
    var recordingTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
        recordingTimer = new Timer.Timer();
    }
    
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
        MainResources.loadIcons(UI_HILIGHT);
        MainResources.loadIcons(UI_MENUS);
        MainResources.freeIcons(UI_SETTINGSMENU);
        MainResources.freeIcons(UI_SETTINGEDIT);
        MainResources.freeIcons(UI_STATES);
        MainResources.freeLabels(UI_MENUS);
        MainResources.freeLabels(UI_SETTINGSMENU);
        MainResources.freeLabels(UI_SETTINGEDIT);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.clear();
        dc.fillCircle(halfW-72*kMult, halfH-25*kMult, 22*kMult);
        dc.fillRoundedRectangle(halfW-30*kMult, halfH-70*kMult, 90*kMult, 90*kMult, 18*kMult);
        if (!cam.isRecording()) {
            dc.fillRoundedRectangle(halfW-80*kMult, halfH+45*kMult, 160*kMult, 40*kMult, 20*kMult);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(halfW+12*kMult, halfH+65*kMult, adaptFontSmall(), cam.getDescription(), JTEXT_MID);
        dc.drawBitmap(halfW-83*kMult-imgOff, halfH-36*kMult-imgOff, MainResources.icons[UI_HILIGHT] as WatchUi.BitmapResource);
        dc.drawBitmap(halfW-71*kMult-imgOff, halfH+53*kMult-imgOff, MainResources.icons[UI_MENUS][SETTINGS]);
        dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(8*kMult);
        dc.drawCircle(halfW+15*kMult, halfH-25*kMult, 28*kMult);
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
            dc.drawText(halfW, halfH/6, MainResources.fontTiny, timeString, JTEXT_MID);

            // Draw the recording circle, blinks every second
            if (recDurationSeconds % 2 == 0) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(halfW-35*kMult, halfH/6, 6*kMult);

        } else {
            if (recordingTimer!=null) {
                recordingTimer.stop();
                recordingTimer = null;
            }
            // For v2, would open states menu on swipe down

            // dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            // dc.setPenWidth(6*kMult);
            // dc.drawArc(halfW, halfH, 108*kMult, Graphics.ARC_CLOCKWISE, 100, 80);
            // dc.fillCircle(halfW-18*kMult, halfH-107*kMult, round(3*kMult));
            // dc.fillCircle(halfW+18*kMult, halfH-107*kMult, round(3*kMult));
            // dc.setPenWidth(1);
        }
    }
 
    function onHide() as Void {
        settingsButton = null;
    }

    function recordingTimerCallback() as Void {
        cam.incrementProgress();
        WatchUi.requestUpdate();
    }

}

class RemoteDelegate extends WatchUi.BehaviorDelegate {
    private var viewController as ViewController;
    private var actionIsSelect as Boolean;

    public function initialize(viewController as ViewController) {
        self.viewController = viewController;
        self.actionIsSelect = false;
        BehaviorDelegate.initialize();
    }

    public function onTap(tap as ClickEvent) {
        actionIsSelect = false;
        var coord = tap.getCoordinates();
        if (coord[0]<halfW+75*kMult and coord[0]>halfW-35*kMult and coord[1]<halfH+25*kMult and coord[1]>halfH-75*kMult) {
            mobile.send([COM_SHUTTER, 0]);
        } else if (cam.isRecording() and coord[0]<halfW-45*kMult and coord[0]>halfW-100*kMult and coord[1]<halfH+5*kMult and coord[1]>halfH-55*kMult) {
            mobile.send([COM_HIGHLIGHT, 0]);
        } else if (!cam.isRecording() and coord[0]<halfW+80*kMult and coord[0]>halfW-80*kMult and coord[1]<halfH+100*kMult and coord[1]>halfH+40*kMult) {
            return onMenu();
        }
        return true;
    }

    public function onSelect() {
        actionIsSelect = true;
        return false;
    }

    public function onKeyPressed(keyEvent) {
        if (actionIsSelect) {
            actionIsSelect = false;
            mobile.send([COM_SHUTTER, 0]);
        }
        return true;
    }

    public function onMenu() {
        viewController.push(new SettingsMenu(SettingsMenu.SM_MENU, -1), new SettingsMenuDelegate(SettingsMenu.SM_MENU, viewController), WatchUi.SLIDE_UP);
        return true;
    }

    public function onNextPage() {
        return onMenu();
    }

    public function onBack() {
        mobile.send([COM_CONNECT, 1]);
        viewController.pop(WatchUi.SLIDE_DOWN);
        return true;
    }
}
