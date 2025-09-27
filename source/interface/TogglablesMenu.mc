import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

class Togglable extends WatchUi.Button {

    private var isHilighted as Boolean;

    public function initialize(options) {
        Button.initialize(options);
        isHilighted = getState() == :stateHilighted;
    }

    public function draw(dc as Dc) as Void {
        Button.draw(dc);

        if (isHilighted) {
            if (dc has :setAntiAlias) {
                dc.setAntiAlias(true);
            }

            var radius = width/2;
            dc.setPenWidth(2*ICM.kMult);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(locX+radius, locY+radius, radius);
        }
    }

    public function hilight() as Void {
        isHilighted = true;
    }

    public function unhilight() as Void {
        isHilighted = false;
    }
}

class TogglablesMenu extends WatchUi.View {
    public function initialize() {
        View.initialize();
    }

    public function onLayout(dc as Dc) as Void {
        System.println("T.onLayout");
        setLayout(Rez.Layouts.TogglablesLayout(dc));
    }

    public function onShow() as Void {
        System.println("T.onShow");
        View.onShow();
        setKeyToSelectableInteraction(true);
    }

    public function onUpdate(dc as Dc) as Void {
        System.println("T.onUpdate");
        View.onUpdate(dc);
    }
}

class TogglablesDelegate extends WatchUi.BehaviorDelegate {

    private var currentHilight as Togglable?;

    public function initialize() {
        BehaviorDelegate.initialize();
    }

    public function onSelectable(selectableEvent as SelectableEvent) as Boolean {
        var button = selectableEvent.getInstance();
        if (button instanceof Togglable) {
            if (button.getState()==:stateHighlighted) {
                button.setState(selectableEvent.getPreviousState());
                button.hilight();

                if (currentHilight!=null) {
                    currentHilight.unhilight();
                }
                currentHilight = button;
            }
        }
        return true;
    }
}