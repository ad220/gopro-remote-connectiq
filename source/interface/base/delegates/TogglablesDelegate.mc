import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using ErrorManager as EM;
using InterfaceComponentsManager as ICM;


(:highend)
class TogglablesDelegate extends WatchUi.BehaviorDelegate {

    private var view as TogglablesView;
    private var camera as GoProCamera;

    public function initialize(view as TogglablesView) {
        BehaviorDelegate.initialize();

        self.view = view;
        self.camera = getApp().gopro;

        camera.queryValues(
            GoProDecoder.GET_AVAILABLE,
            [GoProSettings.FLICKER, GoProSettings.LED, GoProSettings.HYPERSMOOTH, GoProSettings.GPS]b
        );
    }

    public function onKey(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getType() == PRESS_TYPE_ACTION) {
            if (keyEvent.getKey() == KEY_ENTER) {
                var callback = view.getHilighted().behavior;
                if (callback != null) {
                    method(callback).invoke();
                    return true;
                }
                EM.raise(EM.ERR_NULL, 6, :WarningErr);
            }
            else if (keyEvent.getKey() == KEY_UP) {
                view.nextButton();
                requestUpdate();
                return true;
            }
            else if (keyEvent.getKey() == KEY_DOWN) {
                view.prevButton();
                requestUpdate();
                return true;
            }
        }
        return false;
    }

    public function onSelectable(selectableEvent as SelectableEvent) as Boolean {
        var button = selectableEvent.getInstance();
        if (button.getState() == :stateHighlighted) {
            button.setState(selectableEvent.getPreviousState());
        }
        if (button instanceof Togglable) {
            view.onTouch(button);
            return true;
        }
        return false;
    }

    (:keep)
    public function onFlicker() as Void {
        var flicker = camera.getSetting(GoProSettings.FLICKER);
        if (flicker != null) { // expected behavior with MAX2 cam
            view.getHilighted().toggleState(flicker & 0x01 == 0);
            camera.sendSetting(GoProSettings.FLICKER, flicker ^ 0x01);
        }
    }
    
    (:keep)
    public function onPower() as Void {
        view.getHilighted().toggleState(true);
        camera.sendCommand(GoProCamera.SLEEP);
    }
    
    (:keep)
    public function onLed() as Void {
        var led = ICM.toggleOrPick(GoProSettings.LED);
        if (led != null) { view.getHilighted().toggleState(led & 3 != 0); }
        // off-values are 0, 4 and 100 while on-values are 1, 2, 3 and 5
    }
    
    (:keep)
    public function onGps() as Void {
        var gps = camera.toggleSetting(GoProSettings.GPS);
        if (gps != null) { view.getHilighted().toggleState(gps != 0); }
    }

    (:keep)
    public function onStabilize() as Void {
        var stab = ICM.toggleOrPick(GoProSettings.HYPERSMOOTH);
        if (stab != null) { view.getHilighted().toggleState(stab != 0); }
    }

    public function onSwipe(swipeEvent as SwipeEvent) as Boolean {
        if (swipeEvent.getDirection() == SWIPE_UP) {
            return onBack();
        }
        return false;
    }

    public function onBack() as Boolean {
        getApp().viewController.pop(SLIDE_UP);
        return true;
    }
}