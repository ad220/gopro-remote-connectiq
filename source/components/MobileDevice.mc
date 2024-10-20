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
        System.println("received: " + message.data.toString());
        var data = message.data as Array<Number or Array<Number or Array<Number>>>;
        switch (data[0]) {
            case COM_CONNECT:
                // Ouverture connexion M>T>G>T>M
                if (data[1] == 0) {
                    var _view = new RemoteView();
                    GoProRemoteApp.pushView(_view, new RemoteDelegate(_view), WatchUi.SLIDE_LEFT, false);
                    cam.setConnected(true);
                } else {
                    if (cam.isConnected()){
                        while (nViewLayers > 1) {
                            GoProRemoteApp.popView(WatchUi.SLIDE_IMMEDIATE);
                        }
                        GoProRemoteApp.popView(WatchUi.SLIDE_LEFT);
                        disconnect();
                    }
                    cam.setConnected(false);
                    GoProRemoteApp.pushView(new PopUpView(MainResources.labels[UI_CONNECT][CONNECTFAIL], POP_ERROR), new PopUpDelegate(), WatchUi.SLIDE_BLINK, false);
                }
                break;
            
            case COM_FETCH_SETTINGS:
                // GoPro settings --> montre
                if (data[1]) {
                    cam.syncSettings(data[1]);
                }
                break;
            case COM_FETCH_STATES:
                if (data[1]) {
                    cam.syncStates(data[1]);
                }
                break;
            case COM_FETCH_AVAILABLE:
                if (data[1]) {
                    cam.syncAvailableSettings(data[1]);
                }
                break;
            case COM_PROGRESS:
                cam.syncProgress(data[1]);
                break;
            default:
                break;
        }
        
    }

    public function send(data as Object) {
        System.println("sending: " + data.toString());
        Communications.transmit(data, {}, new MobileConnection());
    }
}

class MobileConnection extends Communications.ConnectionListener {
    public function initialize() {
        ConnectionListener.initialize();
    }

    public function onError() {
        System.println("Error on MobileConnection");
    }
}