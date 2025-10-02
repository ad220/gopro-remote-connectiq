import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

class Togglable extends WatchUi.Button {

    public var defaultState as ResourceId;
    public var activatedState as ResourceId;
    private var isActivated as Boolean;
    private var isHilighted as Boolean;

    public function initialize(options as Dictionary) {
        Button.initialize(options);

        self.defaultState = options.get(:defaultBmpId) as ResourceId;
        self.activatedState = options.get(:activatedBmpId) as ResourceId;
        toggleState(false);

        self.isActivated = false;
        self.isHilighted = getState() == :stateHilighted;
        if (isHilighted) {
            setState(:stateDefault);
        }
    }

    public function draw(dc as Dc) as Void {
        Button.draw(dc);

        if (isHilighted) {
            if (dc has :setAntiAlias) {
                dc.setAntiAlias(true);
            }

            var radius = width/2;
            dc.setPenWidth(2*ICM.kMult);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(locX+radius, locY+radius, radius);
        }
    }

    public function hilight() as Void {
        isHilighted = true;
    }

    public function unhilight() as Void {
        isHilighted = false;
    }

    public function toggleState(isActivated as Boolean) as Void {
        if (self.isActivated!=isActivated) {
            self.isActivated = isActivated; 
            var rezId = isActivated ? activatedState : defaultState;
            background = new Bitmap({:rezId=>rezId, :locX=>locX, :locY=>locY});
        }
    }
}


class TogglablesView extends WatchUi.View {

    private var camera as GoProSettings;
    private var buttons as Array<Togglable>;
    private var buttonsCount as Number;
    private var currentHilight as Number;

    public function initialize(camera as GoProSettings) {
        View.initialize();

        self.camera = camera;
        self.buttons = [];
        self.buttonsCount = 0;
        self.currentHilight = 0;
    }

    public function onLayout(dc as Dc) as Void {
        buttons = Rez.Layouts.TogglablesLayout(dc) as Array<Togglable>;
        buttonsCount = buttons.size();
        currentHilight = buttonsCount-1;
        buttons[currentHilight].hilight();
        setLayout(buttons as Array<Drawable>);
    }

    public function onShow() as Void {
        View.onShow();
        
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

class TogglablesDelegate extends WatchUi.BehaviorDelegate {

    private var view as TogglablesView;
    private var camera as GoProCamera;
    private var viewController as ViewController;

    public function initialize(view as TogglablesView, camera as GoProCamera, viewController as ViewController) {
        BehaviorDelegate.initialize();

        self.view = view;
        self.camera = camera;
        self.viewController = viewController;
    }

    public function onKey(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getKey() == KEY_ENTER) {
            method(view.getHilighted().behavior).invoke();
            return true;
        }
        return false;
    }

    public function onNextPage() as Boolean {
        view.prevButton();
        requestUpdate();
        return true;
    }

    public function onPreviousPage() as Boolean {
        view.nextButton();
        requestUpdate();
        return true;
    }

    public function onSelectable(selectableEvent as SelectableEvent) as Boolean {
        var button = selectableEvent.getInstance();
        if (button instanceof Togglable) {
            view.onTouch(button);
            return true;
        }
        return false;
    }

    public function onFlicker() as Void {
        var flicker = camera.getSetting(GoProSettings.FLICKER) as Number;
        view.getHilighted().toggleState(flicker & 0x01 == 0);
        camera.sendSetting(GoProSettings.FLICKER, (flicker ^ 0x01) as Char);
    }
    
    public function onPower() as Void {
        view.getHilighted().toggleState(true);
        camera.sendCommand(GoProCamera.SLEEP);
        getApp().timerController.start(camera.method(:disconnect), 1, false);
    }
    
    public function onLed() as Void {
        var available = camera.getAvailableSettings(GoProSettings.LED);
        if (available.size()>2) {
            var menu = new CustomMenu((50*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {:titleItemHeight => (80*ICM.kMult).toNumber()});
            viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.LED, camera, viewController), SLIDE_LEFT);
        } else {
            var ledStatus = camera.getSetting(GoProSettings.LED);
            view.getHilighted().toggleState(ledStatus==0 or ledStatus==100);
            camera.sendSetting(GoProSettings.LED, available[available.indexOf(ledStatus) ^ 0x01] as Char);
        }
    }
    
    public function onGps() as Void {
        if (camera.getAvailableSettings(GoProSettings.GPS)!=null) {
            var gps = camera.getSetting(GoProSettings.GPS) as Number;
            view.getHilighted().toggleState(gps & 0x01 == 0);
            camera.sendSetting(GoProSettings.GPS, (gps ^ 0x01) as Char);
        }
    }

    public function onStabilize() as Void {
        var menu = new CustomMenu((50*ICM.kMult).toNumber(), Graphics.COLOR_BLACK, {:titleItemHeight => (80*ICM.kMult).toNumber()});
        viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.HYPERSMOOTH, camera, viewController), SLIDE_LEFT);
    }

    public function onBack() as Boolean {
        viewController.pop(SLIDE_UP);
        return true;
    }
}