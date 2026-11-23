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

    function newCustomMenu(itemHeight as Float, titleHeight as Float?) as CustomMenu {
        var options = titleHeight != null ? {:titleItemHeight => (titleHeight*Screen.HEIGHT).toNumber()<<1} : null;
        return new WatchUi.CustomMenu((itemHeight*Screen.HEIGHT).toNumber() << 1, Graphics.COLOR_BLACK, options);
    }

    function toggleOrPick(id as GoProSettings.SettingId) as Void {
        var app = getApp();

        var available = app.gopro.getAvailableSettings(id); 

        if (available.size() > 2) {
            var newMenu = newCustomMenu(0.1, 0.15);
            app.viewController.push(newMenu, new SettingPickerDelegate(newMenu, id), WatchUi.SLIDE_LEFT);
        }
        else {
            app.gopro.toggleSetting(id);
        }
    }
}



