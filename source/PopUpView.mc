import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class PopUpView extends WatchUi.View{
    var message as String;
    var type as Number;

    function initialize(_message as String, _type as PopUpType) {
        message = _message;
        type = _type;
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // GoProResources.load
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor([Graphics.COLOR_DK_GRAY, 0xFF5500][type], Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, 240, 100);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(120, 20, 10);
        dc.drawText(120, 60, GoProResources.fontTiny, message, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor([Graphics.COLOR_DK_GRAY, 0xFF5500][type], Graphics.COLOR_TRANSPARENT);
        dc.drawText(120, 20, GoProResources.fontTiny, ["i", "!"][type], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class PopUpDelegate extends WatchUi.BehaviorDelegate {
    var view as PopUpView;

    public function initialize(_view) {
        BehaviorDelegate.initialize();
        view = _view;
    }
}