import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

using InterfaceComponentsManager as ICM;


class RemoteView extends WatchUi.View {

    private var gopro as GoProCamera;
    private var hilightIcon as BitmapResource?;
    private var settingsIcon as BitmapResource?;


    function initialize(gopro as GoProCamera) {
        self.gopro = gopro;
        View.initialize();
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
        if (!gopro.isRecording()) {
            dc.fillRoundedRectangle(ICM.halfW-80*ICM.kMult, ICM.halfH+45*ICM.kMult, 160*ICM.kMult, 40*ICM.kMult, 20*ICM.kMult);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(ICM.halfW+12*ICM.kMult, ICM.halfH+65*ICM.kMult, ICM.adaptFontSmall(), gopro.getDescription(), ICM.JTEXT_MID);
        dc.drawBitmap(ICM.halfW-83*ICM.kMult-ICM.imgOff, ICM.halfH-36*ICM.kMult-ICM.imgOff, hilightIcon);
        dc.drawBitmap(ICM.halfW-71*ICM.kMult-ICM.imgOff, ICM.halfH+53*ICM.kMult-ICM.imgOff, settingsIcon);
        dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(8*ICM.kMult);
        dc.drawCircle(ICM.halfW+15*ICM.kMult, ICM.halfH-25*ICM.kMult, 28*ICM.kMult);
        dc.setPenWidth(1);


        // Preset Button
        if (gopro.isRecording()) {
            // Draw the recording duration
            var recDurationSeconds = gopro.getStatus(GoProCamera.ENCODING_DURATION);
            var minutes = Math.floor(recDurationSeconds / 60);
            var seconds = recDurationSeconds % 60;
            var timeString = (minutes/100).toString() + (minutes%60).toString() + ":" + (seconds/10).toString() + (seconds%10).toString();
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(ICM.halfW, ICM.halfH/6, ICM.fontTiny, timeString, ICM.JTEXT_MID);

            // Draw the recording circle, blinks every second
            if (recDurationSeconds % 2 == 0) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(ICM.halfW-35*ICM.kMult, ICM.halfH/6, 6*ICM.kMult);

        } else {
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
}

class RemoteDelegate extends WatchUi.BehaviorDelegate {
    private var viewController as ViewController;
    private var gopro as GoProCamera;

    public function initialize(viewController as ViewController, gopro as GoProCamera) {
        self.viewController = viewController;
        self.gopro = gopro;
        BehaviorDelegate.initialize();
    }

    public function onTap(tap as ClickEvent) as Boolean {
        var coord = tap.getCoordinates();
        if (coord[0]<ICM.halfW+75*ICM.kMult and coord[0]>ICM.halfW-35*ICM.kMult and coord[1]<ICM.halfH+25*ICM.kMult and coord[1]>ICM.halfH-75*ICM.kMult) {
            gopro.sendCommand(GoProCamera.SHUTTER);
        } else if (gopro.isRecording() and coord[0]<ICM.halfW-45*ICM.kMult and coord[0]>ICM.halfW-100*ICM.kMult and coord[1]<ICM.halfH+5*ICM.kMult and coord[1]>ICM.halfH-55*ICM.kMult) {
            gopro.sendCommand(GoProCamera.HILIGHT);
        } else if (coord[0]<ICM.halfW+80*ICM.kMult and coord[0]>ICM.halfW-80*ICM.kMult and coord[1]<ICM.halfH+100*ICM.kMult and coord[1]>ICM.halfH+40*ICM.kMult) {
            return onMenu();
        }
        return true;
    }

    public function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Boolean {
        if (keyEvent.getKey()==WatchUi.KEY_ENTER) {
            gopro.sendCommand(GoProCamera.SHUTTER);
            return true;
        } else if (keyEvent.getKey()==WatchUi.KEY_UP and gopro.isRecording()) {
            gopro.sendCommand(GoProCamera.HILIGHT);
            return true;
        }
        return false;
    }

    public function onMenu() as Boolean {
        if (!gopro.isRecording()) {
            var menu = new CustomMenu((80*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {});
            viewController.push(menu, new SettingsMenuDelegate(menu, SettingsMenuItem.MAIN, gopro, [], viewController), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }

    public function onNextPage() as Boolean {
        return onMenu();
    }

    public function onBack() as Boolean {
        gopro.disconnect();
        viewController.pop(WatchUi.SLIDE_DOWN);
        return true;
    }
}
