import Toybox.Lang;

using ErrorManager as EM;

module Helper {
    (:mobile)
    function customSort(array as Array, comp as Lang.Comparator?) as Void {
        if (comp == null) {
            comp = new NumericComparator();
        }

        var sortedArray = [] as Array<Object?>;

        while (array.size() > 0) {
            var j = 0;
            while (
                j < sortedArray.size() and
                comp.compare(sortedArray[j] as Object, array[0] as Object) < 0
            ) { j++; }

            sortedArray = sortedArray.slice(0, j).add(array[0] as Object).addAll(sortedArray.slice(j, sortedArray.size()));
            array.remove(array[0] as Object);
        }
        array.addAll(sortedArray);
    }

    (:ble :inline)
    function customSort(array as Array, comp as Lang.Comparator?) as Void {
        array.sort(comp);
    }

    (:typecheck(false))
    function safeGoProAccess(callsiteIdx as Number?) as GoProCamera? {
        var camera = getApp().gopro;

        if (! (camera instanceof GoProCamera) and callsiteIdx != null) {
            EM.raise(EM.ERR_NULL, callsiteIdx, :CriticalErr);
        }
        return camera;
    }

    (:inline)
    function createNullObject() as Object? {
        return null;
    }

    (:mobile)
    class NumericComparator {

        function compare(a as Object, b as Object) as Number {
            if (a as Numeric? == null) { a = 0; }
            if (b as Numeric? == null) { b = 0; }
            return a >= b ? 1 : -1;
        }
    }
}