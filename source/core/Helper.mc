import Toybox.Lang;

module Helper {
    function sort(array as Array, comp as Comparator) {
        var sortedArray = [];
        while (array.size()>0) {
            var j = 0;
            while (j<sortedArray.size() and comp.compare(array[0], sortedArray[j])>0) { j++; }
            sortedArray = sortedArray.slice(0, j).add(array[0]).addAll(sortedArray.slice(j, sortedArray.size()));
            array.remove(array[0]);
        }
        array.addAll(sortedArray);
    }


    class Comparator {
        public function compare(a, b) {}
    }
}