import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;


class Togglable extends WatchUi.Button {

    public var defaultState as ResourceId;
    public var enabledState as ResourceId;
    public var isEnabled as Boolean?;
    public var isHilighted as Boolean;

    (:typecheck(false))
    public function initialize(options) {
        Button.initialize(options);

        self.defaultState = options.get(:defaultBmpId) as ResourceId;
        self.enabledState = options.get(:enabledBmpId) as ResourceId;

        self.isHilighted = getState() == :stateHilighted;
        if (isHilighted) {
            setState(:stateDefault);
        }
    }

    public function draw(dc as Dc) as Void {
        Button.draw(dc);

        if (isHilighted) {
            if (dc has :setAntiAlias) {
                dc.setAntiAlias(true);
            }

            var radius = width/2.0;
            dc.setPenWidth(0.008*dc.getWidth());
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(locX+radius, locY+radius, radius);
        }
    }

    public function updateState() as Void {
        var enabled = getApp().gopro.isEnabled(identifier as GoProSettings.SettingId);
        if (isEnabled != enabled) {
            isEnabled = enabled;
            var rezId = enabled ? enabledState : defaultState;
            background = new Bitmap({:rezId => rezId, :locX => locX, :locY => locY});
        }
    }
}