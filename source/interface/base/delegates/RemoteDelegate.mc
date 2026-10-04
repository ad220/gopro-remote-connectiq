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
        if (gopro.isRecording()) { return false; }

        var vc = getApp().viewController;
        var menu = new Menu2(null);
        vc.push(menu, new RemoteMenuDelegate(menu), SLIDE_IMMEDIATE);
        return true;
    }

    public function onNextPage() as Boolean {
        if (gopro.isRecording()) { return false; }

        var vc = getApp().viewController;
        if (gopro.getStatus(GoProCamera.PRESET_GRP) == GoProCamera.PGRP_VIDEO) {
            var menu = ICM.newCustomMenu(0.15, null);
            vc.switchTo(menu, new SettingsMenuDelegate(menu, SettingsMenuDelegate.MAIN, []), SLIDE_UP);
        } else {
            var menu = ICM.newCustomMenu(0.1, 0.3);
            vc.push(menu, new SettingPickerDelegate(menu, GoProSettings.PHOTO_LENS), SLIDE_UP);
        }
        return true;
    }

    (:highend)
    public function onPreviousPage() as Boolean {
        if (gopro.isRecording()) {
            hilight();
            return true;
        } else if (!gopro.getDescription().equals(". . .")) {
            var view = new TogglablesView();
            getApp().viewController.push(view, new TogglablesDelegate(view), SLIDE_DOWN);
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
            getApp().gopro.queryValues(
                GoProDecoder.GET_AVAILABLE,
                [GoProSettings.FLICKER, GoProSettings.LED, GoProSettings.HYPERSMOOTH]b
            );
            return true;
        }
        return false;
    }

    public function onBack() as Boolean {
        if (!gopro.isRecording()) {
            gopro.sendCommand(GoProCamera.SLEEP);
            // getApp().timerController.start(gopro.method(:disconnect), 2, false);
        } else {
            gopro.disconnect();
        }
        // getApp().viewController.pop(SLIDE_RIGHT);
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
