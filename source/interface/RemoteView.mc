import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

using InterfaceComponentsManager as ICM;


class RecordButton extends WatchUi.Button {
    public function initialize(options) {
        Button.initialize(options);
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRoundedRectangle(ICM.halfW-30*ICM.kMult, ICM.halfH-70*ICM.kMult, 90*ICM.kMult, 90*ICM.kMult, 18*ICM.kMult);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(8*ICM.kMult);
        dc.drawCircle(ICM.halfW+15*ICM.kMult, ICM.halfH-25*ICM.kMult, 28*ICM.kMult);
    }
}

class RemoteView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.RemoteLayout(dc));
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        
        var gopro = getApp().gopro;
        var isRecording = gopro.isRecording();
        var recDuration = gopro.getStatus(GoProCamera.ENCODING_DURATION);
        var timeLabel = findDrawableById("RecordTime") as Text;
        var descLabel = findDrawableById("RecordSettingsLabel") as Text;
        if (isRecording) {
            var minutes = Math.floor(recDuration / 60);
            var seconds = recDuration % 60;
            var timeString = (minutes/100).toString() + (minutes%60).toString() + ":" + (seconds/10).toString() + (seconds%10).toString();
            timeLabel.setText(timeString);
        }
        timeLabel.setVisible(isRecording);
        descLabel.setText(gopro.getDescription());
        descLabel.setColor(isRecording ? 0xAAAAAA : 0xFFFFFF);
        findDrawableById("RecordSettingsButton").setVisible(!isRecording);
        findDrawableById("RecordRed").setVisible(isRecording and recDuration%2==0);
        findDrawableById("RecordGray").setVisible(isRecording and recDuration%2==1);

        View.onUpdate(dc);
    }

}

class RemoteDelegate extends WatchUi.BehaviorDelegate {
    private var gopro as GoProCamera;

    public function initialize() {
        self.gopro = getApp().gopro;
        BehaviorDelegate.initialize();
    }

    public function onKeyPressed(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getKey()==KEY_ENTER) {
            shutter();
            return true;
        }
        return false;
    }

    public function onMenu() as Boolean {
        if (!gopro.isRecording()) {
            var menu = new CustomMenu((80*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {});
            getApp().viewController.push(menu, new SettingsMenuDelegate(menu, SettingsMenuItem.MAIN, []), SLIDE_UP);
            return true;
        }
        return false;
    }

    public function onNextPage() as Boolean {
        return onMenu();
    }

    public function onPreviousPage() as Boolean {
        if (gopro.isRecording()) {
            hilight();
            return true;
        } else if (!gopro.getDescription().equals("...")) {
            var view = new TogglablesView();
            getApp().viewController.push(view, new TogglablesDelegate(view), SLIDE_DOWN);
            return true;
        }
        return false;
    }

    public function onBack() as Boolean {
        gopro.disconnect();
        getApp().viewController.pop(SLIDE_RIGHT);
        return true;
    }

    public function shutter() as Void {
        gopro.sendCommand(GoProCamera.SHUTTER);
    }

    public function hilight() as Void {
        if (gopro.isRecording()) {
            gopro.sendCommand(GoProCamera.HILIGHT);
        }
    }
}
