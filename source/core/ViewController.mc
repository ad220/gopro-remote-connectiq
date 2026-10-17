import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ViewController {

    typedef Dlgt as WatchUi.BehaviorDelegate or WatchUi.Menu2InputDelegate or Null;
    typedef DlgtStack as [Dlgt, DlgtStack?];

    protected var viewStack as DlgtStack;

    public function initialize(rootView as Dlgt) {
        self.viewStack = [rootView, null];
    }

    (:typecheck(false))
    public function update() as Void {
        var dlgt = viewStack[0];
        if (dlgt != null and dlgt has :update){
            dlgt.update();
        } else {
            WatchUi.requestUpdate();
        }
    }

    public function push(view as WatchUi.View, delegate as Dlgt, slide as WatchUi.SlideType) as Void {
        var dlgt = viewStack[0];
        if (dlgt instanceof NotifDelegate) {
            viewStack[0] = delegate;
            dlgt.pop();
        } else {
            viewStack = [delegate, viewStack] as DlgtStack;
        }
        WatchUi.pushView(view, delegate, slide);
    }

    public function switchTo(view as WatchUi.View, delegate as Dlgt, slide as WatchUi.SlideType) as Void {
        var dlgt = viewStack[0];
        if (dlgt instanceof NotifDelegate) { dlgt.pop(); }

        viewStack[0] = delegate;
        WatchUi.switchToView(view, delegate, slide);
    }

    public function pop(slide as WatchUi.SlideType) as Void {
        var dlgt = viewStack[0];
        var prev = viewStack[1];

        if (prev != null) {
            if (dlgt instanceof NotifDelegate) { dlgt.pop(); }
            else { WatchUi.popView(slide); }
            viewStack = prev as DlgtStack;
        }
    }

    public function returnHome(message as String or ResourceId or Null, messageType as NotifView.NotifType?) as Void {
        if (getApp().fromGlance) {
            getApp().fromGlance = false;
            System.exit();
        } else {
            while (viewStack[1] != null) {
                pop(WatchUi.SLIDE_RIGHT);
            }

            if (message != null and messageType != null) {
                var notif = new NotifView(message, messageType);
                push(notif, new NotifDelegate(), WatchUi.SLIDE_DOWN);
            }
        }
    }

    (:debug)
    public function getCurrentDelegate() as Dlgt {
        return viewStack[0];
    }
}