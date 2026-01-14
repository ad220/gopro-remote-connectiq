import Toybox.Lang;
import Toybox.Test;
import Toybox.System;

(:test)
module HelperTest {
    
    (:test)
    function testSort(logger as Logger) as Boolean {
        var comparator = new Helper.NumericComparator();
        var array = [-12, 2.3, 0, -2, 7, 1, 1l << 48, 5.2d/42, -45, 0, -5.0];

        Helper.sort(array, comparator);
        
        var sortedArray = [-45, -12, -5.0, -2, 0, 0, 5.2d/42, 1, 2.3, 7, 1l<<48];

        for (var i=0; i<array.size(); i++) {
            if (array[i] != sortedArray[i]) {
                logger.error(
                    "Expecting sorted array: " + sortedArray + 
                    "\ngiven: " + array
                );
                return false;
            }
        }

        return true;
    }

    (:test)
    function testEmptySort(logger as Logger) as Boolean {
        var array = [];

        try {
            Helper.sort(array, null);
        } catch (ex) {
            logger.error(ex.getErrorMessage() + "");
            return false;
        }
        
        var result = array.size() == 0;
        if (!result) {
            logger.error("Empty array size changed suring sort");
        }
        return result;
    }
}