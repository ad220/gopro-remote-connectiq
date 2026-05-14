import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;
using ErrorManager as EM;


class RemoteView extends WatchUi.View {

    private var hilightIcon as BitmapType?;
    private var settingsIcon as BitmapType?;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        var layout = [];

        // Shutter button
        layout.add(new Button({
            :behavior   => :shutter,
            :locX       => ICM.screenH * 0.35,
            :locY       => ICM.screenW * 0.2,
            :width      => ICM.screenW * 0.4,
            :height     => ICM.screenH * 0.4
        }));
        // Hilight button
        layout.add(new Button({
            :behavior   => :hilight,
            :locX       => ICM.screenH * 0.1,
            :locY       => ICM.screenW * 0.3,
            :width      => ICM.screenW * 0.2,
            :height     => ICM.screenH * 0.2
        }));
        // Settings button
        layout.add(new Button({
            :behavior   => :onMenu,
            :locX       => ICM.screenH * 0.2,
            :locY       => ICM.screenW * 0.65,
            :width      => ICM.screenW * 0.6,
            :height     => ICM.screenH * 0.2
        }));
        setLayout(layout);
    }

    function onShow() as Void {
        hilightIcon = loadResource(Rez.Drawables.Hilight) as BitmapType;
        settingsIcon = loadResource(Rez.Drawables.Settings) as BitmapType;
    }

    function onHide() as Void {
        hilightIcon = null;
        settingsIcon = null;
    }

    function onUpdate(dc as Dc) as Void {
        var gopro = getApp().gopro as GoProCamera?;
        if (gopro == null) {
            // ERA_CRASH(x11v4.0.1, x100v4.0.2): before null check
            EM.raise(EM.ERR_NULL, 7, :CriticalErr);
            return;
        }

        var width = dc.getWidth();
        var height = dc.getHeight();

        View.onUpdate(dc);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.clear();

        // Hilight and shutter buttons
        dc.fillCircle(0.20*width, 0.40*height, 0.09*width);
        dc.fillRoundedRectangle(0.385*width, 0.231*height, 0.346*width, 0.346*height, 0.07*width);
        
        // Record state related elements
        if (gopro.isRecording()) {
            var recordTime = gopro.getStatus(GoProCamera.ENCODING_DURATION); // in seconds
            if (recordTime == null) { recordTime = 0; }

            // Draw the recording circle, blinks every second
            if (recordTime % 2) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            }
            dc.fillCircle(0.38*width, 0.10*height, 0.025*width);

            // Draw the recording duration 
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var timeString = (recordTime / 60) + ":" + (recordTime % 60).format("%02d");
            dc.drawText(ICM.halfW, 0.1*height, ICM.fontTiny, timeString, ICM.JTEXT_MID);

            // Settings button
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.fillRoundedRectangle(0.175*width, 0.6865*height, 0.65*width, 0.167*height, 255);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(0.55*width, 0.765*height, ICM.fontTiny, gopro.getDescription(), ICM.JTEXT_MID);
        
        // Draw icons
        if (hilightIcon!=null and settingsIcon!=null) {
            dc.drawBitmap(0.156*width, 0.356*height, hilightIcon);
            dc.drawBitmap(0.21*width, 0.72*height, settingsIcon);
        } else {
            EM.raise(EM.ERR_NULL, 8, :WarningErr);
        }

        // Draw record circle
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_DK_GRAY);
        dc.setPenWidth(0.03*width);
        dc.drawCircle(0.558*width, 0.404*height, 0.1*width);
    }
}
