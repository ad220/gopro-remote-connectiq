import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

(:highend)
class ConnectView extends WatchUi.View {

    private var label as String;
    private var delegate as ConnectDelegate;

    function initialize(label as String, delegate as ConnectDelegate) {
        View.initialize();

        self.label = label;
        self.delegate = delegate;
    }

    public function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.ConnectLayout(dc));
    }


    function onShow() as Void {
        if (getApp().fromGlance) {
            delegate.onSelect();
        }
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

        (findDrawableById("ConnectLabel") as Text).setText(label);
        View.onUpdate(dc);
    }
}
