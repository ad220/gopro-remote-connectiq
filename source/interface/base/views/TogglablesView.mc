import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;


class TogglablesView extends WatchUi.View {

    private var buttons as Array<Togglable>;
    private var buttonsCount as Number;
    private var currentHilight as Number;

    public function initialize() {
        View.initialize();

        self.buttons = [];
        self.buttonsCount = 0;
        self.currentHilight = 0;
    }

    public function onLayout(dc as Dc) as Void {
        buttons = Rez.Layouts.TogglablesLayout(dc) as Array<Togglable>;
        buttonsCount = buttons.size();
        currentHilight = buttonsCount-1;
        buttons[currentHilight].hilight();
        
        var layout = Rez.Layouts.TogglablesInfos(dc);
        layout.addAll(buttons as Array<Drawable>);
        setLayout(layout);
    }

    public function onShow() as Void {
        View.onShow();
        var camera = getApp().gopro;
        camera.requestStatuses([GoProCamera.BATTERY, GoProCamera.SD_REMAINING]b);

        var flicker = camera.getSetting(GoProSettings.FLICKER) as Number;
        (findDrawableById("FlickerButton") as Togglable).toggleState(flicker & 0x01 != 0);
        
        var gps = camera.getSetting(GoProSettings.GPS) as Number;
        (findDrawableById("GpsButton") as Togglable).toggleState(gps==1);
        
        var led = camera.getSetting(GoProSettings.LED) as Number;
        (findDrawableById("LedButton") as Togglable).toggleState(
            led==GoProSettings.LED_ON or
            led==GoProSettings.LED_ALL_ON or
            led==GoProSettings.LED_FRONT_OFF
        );
        
        var hypersmooth = camera.getSetting(GoProSettings.HYPERSMOOTH) as Number;
        (findDrawableById("StabilizeButton") as Togglable).toggleState(hypersmooth != GoProSettings.HS_OFF);
    }

    public function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        var camera = getApp().gopro;

        var sdRemaining = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sdRemaining!=null) {
            (findDrawableById("SdLevel") as Text).setText(sdRemaining/3600+":"+sdRemaining%3600/60);
        }
        var battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery!=null) {
            (findDrawableById("BatteryLevel") as Text).setText(battery+"%");
        }

        View.onUpdate(dc);
    }

    public function getHilighted() as Togglable {
        return buttons[currentHilight];
    }

    public function onTouch(button as Togglable) as Void {
        buttons[currentHilight].unhilight();
        currentHilight = buttons.indexOf(button);
    }

    public function nextButton() as Void {
        buttons[currentHilight].unhilight();
        currentHilight = (currentHilight + buttonsCount - 1) % buttonsCount;
        buttons[currentHilight].hilight();
    }

    public function prevButton() as Void {
        buttons[currentHilight].unhilight();
        currentHilight = (currentHilight + 1) % buttonsCount;
        buttons[currentHilight].hilight();
    }
}
