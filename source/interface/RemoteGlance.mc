import Toybox.System;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

class RemoteGlance extends WatchUi.GlanceView {

    public function initialize() {
        GlanceView.initialize();
    }

    public function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.GlanceLayout(dc));
    }
}