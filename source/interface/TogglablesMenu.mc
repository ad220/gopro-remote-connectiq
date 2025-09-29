import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

class Togglable extends WatchUi.Button {

    public var defaultState as ResourceId;
    public var activatedState as ResourceId;
    private var isHilighted as Boolean;

    public function initialize(options as Dictionary) {
        Button.initialize(options);

        self.defaultState = options.get(:defaultBmpId) as ResourceId;
        self.activatedState = options.get(:activatedBmpId) as ResourceId;
        toggleState(false);

        isHilighted = getState() == :stateHilighted;
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
        var rezId = isActivated ? activatedState : defaultState;
        background = new Bitmap({:rezId=>rezId, :locX=>locX, :locY=>locY});
    }
}

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
        setLayout(buttons as Array<Drawable>);
    }

    public function onShow() as Void {
        View.onShow();
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
    private var currentHilight as Togglable?;

    public function initialize(view as TogglablesView, camera as GoProCamera) {
        BehaviorDelegate.initialize();

        self.view = view;
        self.camera = camera;
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
        WatchUi.requestUpdate();
        return true;
    }

    public function onPreviousPage() as Boolean {
        view.nextButton();
        WatchUi.requestUpdate();
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
        camera.sendSetting(GoProSettings.FLICKER, (flicker ^ 0x01) as Char);
        view.getHilighted().toggleState(flicker%3 != 0);
    }
    
    public function onPower() as Void {

    }
    
    public function onLed() as Void {

    }
    
    public function onGps() as Void {

    }

    public function onStabilize() as Void {

    }
}