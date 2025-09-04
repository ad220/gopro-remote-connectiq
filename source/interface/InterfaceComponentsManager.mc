import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;


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
    var fontLarge as FontResource?;
    
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
        fontLarge = WatchUi.loadResource(Rez.Fonts.Large);
    }
    
    // TODO: replace with font resource override by screen size
    function adaptFontSmall() as FontResource {
        return kMult<=1 ? fontTiny : fontSmall;
    }

    public function adaptFontMid() as FontResource {
        return kMult<=1 ? fontSmall : fontMedium;
    }
}



