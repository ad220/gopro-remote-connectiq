import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Timer;
import Toybox.Lang;

using InterfaceComponentsManager as ICM;


class RemoteView extends WatchUi.View {

    private var hilightIcon as BitmapResource?;
    private var settingsIcon as BitmapResource?;
    private var recordingTimer as Timer.Timer;


    function initialize() {
        self.recordingTimer = new Timer.Timer();
        View.initialize();
    }
    
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
        hilightIcon = WatchUi.loadResource(Rez.Drawables.Hilight);
        settingsIcon = WatchUi.loadResource(Rez.Drawables.Wheel);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.clear();
        dc.fillCircle(ICM.halfW-72*ICM.kMult, ICM.halfH-25*ICM.kMult, 22*ICM.kMult);
        dc.fillRoundedRectangle(ICM.halfW-30*ICM.kMult, ICM.halfH-70*ICM.kMult, 90*ICM.kMult, 90*ICM.kMult, 18*ICM.kMult);
        if (!cam.isRecording()) {
            dc.fillRoundedRectangle(ICM.halfW-80*ICM.kMult, ICM.halfH+45*ICM.kMult, 160*ICM.kMult, 40*ICM.kMult, 20*ICM.kMult);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(ICM.halfW+12*ICM.kMult, ICM.halfH+65*ICM.kMult, ICM.adaptFontSmall(), cam.getDescription(), ICM.JTEXT_MID);
        dc.drawBitmap(ICM.halfW-83*ICM.kMult-ICM.imgOff, ICM.halfH-36*ICM.kMult-ICM.imgOff, hilightIcon);
        dc.drawBitmap(ICM.halfW-71*ICM.kMult-ICM.imgOff, ICM.halfH+53*ICM.kMult-ICM.imgOff, settingsIcon);
        dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(8*ICM.kMult);
        dc.drawCircle(ICM.halfW+15*ICM.kMult, ICM.halfH-25*ICM.kMult, 28*ICM.kMult);
        dc.setPenWidth(1);


        // Preset Button
        if (cam.isRecording()) {
            var recDurationSeconds = cam.getProgress();
            recordingTimer.start(method(:recordingTimerCallback), 1000, true);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            // Draw the recording duration 
            var minutes = Math.floor(recDurationSeconds / 60);
            var seconds = recDurationSeconds % 60;
            var timeString = (minutes/100).toString() + (minutes%60).toString() + ":" + (seconds/10).toString() + (seconds%10).toString();
            dc.drawText(ICM.halfW, ICM.halfH/6, ICM.fontTiny, timeString, ICM.JTEXT_MID);

            // Draw the recording circle, blinks every second
            if (recDurationSeconds % 2 == 0) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(ICM.halfW-35*ICM.kMult, ICM.halfH/6, 6*ICM.kMult);

        } else {
            recordingTimer.stop();
            // For v2, would open states menu on swipe down

            // dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            // dc.setPenWidth(6*ICM.kMult);
            // dc.drawArc(ICM.halfW, ICM.halfH, 108*ICM.kMult, Graphics.ARC_CLOCKWISE, 100, 80);
            // dc.fillCircle(ICM.halfW-18*ICM.kMult, ICM.halfH-107*ICM.kMult, round(3*ICM.kMult));
            // dc.fillCircle(ICM.halfW+18*ICM.kMult, ICM.halfH-107*ICM.kMult, round(3*ICM.kMult));
            // dc.setPenWidth(1);
        }
    }
 
    function onHide() as Void {
        hilightIcon = null;
        settingsIcon = null;
    }

    public function recordingTimerCallback() as Void {
        if (cam.isRecording()) {
            cam.incrementProgress();
            WatchUi.requestUpdate();
        }
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
        if (coord[0]<ICM.halfW+75*ICM.kMult and coord[0]>ICM.halfW-35*ICM.kMult and coord[1]<ICM.halfH+25*ICM.kMult and coord[1]>ICM.halfH-75*ICM.kMult) {
            mobile.send([MobileDevice.COM_SHUTTER, 0]);
        } else if (cam.isRecording() and coord[0]<ICM.halfW-45*ICM.kMult and coord[0]>ICM.halfW-100*ICM.kMult and coord[1]<ICM.halfH+5*ICM.kMult and coord[1]>ICM.halfH-55*ICM.kMult) {
            mobile.send([MobileDevice.COM_HIGHLIGHT, 0]);
        } else if (!cam.isRecording() and coord[0]<ICM.halfW+80*ICM.kMult and coord[0]>ICM.halfW-80*ICM.kMult and coord[1]<ICM.halfH+100*ICM.kMult and coord[1]>ICM.halfH+40*ICM.kMult) {
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
            mobile.send([MobileDevice.COM_SHUTTER, 0]);
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
        mobile.send([MobileDevice.COM_CONNECT, 1]);
        viewController.pop(WatchUi.SLIDE_DOWN);
        return true;
    }
}
