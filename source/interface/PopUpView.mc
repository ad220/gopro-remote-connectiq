import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;

class PopUpView extends WatchUi.View{
    public static var currentView = null as PopUpView?;

    var message as String;
    var type as Number;
    var timer as Timer.Timer;

    function initialize(_message as String, _type as PopUpType) {
        message = _message;
        type = _type;
        timer = new Timer.Timer();
        timer.start(method(:popOut), 4000, false);
        View.initialize(); 
    }

    function onShow() as Void {
        currentView = self;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(type ? 0xFF5500 : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, screenW, 90*kMult);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(halfW, 20*kMult, 10*kMult);
        dc.drawText(halfW, 60*kMult, adaptFontSmall(), message, JTEXT_MID);
        dc.setColor(type ? 0xFF5500 : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(halfW, 20*kMult, adaptFontMid() , type ? "!" : "i", JTEXT_MID);
    }

    function onHide() as Void {
        currentView = null;
    }
    
    public function popOut() as Void {
        currentView = null;
        timer.stop();
        nViewLayers--;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class PopUpDelegate extends WatchUi.BehaviorDelegate {

    public function initialize() {
        BehaviorDelegate.initialize();
    }

    public function onBack() {
        GoProRemoteApp.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}