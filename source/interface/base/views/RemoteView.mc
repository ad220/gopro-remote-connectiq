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
            :locX       => Screen.HEIGHT * 0.35,
            :locY       => Screen.WIDTH * 0.2,
            :width      => Screen.WIDTH * 0.4,
            :height     => Screen.HEIGHT * 0.4
        }));
        // Hilight button
        layout.add(new Button({
            :behavior   => :hilight,
            :locX       => Screen.HEIGHT * 0.1,
            :locY       => Screen.WIDTH * 0.3,
            :width      => Screen.WIDTH * 0.2,
            :height     => Screen.HEIGHT * 0.2
        }));
        // Settings button
        layout.add(new Button({
            :behavior   => :onMenu,
            :locX       => Screen.HEIGHT * 0.2,
            :locY       => Screen.WIDTH * 0.65,
            :width      => Screen.WIDTH * 0.6,
            :height     => Screen.HEIGHT * 0.2
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
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        var gopro = getApp().gopro as GoProCamera?;
        if (gopro == null) {
            // ERA_CRASH(x11v4.0.1, x100v4.0.2): before null check
            EM.raise(EM.ERR_NULL, 7, :CriticalErr);
            return;
        }

        View.onUpdate(dc);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.clear();

        // Hilight and shutter buttons
        dc.fillCircle(0.20*Screen.WIDTH, 0.40*Screen.HEIGHT, 0.09*Screen.WIDTH);
        dc.fillRoundedRectangle(0.385*Screen.WIDTH, 0.231*Screen.HEIGHT, 0.346*Screen.WIDTH, 0.346*Screen.HEIGHT, 0.07*Screen.WIDTH);
        
        // Record state related elements
        if (gopro.isRecording()) {
            var recordTime = gopro.getStatus(GoProCamera.ENCODING_DURATION); // in seconds
            if (recordTime == null) { recordTime = 0; }

            // Draw the recording circle, blinks every second
            if (recordTime % 2) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
            }
            dc.fillCircle(0.38*Screen.WIDTH, 0.10*Screen.HEIGHT, 0.025*Screen.WIDTH);

            // Draw the recording duration 
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var timeString = (recordTime / 60) + ":" + (recordTime % 60).format("%02d");
            dc.drawText(Screen.WIDTH * 0.45, 0.1*Screen.HEIGHT, ICM.fontTiny, timeString, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            // Settings button
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.fillRoundedRectangle(0.175*Screen.WIDTH, 0.6865*Screen.HEIGHT, 0.65*Screen.WIDTH, 0.167*Screen.HEIGHT, 255);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(0.55*Screen.WIDTH, 0.765*Screen.HEIGHT, ICM.fontTiny, gopro.getDescription(), ICM.JTEXT_MID);
        
        // Draw icons
        if (hilightIcon!=null and settingsIcon!=null) {
            dc.drawBitmap(0.156*Screen.WIDTH, 0.356*Screen.HEIGHT, hilightIcon);
            dc.drawBitmap(0.21*Screen.WIDTH, 0.72*Screen.HEIGHT, settingsIcon);
        } else {
            EM.raise(EM.ERR_NULL, 8, :WarningErr);
        }

        // Draw record circle
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_DK_GRAY);
        dc.setPenWidth(0.03*Screen.WIDTH);
        dc.drawCircle(0.558*Screen.WIDTH, 0.404*Screen.HEIGHT, 0.1*Screen.WIDTH);
    }
}
