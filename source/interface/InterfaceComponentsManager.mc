import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Math;


module InterfaceComponentsManager {
    
    var screenH as Number?;
    var screenW as Number?;
    var halfH as Number?;
    var halfW as Number?;
    var kMult as Float?; // compared to 240x240 screen
    var imgOff as Float?;

    var fontTiny as FontResource?;
    var fontSmall as FontResource?;
    var fontMedium as FontResource?;
    
    const JTEXT_MID = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;


    function computeInterfaceConstants() {
        var deviceSettings = System.getDeviceSettings();
        screenH = deviceSettings.screenHeight;
        screenW = deviceSettings.screenWidth;
        halfH = screenH / 2;
        halfW = screenW / 2;
        kMult = (screenH / 120)*0.5;
        if (kMult < 1) {kMult = 1.0;}
        imgOff = 0.05*screenH-12*kMult;
    }

    function loadFonts() as Void{
        fontTiny = WatchUi.loadResource(Rez.Fonts.Tiny);
        fontSmall = WatchUi.loadResource(Rez.Fonts.Small);
        fontMedium = WatchUi.loadResource(Rez.Fonts.Medium);
    }

    function scaleX(xRel as Float) as Number {
        return Math.round(xRel*screenW).toNumber();
    }
    
    function scaleY(yRel as Float) as Number {
        return Math.round(yRel*screenH).toNumber();
    }
}



