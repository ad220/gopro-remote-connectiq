import Toybox.Lang;

module Helper {
    (:mobile)
    function sort(array as Array, comp as Lang.Comparator?) as Void {
        if (comp == null) {
            comp = new NumericComparator();
        }

        var sortedArray = []b;
        while (array.size()>0) {
            var j = 0;
            while (
                j<sortedArray.size() and
                comp.compare(array[0], sortedArray[j]) < 0
            ) { j++; }

            sortedArray = sortedArray.slice(0, j).add(array[0]).addAll(sortedArray.slice(j, sortedArray.size()));
            array.remove(array[0]);
        }
        array.addAll(sortedArray);
    }

    (:ble :inline)
    function sort(array as Array, comp as Lang.Comparator?) as Void {
        array.sort(comp);
    }

    (:mobile)
    class NumericComparator {

        function compare(a as Object, b as Object) as Number {
            if (a as Numeric? == null) { a = 0; }
            if (b as Numeric? == null) { b = 0; }
            return (1000 * b - 1000 * a).toNumber();
        }
    }
}