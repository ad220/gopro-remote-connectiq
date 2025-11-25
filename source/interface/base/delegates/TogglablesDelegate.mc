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
            var menu = new CustomMenu((0.1*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.15*ICM.screenH).toNumber()<<1});
            getApp().viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.LED), SLIDE_LEFT);
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
        var menu = new CustomMenu((0.1*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {:titleItemHeight => (0.15*ICM.screenH).toNumber()<<1});
        getApp().viewController.push(menu, new SettingPickerDelegate(menu, GoProSettings.HYPERSMOOTH), SLIDE_LEFT);
    }

    public function onBack() as Boolean {
        getApp().gopro.subscribeChanges(
            CameraDelegate.UNREGISTER_AVAILABLE,
            [GoProSettings.FLICKER, GoProSettings.LED, GoProSettings.GPS, GoProSettings.HYPERSMOOTH]b
        );   
        getApp().viewController.pop(SLIDE_UP);
        return true;
    }
}