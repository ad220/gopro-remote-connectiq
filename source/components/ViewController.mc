import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ViewController {
    private var viewLayersCount as Number;
    // private var currentView as WatchUi.View;
    private var currentDelegate as WatchUi.BehaviorDelegate or WatchUi.Menu2InputDelegate or Null;

    public function initialize() {
        self.viewLayersCount = 0;
    } 

    public function push(view as WatchUi.View, delegate as WatchUi.BehaviorDelegate or WatchUi.Menu2InputDelegate, slide as WatchUi.SlideType) as Void {
        if (currentDelegate instanceof NotifDelegate) { currentDelegate.pop(); }

        WatchUi.pushView(view, delegate, slide);
        viewLayersCount++;
        System.println("viewLayersCount: " + viewLayersCount.toString());
    }

    public function switchTo(view as WatchUi.View, delegate as WatchUi.BehaviorDelegate or WatchUi.Menu2InputDelegate, slide as WatchUi.SlideType) as Void {
        if (currentDelegate instanceof NotifDelegate) {
            push(view, delegate, slide);
        }
        WatchUi.switchToView(view, delegate, slide);
    }

    public function pop(slide as WatchUi.SlideType) as Void {
        if (viewLayersCount > 0) {
            if (currentDelegate instanceof NotifDelegate) { currentDelegate.pop(); }
            else {
                WatchUi.popView(slide);
                viewLayersCount--;
                System.println("viewLayersCount: " + viewLayersCount.toString());
            }
        }
    }

    public function returnHome(message as String?, messageType as NotifView.NotifType?) as Void {
        for (; viewLayersCount>1; viewLayersCount--) {
            pop(WatchUi.SLIDE_IMMEDIATE);
        }
        if (viewLayersCount>0) {
            pop(WatchUi.SLIDE_LEFT);
        }
    }
}