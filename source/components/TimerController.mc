import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;

class TimerController {

    private var timer as Timer.Timer;
    private var callbackList as Array<TimerCallback>;

    public function initialize() {
        self.timer = new Timer.Timer();
        self.callbackList = [];
        self.timer.start(method(:triggerCallbacks), 500, true);
    }

    public function triggerCallbacks() as Void {
        for (var i=0; i<callbackList.size(); i++) {
            callbackList[i].trigger();
        }
    }

    public function start(callback as Method() as Void, periodInTicks as Number, repeat as Boolean) as TimerCallback{
        var timerCallback = new TimerCallback(callback, periodInTicks, repeat, self);
        callbackList.add(timerCallback);
        return timerCallback;
    }

    public function stop(callback as TimerCallback?) {
        callbackList.remove(callback);
    }

    public function stopAll() {
        callbackList = [];
    }
}


class TimerCallback {

    private var callback as Method() as Void;
    private var period as Number;
    private var repeat as Boolean;
    private var controller as TimerController;
    private var tickCount as Number;


    public function initialize(callback as Method() as Void, period as Number, repeat as Boolean, controller as TimerController) {
        self.callback = callback;
        self.period = period;
        self.repeat = repeat;
        self.controller = controller;
        self.tickCount = 0;
    }

    public function trigger() {
        tickCount = (tickCount + 1) % period;
        if (tickCount == 0) {
            callback.invoke();
            if (!repeat) {
                stop();
            }
        }
    }

    public function stop() {
        controller.stop(self);
    }
}