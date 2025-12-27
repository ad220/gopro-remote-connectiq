import Toybox.Lang;

module Helper {
    function sort(array as Array, comp as CustomComparator?) as Void {
        if (comp == null) {
            comp = new NumericComparator();
        }

        var sortedArray = [] as Array<Object?>;
        while (array.size()>0) {
            var j = 0;
            while (
                j<sortedArray.size() and
                comp.compare(array[0] as Object, sortedArray[j] as Object) > 0
            ) { j++; }

            sortedArray = sortedArray.slice(0, j).add(array[0] as Object).addAll(sortedArray.slice(j, sortedArray.size()));
            array.remove(array[0] as Object);
        }
        array.addAll(sortedArray);
    }

    typedef CustomComparator as interface {
        function compare(a, b) as Numeric;
    };

    class NumericComparator {
        (:typecheck(false))
        function compare(a, b) as Numeric {
            if (a == null) { a=0; }
            if (b == null) { b=0; }
            return a - b;
        }
    }
}