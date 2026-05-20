import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

(:debug)
class ViewDebugController extends ViewController {

    var stack as Array<[View, BehaviorDelegate or Menu2InputDelegate or Null]>;

    function initialize() {
        ViewController.initialize();

        self.stack = [];
    }

    function push(view as View, delegate as BehaviorDelegate or Menu2InputDelegate or Null, slide as SlideType) as Void {        
        if (currentDelegate instanceof NotifDelegate) {
            stack[stack.size() - 1] = [view, delegate];
            return;
        }
        stack.add([view, delegate]);

        ViewController.push(view, delegate, slide);
    }

    function switchTo(view as View, delegate as BehaviorDelegate or Menu2InputDelegate or Null, slide as SlideType) as Void {
        if (currentDelegate instanceof NotifDelegate) {
            stack = stack.slice(0, -1);
        }

        if (stack.size()>0) {
            stack[stack.size() - 1] = [view, delegate];
        }

        ViewController.switchTo(view, delegate, slide);
    }

    function pop(slide as SlideType) as Void {
        if (currentDelegate instanceof NotifDelegate or viewLayersCount > 0) {
            stack = stack.slice(0, -1);
        }

        ViewController.pop(slide);
    }

    function popNotif() as Void {
        if (currentDelegate instanceof NotifDelegate) {
            stack = stack.slice(0, -1);
        }

        ViewController.popNotif();
    }

    function getCurrentDelegate() as BehaviorDelegate or Menu2InputDelegate or Null {
        return stack.size()>0 ? stack[stack.size() - 1][1] : null;
    }
}