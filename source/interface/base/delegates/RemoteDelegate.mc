import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;


class RemoteDelegate extends WatchUi.BehaviorDelegate {
    private var gopro as GoProCamera;

    public function initialize() {
        self.gopro = getApp().gopro;
        BehaviorDelegate.initialize();
    }

    public function onKeyPressed(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getKey()==KEY_ENTER) {
            shutter();
            return true;
        }
        return false;
    }

    public function onMenu() as Boolean {
        if (!gopro.isRecording()) {
            var menu = new CustomMenu((0.15*ICM.screenH).toNumber()<<1, Graphics.COLOR_BLACK, {});
            getApp().viewController.switchTo(menu, new SettingsMenuDelegate(menu, SettingsMenuDelegate.MAIN, []), SLIDE_UP);
            getApp().gopro.subscribeChanges(
                CameraDelegate.REGISTER_AVAILABLE,
                [GoProSettings.RESOLUTION, GoProSettings.LENS, GoProSettings.FRAMERATE]b
            );
            return true;
        }
        return false;
    }

    public function onNextPage() as Boolean {
        return onMenu();
    }

    (:highend)
    public function onPreviousPage() as Boolean {
        if (gopro.isRecording()) {
            hilight();
            return true;
        } else if (!gopro.getDescription().equals(". . .")) {
            var view = new TogglablesView();
            getApp().viewController.push(view, new TogglablesDelegate(view), SLIDE_DOWN);
            getApp().gopro.subscribeChanges(
                CameraDelegate.REGISTER_AVAILABLE,
                [GoProSettings.FLICKER, GoProSettings.LED, GoProSettings.GPS, GoProSettings.HYPERSMOOTH]b
            );
            return true;
        }
        return false;
    }

    
    (:lowend)
    public function onPreviousPage() as Boolean {
        if (gopro.isRecording()) {
            hilight();
            return true;
        } else if (!gopro.getDescription().equals(". . .")) {
            var menu = new Menu2(null);
            getApp().viewController.push(menu, new TogglablesDelegate(menu), SLIDE_DOWN);
            getApp().gopro.subscribeChanges(
                CameraDelegate.REGISTER_AVAILABLE,
                [GoProSettings.FLICKER, GoProSettings.LED, GoProSettings.GPS, GoProSettings.HYPERSMOOTH]b
            );
            return true;
        }
        return false;
    }

    public function onBack() as Boolean {
        if (!gopro.isRecording()) {
            gopro.sendCommand(GoProCamera.SLEEP);
            getApp().timerController.start(gopro.method(:disconnect), 1, false);
        } else {
            gopro.disconnect();
        }
        getApp().viewController.pop(SLIDE_RIGHT);
        return true;
    }

    public function shutter() as Void {
        gopro.sendCommand(GoProCamera.SHUTTER);
    }

    public function hilight() as Void {
        if (gopro.isRecording()) {
            gopro.sendCommand(GoProCamera.HILIGHT);
        }
    }
}
