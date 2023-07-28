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
    public function initialize() {
        Communications.registerForPhoneAppMessages(method(:onReceive) as Communications.PhoneMessageCallback);
    }

    public function onReceive(message as Communications.PhoneAppMessage) {
        // System.print(message.data);
        switch (message.data[0]) {
            case COM_CONNECT:
                // Ouverture connexion M>T>G>T>M
                if (message.data[1] == 0) {
                    var _view = new GoProRemoteView();
                    WatchUi.pushView(_view, new GoProRemoteDelegate(_view), WatchUi.SLIDE_LEFT);
                } else {
                    while (!onRemoteView) {
                        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                    }
                    WatchUi.popView(WatchUi.SLIDE_LEFT);
                    var _view = new PopUpView("Unable to connect to GoPro", POP_ERROR);
                    WatchUi.pushView(_view, new PopUpDelegate(_view), WatchUi.SLIDE_IMMEDIATE);
                }
                break;
            
            case COM_FETCH_SETTINGS:
                // GoPro settings --> montre
                System.print(message.data);
                if (message.data[1]) {
                    cam.syncSettings(message.data[1]);
                }
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

    }
}