import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;


module InterfaceComponentsManager {
    
    (:initialized) var screenH as Number;
    (:initialized) var screenW as Number;
    (:initialized) var halfH as Number;
    (:initialized) var halfW as Number;

    (:initialized) var fontTiny as FontType;
    (:initialized) var fontSmall as FontType;
    (:initialized) var fontMedium as FontType;
    
    const JTEXT_MID = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;


    function computeInterfaceConstants() as Void {
        var deviceSettings = System.getDeviceSettings();
        screenH = deviceSettings.screenHeight;
        screenW = deviceSettings.screenWidth;
        halfH = screenH / 2;
        halfW = screenW / 2;
    }

    (:highend)
    function loadFonts() as Void{
        fontTiny = WatchUi.loadResource(Rez.Fonts.Tiny);
        fontSmall = WatchUi.loadResource(Rez.Fonts.Small);
        fontMedium = WatchUi.loadResource(Rez.Fonts.Medium);
    }
    
    (:lowend)
    function loadFonts() as Void{
        fontTiny = Graphics.FONT_XTINY;
        fontSmall = Graphics.FONT_TINY;
        fontMedium = WatchUi.loadResource(Rez.Fonts.Medium);
    }
}



