import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

using InterfaceComponentsManager as ICM;


class RecordButton extends WatchUi.Button {

    (:typecheck(false))
    public function initialize(options as Dictionary) {
        Button.initialize(options);
    }

    public function draw(dc as Dc) as Void {
        var height = dc.getHeight();
        var width = dc.getWidth();
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRoundedRectangle(0.385*width, 0.231*height, 0.346*width, 0.346*height, 0.07*width);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(0.03*width);
        dc.drawCircle(0.558*width, 0.404*height, 0.1*width);
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
        if (recDuration == null) { recDuration = 0; }
        var timeLabel = findDrawableById("RecordTime") as Text;
        var descLabel = findDrawableById("RecordSettingsLabel") as Text;
        if (isRecording) {
            var minutes = recDuration / 60;
            var seconds = recDuration % 60;
            var timeString = (minutes/100).toString() + (minutes%60).toString() + ":" + (seconds/10).toString() + (seconds%10).toString();
            timeLabel.setText(timeString);
        }
        timeLabel.setVisible(isRecording);
        descLabel.setText(gopro.getDescription());
        descLabel.setColor(isRecording ? 0xAAAAAA : 0xFFFFFF);
        (findDrawableById("RecordSettingsButton") as Drawable).setVisible(!isRecording);
        (findDrawableById("RecordRed") as Drawable).setVisible(isRecording and recDuration&1==0);
        (findDrawableById("RecordGray") as Drawable).setVisible(isRecording and recDuration&1==1);

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
            var menu = new CustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, null);
            getApp().viewController.push(menu, new SettingsMenuDelegate(menu, SettingsMenuDelegate.MAIN, []), SLIDE_UP);
            getApp().gopro.subscribeChanges(GoProDelegate.REGISTER_AVAILABLE, [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE]b);
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
        } else if (!gopro.getDescription().equals(". . .")) {
            var view = new TogglablesView();
            getApp().viewController.push(view, new TogglablesDelegate(view), SLIDE_DOWN);
            getApp().gopro.subscribeChanges(GoProDelegate.REGISTER_AVAILABLE, [GoProSettings.FLICKER, GoProSettings.LED, GoProSettings.HYPERSMOOTH]b);
            return true;
        }
        return false;
    }

    public function onBack() as Boolean {
        if (!gopro.isRecording()) {
            gopro.sendCommand(GoProCamera.SLEEP);
            getApp().timerController.start(gopro.method(:disconnect), 1, false);
        } else {
            gopro.disconnect();
        }
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
