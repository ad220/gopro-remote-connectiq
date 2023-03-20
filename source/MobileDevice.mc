import Toybox.Communications;
import Toybox.Lang;

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
        Communications.registerForPhoneAppMessages(method(:onReceive));
    }

    public function onReceive(message as Communications.PhoneAppMessage) {
        message.data
        
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