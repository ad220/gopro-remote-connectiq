import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

// ===
// Messages possibles :
// ===
// 1 - Ouverture connexion M>T>G>T>M
// 2 - Fermeture connexion M>T>G
// 3 - GoPro settings --> montre
// 4 - Settings montre --> GoPro
// 5 - Démarrage vidéo
// 6 - Hilight

// ===
// Data structure :
// ===
// [COM_TYPE, COM_DATA]



class MobileDevice {
    private var connected as Boolean;

    public function initialize() {
        connected = false;
    }

    public function connect() {
        Communications.registerForPhoneAppMessages(method(:onReceive) as Communications.PhoneMessageCallback);
        connected = true;
    }

    public function disconnect() {
        Communications.registerForPhoneAppMessages(null);
        connected = false;
    }

    public function isConnected() {
        return connected;
    }

    public function onReceive(message as Communications.PhoneAppMessage) {
        System.println(message.data);
        switch (message.data[0]) {
            case COM_CONNECT:
                // Ouverture connexion M>T>G>T>M
                if (message.data[1] == 0) {
                    var _view = new GoProRemoteView();
                    WatchUi.pushView(_view, new GoProRemoteDelegate(_view), WatchUi.SLIDE_LEFT);
                    cam.setConnected(true);
                } else {
                    if (cam.isConnected()){
                        while (!onRemoteView) {
                            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                        }
                        WatchUi.popView(WatchUi.SLIDE_LEFT);
                        disconnect();
                    }
                    cam.setConnected(false);
                    var _view = new PopUpView("Unable to connect to GoPro", POP_ERROR);
                    WatchUi.pushView(_view, new PopUpDelegate(_view), WatchUi.SLIDE_IMMEDIATE);
                }
                break;
            
            case COM_FETCH_SETTINGS:
                // GoPro settings --> montre
                if (message.data[1]) {
                    cam.syncSettings(message.data[1]);
                }
                break;
            case COM_FETCH_STATES:
                if (message.data[1]) {
                    cam.syncStates(message.data[1]);
                }
                break;
            case COM_PROGRESS:
                cam.syncProgress(message.data[1]);
                break;
            default:
                break;
        }
        
    }

    public function send(data as Object) {
        Communications.transmit(data, {}, new MobileConnection());
    }
}

class MobileConnection extends Communications.ConnectionListener {
    public function initialize() {
        ConnectionListener.initialize();
    }

    public function onError() {
        // TODO

    }
}