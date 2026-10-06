import Toybox.Lang;
import Toybox.WatchUi;


class NotifDelegate extends WatchUi.BehaviorDelegate {

    private var timer as TimerCallback;

    public function initialize() {
        self.timer = getApp().timerController.start(method(:onTimeout), 20, false);
        BehaviorDelegate.initialize();
    }

    public function onBack() {
        pop();
        return true;
    }

    public function pop() as Void {
        timer.stop();
        WatchUi.popView(WatchUi.SLIDE_UP);
    }

    public function onTimeout() as Void {
        getApp().viewController.pop(SLIDE_UP);
    }
}