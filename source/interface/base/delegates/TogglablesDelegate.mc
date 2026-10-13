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

        camera.queryValues(GoProDecoder.GET_STATUS, [GoProCamera.BATTERY, GoProCamera.SD_REMAINING]b);
        camera.queryValues(GoProDecoder.REGISTER_SETTING, view.togglableIds);
        camera.queryValues(GoProDecoder.GET_AVAILABLE, view.togglableIds);
    }

    public function update() as Void {
        view.update();
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

            var id = button.identifier;
            if (id == GoProCamera.SLEEP) {
                getApp().gopro.sendCommand(GoProCamera.SLEEP);
            } else {
                ICM.toggleOrPick(id as GoProSettings.SettingId);
            }
            return true;
        }
        return false;
    }

    public function onSwipe(swipeEvent as SwipeEvent) as Boolean {
        if (swipeEvent.getDirection() == SWIPE_UP) {
            return onBack();
        }
        return false;
    }

    public function onBack() as Boolean {
        var app = getApp();
        app.viewController.pop(SLIDE_UP);
        app.gopro.queryValues(GoProDecoder.UNREGISTER_SETTING, view.togglableIds);
        return true;
    }
}