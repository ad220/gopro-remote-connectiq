import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

class MobileStub {
    private var connected as Boolean;

    public function initialize() {
        connected = false;
    }

    public function connect() {
        connected = true;
    }

    public function disconnect() {
        connected = false;
    }

    public function isConnected() {
        return connected;
    }

    public function send(data as Array<Number or Array<Number>>) {
        if (data[0] == COM_CONNECT && data[1]==0) {
            var _view = new RemoteView();
            GoProRemoteApp.pushView(_view, new RemoteDelegate(_view), WatchUi.SLIDE_LEFT, false);
            System.println("Send connected stub");
            cam.setConnected(true);
        } else {
            System.println(data);
        }
    }
}
