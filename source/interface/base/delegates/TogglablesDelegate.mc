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
        var ids = view.togglableIds.slice(null, null);

        camera.queryValues(GoProDecoder.GET_STATUS, [GoProCamera.BATTERY, GoProCamera.SD_REMAINING]b);
        camera.queryValues(GoProDecoder.REGISTER_SETTING, ids);

        ids.remove(GoProSettings.BEEPS);
        ids.remove(GoProSettings.BEEPS_OLD);
        camera.queryValues(GoProDecoder.GET_AVAILABLE, ids);
    }

    public function update() as Void {
        view.update();
        WatchUi.requestUpdate();
    }

    public function onKey(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getType() == PRESS_TYPE_ACTION) {
            if (keyEvent.getKey() == KEY_ENTER) {
                ICM.toggleOrPick(view.getHilighted().identifier as GoProSettings.SettingId);
                return true;
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

            ICM.toggleOrPick(button.identifier as GoProSettings.SettingId);
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