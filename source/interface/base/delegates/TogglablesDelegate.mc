import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

(:highend)
class TogglablesDelegate extends WatchUi.BehaviorDelegate {

    private var view as TogglablesView;
    private var camera as GoProCamera;

    public function initialize(view as TogglablesView) {
        BehaviorDelegate.initialize();

        self.view = view;
        self.camera = getApp().gopro;
    }

    public function onKey(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getKey() == KEY_ENTER) {
            var callback = view.getHilighted().behavior;
            if (callback != null) { method(callback).invoke(); }
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
        if (button.getState() == :stateHighlighted) {
            button.setState(selectableEvent.getPreviousState());
        }
        if (button instanceof Togglable) {
            view.onTouch(button);
            return true;
        }
        return false;
    }

    public function onFlicker() as Void {
        var flicker = camera.getSetting(GoProSettings.FLICKER);
        if (flicker != null) {
            flicker = flicker.toNumber();
            view.getHilighted().toggleState(flicker & 0x01 == 0);
            camera.sendSetting(GoProSettings.FLICKER, (flicker ^ 0x01) as Char);
        }
    }
    
    public function onPower() as Void {
        view.getHilighted().toggleState(true);
        camera.sendCommand(GoProCamera.SLEEP);
        getApp().timerController.start(camera.method(:disconnect), 2, false);
    }
    
    public function onLed() as Void {
        var available = camera.getAvailableSettings(GoProSettings.LED);
        if (available.size()>2) {
            var menu = new CustomMenu(
                (0.1*ICM.screenH).toNumber()<<1,
                Graphics.COLOR_BLACK,
                {:titleItemHeight => (0.15*ICM.screenH).toNumber() << 1}
            );
            getApp().viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.LED), SLIDE_LEFT);
        } else {
            var ledStatus = camera.getSetting(GoProSettings.LED);
            if (ledStatus != null) {
                var index = available.indexOf(ledStatus);
                if (index == -1) { return; } // TODO: error msg
                view.getHilighted().toggleState(
                    ledStatus==GoProSettings.LED_OFF or 
                    ledStatus==GoProSettings.LED_ALL_OFF
                );
                camera.sendSetting(
                    GoProSettings.LED,
                    index as Char
                );
            }
        }
    }
    
    public function onGps() as Void {
        var gps = camera.getSetting(GoProSettings.GPS) as Number?;
        if (gps!=null) {
            view.getHilighted().toggleState(gps & 0x01 == 0);
            camera.sendSetting(GoProSettings.GPS, (gps ^ 0x01) as Char);
        }
    }

    public function onStabilize() as Void {
        var menu = new CustomMenu((0.1*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.15*ICM.screenH).toNumber()<<1});
        getApp().viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.HYPERSMOOTH), SLIDE_LEFT);
    }

    public function onBack() as Boolean {
        getApp().viewController.pop(SLIDE_UP);
        return true;
    }
}