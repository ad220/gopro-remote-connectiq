import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ViewController {

    private var viewLayersCount as Number;
    private var currentDelegate as WatchUi.BehaviorDelegate or WatchUi.Menu2InputDelegate or Null;


    public function initialize() {
        self.viewLayersCount = 0;
    } 

    public function push(view as WatchUi.View, delegate as WatchUi.BehaviorDelegate or WatchUi.Menu2InputDelegate or Null, slide as WatchUi.SlideType) as Void {
        if (currentDelegate instanceof NotifDelegate) { currentDelegate.pop(); }

        currentDelegate = delegate;
        WatchUi.pushView(view, delegate, slide);
        if (delegate instanceof NotifDelegate) {
            getApp().timerController.start(delegate.method(:pop), 8, false);
        } else {
            viewLayersCount++;
        }
    }

    public function switchTo(view as WatchUi.View, delegate as WatchUi.BehaviorDelegate or WatchUi.Menu2InputDelegate or Null, slide as WatchUi.SlideType) as Void {
        if (currentDelegate instanceof NotifDelegate) { currentDelegate.pop(); }

        currentDelegate = delegate;
        WatchUi.switchToView(view, delegate, slide);
    }

    public function pop(slide as WatchUi.SlideType) as Void {
        if (currentDelegate instanceof NotifDelegate) {
            currentDelegate.pop();
        } else if (viewLayersCount > 0) {
            WatchUi.popView(slide);
            viewLayersCount--;
        }
        currentDelegate = null;
    }

    public function returnHome(message as String?, messageType as NotifView.NotifType?) as Void {
        for (; viewLayersCount>1;) {
            pop(WatchUi.SLIDE_IMMEDIATE);
        }
        if (viewLayersCount>0) {
            pop(WatchUi.SLIDE_LEFT);
        }
    }
}