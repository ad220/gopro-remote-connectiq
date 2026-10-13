import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using ErrorManager as EM;

(:highend)
class TogglablesView extends WatchUi.View {

    private var buttons as Array<Togglable>;
    private var buttonsCount as Number;
    private var currentHilight as Number;
    public var togglableIds as ByteArray;

    public function initialize() {
        View.initialize();

        self.buttons = [];
        self.buttonsCount = 0;
        self.currentHilight = 0;
        self.togglableIds = [
            GoProSettings.FLICKER,
            GoProSettings.BEEPS,
            GoProSettings.LED,
            GoProSettings.GPS,
            GoProSettings.HYPERSMOOTH,
        ]b;
    }

    public function onLayout(dc as Dc) as Void {
        buttons     = [];
        buttonsCount = 5;

        var params = [
            [0.6853 * Screen.WIDTH, 0.4927 * Screen.HEIGHT, Rez.Drawables.Flicker60, Rez.Drawables.Flicker50],
            [0.4000 * Screen.WIDTH, 0.7000 * Screen.HEIGHT, Rez.Drawables.PowerOn,   Rez.Drawables.PowerOff],
            [0.1147 * Screen.WIDTH, 0.4927 * Screen.HEIGHT, Rez.Drawables.LedOn,     Rez.Drawables.LedOff],
            [0.2237 * Screen.WIDTH, 0.1573 * Screen.HEIGHT, Rez.Drawables.GpsOn,     Rez.Drawables.GpsOff],
            [0.5763 * Screen.WIDTH, 0.1573 * Screen.HEIGHT, Rez.Drawables.StabOn,    Rez.Drawables.StabOff],
        ];

        for (var i=0; i<buttonsCount; i++) {
            buttons.add(new Togglable({
                :width          => 0.2 * Screen.WIDTH,
                :height         => 0.2 * Screen.HEIGHT,
                :identifier     => togglableIds[i],
                :locX           => params[i][0],
                :locY           => params[i][1],
                :defaultBmpId   => params[i][2],
                :enabledBmpId   => params[i][3],
            }));
        }

        currentHilight = buttonsCount-1;
        buttons[currentHilight].isHilighted = true;
        
        var layout = Rez.Layouts.TogglablesInfos(dc);
        layout.addAll(buttons as Array<Drawable>);
        setLayout(layout);
    }

    public function onShow() as Void {
        update();
    }

    public function update() as Void {
        var camera = Helper.safeGoProAccess(33);
        if (camera == null) { return; }

        for (var i=0; i<buttons.size(); i++) {
            buttons[i].updateState();
        }

        var sdRemaining = camera.getStatus(GoProCamera.SD_REMAINING);
        if (sdRemaining!=null) {
            (findDrawableById("SdLevel") as Text).setText(
                sdRemaining / 3600 + ":" + (sdRemaining % 3600 / 60).format("%02d")
            );
        }

        var battery = camera.getStatus(GoProCamera.BATTERY);
        if (battery!=null) {
            (findDrawableById("BatteryLevel") as Text).setText(battery+"%");
        }
    }

    public function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        View.onUpdate(dc);
    }

    public function getHilighted() as Togglable {
        return buttons[currentHilight];
    }

    public function onTouch(button as Togglable) as Void {
        buttons[currentHilight].isHilighted = false;
        currentHilight = buttons.indexOf(button);
    }

    public function nextButton() as Void {
        buttons[currentHilight].isHilighted = false;
        currentHilight = (currentHilight + buttonsCount - 1) % buttonsCount;
        buttons[currentHilight].isHilighted = true;
    }

    public function prevButton() as Void {
        buttons[currentHilight].isHilighted = false;
        currentHilight = (currentHilight + 1) % buttonsCount;
        buttons[currentHilight].isHilighted = true;
    }
}
