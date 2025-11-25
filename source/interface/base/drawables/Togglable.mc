import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;


class Togglable extends WatchUi.Button {

    public var defaultState as ResourceId;
    public var activatedState as ResourceId;
    private var isActivated as Boolean;
    public var isHilighted as Boolean;

    public function initialize(options as Dictionary) {
        Button.initialize(options);

        self.defaultState = options.get(:defaultBmpId) as ResourceId;
        self.activatedState = options.get(:activatedBmpId) as ResourceId;
        toggleState(false);

        self.isActivated = false;
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

            var radius = width/2;
            dc.setPenWidth(0.008*dc.getWidth());
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(locX+radius, locY+radius, radius);
        }
    }

    public function toggleState(isActivated as Boolean) as Void {
        if (self.isActivated!=isActivated) {
            self.isActivated = isActivated; 
            var rezId = isActivated ? activatedState : defaultState;
            background = new Bitmap({:rezId=>rezId, :locX=>locX, :locY=>locY});
        }
    }
}