import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

(:lowend)
class RemoteView extends WatchUi.View {

    private var hilightIcon as BitmapResource?;
    private var settingsIcon as BitmapResource?;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        hilightIcon = loadResource(Rez.Drawables.Hilight);
        settingsIcon = loadResource(Rez.Drawables.Settings);
    }

    function onHide() as Void {
        hilightIcon = null;
        settingsIcon = null;
    }

    function onUpdate(dc as Dc) as Void {
        var gopro = getApp().gopro;
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.clear();

        // Hilight and shutter buttons
        dc.fillCircle(0.20*width, 0.40*height, 0.09*width);
        dc.fillRoundedRectangle(0.385*width, 0.231*height, 0.346*width, 0.346*height, 0.07*width);
        
        // Settings button
        if (!gopro.isRecording()) {
            dc.fillRoundedRectangle(0.175*width, 0.6865*height, 0.65*width, 0.167*height, 255);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(0.55*width, 0.765*height, ICM.fontTiny, gopro.getDescription(), ICM.JTEXT_MID);
        
        // Draw icons
        dc.drawBitmap(0.156*width, 0.356*height, hilightIcon);
        dc.drawBitmap(0.21*width, 0.72*height, settingsIcon);

        // Draw record circle
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_DK_GRAY);
        dc.setPenWidth(0.03*width);
        dc.drawCircle(0.558*width, 0.404*height, 0.1*width);

        if (gopro.isRecording()) {
            var recDurationSeconds = gopro.getStatus(GoProCamera.ENCODING_DURATION);

            // Draw the recording circle, blinks every second
            if (recDurationSeconds % 2) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            }
            dc.fillCircle(0.38*width, 0.10*height, 0.025*width);

            // Draw the recording duration 
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var minutes = Math.floor(recDurationSeconds / 60);
            var seconds = recDurationSeconds % 60;
            var timeString = (minutes/100).toString() + (minutes%60).toString() + ":" + (seconds/10).toString() + (seconds%10).toString();
            dc.drawText(ICM.halfW, 0.1*height, ICM.fontTiny, timeString, ICM.JTEXT_MID);
        }
    }
}
