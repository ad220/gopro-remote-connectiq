import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;


module InterfaceComponentsManager {
    
    const JTEXT_MID = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    (:initialized) var fontTiny as FontType;
    (:initialized) var fontSmall as FontType;
    (:initialized) var fontMedium as FontType;
    

    (:highend)
    function loadFonts() as Void {
        fontTiny = WatchUi.loadResource(Rez.Fonts.Tiny) as FontResource;
        fontSmall = WatchUi.loadResource(Rez.Fonts.Small) as FontResource;
        fontMedium = WatchUi.loadResource(Rez.Fonts.Medium) as FontResource;
    }
    
    (:lowend)
    function loadFonts() as Void{
        fontTiny = Graphics.FONT_XTINY;
        fontSmall = Graphics.FONT_TINY;
        fontMedium = WatchUi.loadResource(Rez.Fonts.Medium);
    }

    (:typecheck(false) :inline)
    function loadString(rez as Symbol) as String {
        return WatchUi.loadResource(Rez.Strings[rez]);
    }
}



