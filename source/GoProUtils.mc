import Toybox.Lang;

class GoProUtils {
    static function isValueInList(value, list) as Boolean { //list as Array
        for (var i=0; i<list.size(); i++) {
            if (value == list[i]) {
                return true;
            }
        }
        return false;
    }
}