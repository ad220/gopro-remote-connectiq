import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;

class TimerController {

    private var timer as Timer.Timer;
    private var period as Number;
    private var isRunning as Boolean;
    private var callbackList as Array<TimerCallback>;

    public function initialize(periodInMs as Number) {
        self.timer = new Timer.Timer();
        self.period = periodInMs;
        self.callbackList = [];
        self.isRunning = false;
    }

    public function triggerCallbacks() as Void {
        for (var i=0; i<callbackList.size(); i++) {
            callbackList[i].trigger();
        }
    }

    public function start(callback as Method() as Void, periodInTicks as Number, repeat as Boolean) as TimerCallback{
        var timerCallback = new TimerCallback(callback, periodInTicks, repeat, self);
        callbackList.add(timerCallback);
        if (!isRunning) {
            timer.start(method(:triggerCallbacks), period, true);
            isRunning = true;
        }
        return timerCallback;
    }

    public function stop(callback as TimerCallback?) {
        if (callbackList.remove(callback)) {
            callback.clear();
            if (callbackList.size()==0) {
                stopAll();
            }
        }
    }

    public function stopAll() {
        callbackList = [];
        timer.stop();
        isRunning = false;
    }

    public function getPeriod() as Number {
        return period;
    }
}


class TimerCallback {

    private var callback as Method() as Void?;
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

    public function trigger() as Void {
        tickCount = (tickCount + 1) % period;
        if (tickCount == 0) {
            callback.invoke();
            if (!repeat) {
                stop();
            }
        }
    }

    public function stop() as Void {
        controller.stop(self);
    }

    public function clear() as Void {
        callback = null;
    }
}