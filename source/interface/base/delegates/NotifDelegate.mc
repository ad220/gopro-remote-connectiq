import Toybox.Lang;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;


class NotifDelegate extends WatchUi.BehaviorDelegate {

    private var stillExists as Boolean;

    public function initialize() {
        self.stillExists = true;

        BehaviorDelegate.initialize();
    }

    public function onBack() {
        pop();
        return true;
    }

    public function pop() as Void {
        if (stillExists) {
            stillExists = false;
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }
}