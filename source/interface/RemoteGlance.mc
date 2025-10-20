import Toybox.System;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;

using InterfaceComponentsManager as ICM;

(:glance)
class RemoteGlance extends WatchUi.GlanceView {

    private var title as String;
    private var subtitle as String;

    public function initialize(subtitle as String) {
        GlanceView.initialize();

        self.title = loadResource(Rez.Strings.GlanceTitle);
        self.subtitle = subtitle;
    }

    public function onUpdate(dc as Dc) as Void {
        GlanceView.onUpdate(dc);
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, 0.2*dc.getHeight(), Graphics.FONT_GLANCE, title, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(0, 0.55*dc.getHeight(), Graphics.FONT_GLANCE, subtitle, Graphics.TEXT_JUSTIFY_LEFT);
    }
}