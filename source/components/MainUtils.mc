import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

const JTEXT_MID = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

function adaptFontSmall() as FontResource {
    return kMult<=1 ? MainResources.fontTiny : MainResources.fontSmall;
}

function adaptFontMid() as FontResource {
    return kMult<=1 ? MainResources.fontSmall : MainResources.fontSmall;
}

class MainUtils {
    static function isValueInList(value, list) as Boolean { //list as Array
        for (var i=0; i<list.size(); i++) {
            if (value == list[i]) {
                return true;
            }
        }
        return false;
    }
}