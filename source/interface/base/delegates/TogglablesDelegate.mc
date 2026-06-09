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

        camera.subscribeChanges(
            CameraDelegate.GET_AVAILABLE,
            [GoProSettings.FLICKER, GoProSettings.LED, GoProSettings.HYPERSMOOTH]b
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
            flicker = flicker.toNumber();
            view.getHilighted().toggleState(flicker & 0x01 == 0);
            camera.sendSetting(GoProSettings.FLICKER, (flicker ^ 0x01) as Char);
        }
    }
    
    (:keep)
    public function onPower() as Void {
        view.getHilighted().toggleState(true);
        camera.sendCommand(GoProCamera.SLEEP);
    }
    
    (:keep)
    public function onLed() as Void {
        var available = camera.getAvailableSettings(GoProSettings.LED);
        if (available.size() == 0) {
            EM.raise(EM.ERR_CAM | EM.SUB_CAM_NULL | 0x08 <<16, GoProSettings.LED, :WarningErr);
            return;
        }

        if (available.size()>2) {
            var menu = ICM.newCustomMenu(0.1, 0.15);
            getApp().viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.LED), SLIDE_LEFT);
        } else {
            var ledStatus = camera.getSetting(GoProSettings.LED);
            if (ledStatus == null) {
                EM.raise(EM.ERR_CAM | EM.SUB_CAM_NULL | 0x01 << 16, GoProSettings.LED, :WarningErr);
                return;
            }

            var index = available.indexOf(ledStatus);
            if (index == -1) {
                EM.raise(
                    EM.ERR_CAM | EM.SUB_CAM_AVAIL | 0x01 << 16,
                    ledStatus.toNumber() << 8 + GoProSettings.LED,
                    :WarningErr
                );
            }

            view.getHilighted().toggleState(
                ledStatus==GoProSettings.LED_OFF or 
                ledStatus==GoProSettings.LED_ALL_OFF
            );
            camera.sendSetting(
                GoProSettings.LED,
                available[(index + 1) % available.size()]
            );
        }
    }
    
    (:keep)
    public function onGps() as Void {
        var gps = camera.getSetting(GoProSettings.GPS) as Number?;
        if (gps==null) {
            EM.raise(EM.ERR_CAM | EM.SUB_CAM_NULL | 0x01 << 16, GoProSettings.GPS, :WarningErr);
            return;
        }
        
        view.getHilighted().toggleState(gps & 0x01 == 0);
        camera.sendSetting(GoProSettings.GPS, (gps ^ 0x01) as Char);
    }

    (:keep)
    public function onStabilize() as Void {
        var menu = ICM.newCustomMenu(0.1, 0.15);
        getApp().viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.HYPERSMOOTH), SLIDE_LEFT);
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