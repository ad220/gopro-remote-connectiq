import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

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
        findDrawableById("RecordRed").setVisible(isRecording and recDuration&1==0);
        findDrawableById("RecordGray").setVisible(isRecording and recDuration&1==1);

        View.onUpdate(dc);
    }

}
