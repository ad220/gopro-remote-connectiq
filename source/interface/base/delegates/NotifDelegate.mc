import Toybox.Lang;
import Toybox.WatchUi;


class NotifDelegate extends WatchUi.BehaviorDelegate {

    private var timer as TimerCallback;

    public function initialize(ticksTimeout as Number) {
        self.timer = getApp().timerController.start(method(:onTimeout), ticksTimeout, false);
        BehaviorDelegate.initialize();
    }

    public function onBack() {
        onTimeout();
        return true;
    }

    public function pop() as Void {
        timer.stop();
        WatchUi.popView(SLIDE_UP);
    }

    public function onTimeout() as Void {
        getApp().viewController.pop(SLIDE_UP);
    }
}