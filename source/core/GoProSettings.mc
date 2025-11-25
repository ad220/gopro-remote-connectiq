import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class GoProSettings {

    public enum SettingId {
        RESOLUTION  = 2,
        FRAMERATE   = 3,
        GPS         = 83,
        LED         = 91,
        LENS        = 121,
        FLICKER     = 134,
        HYPERSMOOTH = 135,

        RATIO = -1
    }

    public static const RESOLUTION_MAP = {
        1   => [4000, 16.9],
        4   => [2700, 16.9],
        6   => [2700, 4.3],
        7   => [1440, 16.9],
        9   => [1080, 16.9],
        12  => [720, 16.9],
        18  => [4000, 4.3],
        21  => [5600, 360],
        24  => [5000, 16.9],
        25  => [5000, 4.3],
        26  => [5300, 8.7],
        27  => [5300, 4.3],
        28  => [4000, 8.7],
        31  => [8000, 360],
        35  => [5300, 21.9],
        36  => [4000, 21.9],
        37  => [4000, 1.1],
        38  => [900, 16.9],
        39  => [4000, 360],
        100 => [5300, 16.9],
        107 => [5300, 8.7],
        108 => [4000, 8.7],
        109 => [4000, 9.16],
        110 => [1080, 9.16],
        111 => [2700, 4.3],
        112 => [4000, 4.3],
        113 => [5300, 4.3],
    };

    public static const FRAMERATE_MAP = {
        0  => 240,
        1  => 120,
        2  => 100,
        3  => 90,
        5  => 60,
        6  => 50,
        8  => 30,
        9  => 25,
        10 => 24,
        13 => 200,
        15 => 400,
        16 => 360,
        17 => 300,
    };

    public static const FRAMERATE_LABEL = WatchUi.loadResource(Rez.Strings._FPS);

    public enum LedId {
        LED_OFF         = 0,
        LED_ON          = 2,
        LED_ALL_ON      = 3,
        LED_ALL_OFF     = 4,
        LED_FRONT_OFF   = 5,
        LED_BACK_ONLY   = 100,
    }

    public static const LED_LABELS = {
        LED_OFF         => Rez.Strings.Off,
        LED_ON          => Rez.Strings.On,
        LED_ALL_ON      => Rez.Strings.AllOn,
        LED_ALL_OFF     => Rez.Strings.AllOff,
        LED_FRONT_OFF   => Rez.Strings.FrontOffOnly,
        LED_BACK_ONLY   => Rez.Strings.BackOnly,
    };

    public enum LensId {
        WIDE            = 0,
        NARROW          = 2,
        SUPERVIEW       = 3,
        LINEAR          = 4,
        MAXSUPERVIEW    = 7,
        LINEARLEVEL     = 8,
        HYPERVIEW       = 9,
        LINEARLOCK      = 10,
        MAXHYPERVIEW    = 11,
        ULTRASUPERVIEW  = 12,
        ULTRAWIDE       = 13,
        ULTRALINEAR     = 14,
        ULTRAHYPERVIEW  = 104,
    }

    public static const LENS_LABELS = {
        WIDE            => Rez.Strings._WIDE,
        NARROW          => Rez.Strings._NARROW,
        SUPERVIEW       => Rez.Strings._SUPERVIEW,
        LINEAR          => Rez.Strings._LINEAR,
        MAXSUPERVIEW    => Rez.Strings._MAXSUPERVIEW,
        LINEARLEVEL     => Rez.Strings._LINEARLEVEL,
        HYPERVIEW       => Rez.Strings._HYPERVIEW,
        LINEARLOCK      => Rez.Strings._LINEARLOCK,
        MAXHYPERVIEW    => Rez.Strings._MAXHYPERVIEW,
        ULTRASUPERVIEW  => Rez.Strings._ULTRASUPERVIEW,
        ULTRAWIDE       => Rez.Strings._ULTRAWIDE,
        ULTRALINEAR     => Rez.Strings._ULTRALINEAR,
        ULTRAHYPERVIEW  => Rez.Strings._ULTRAHYPERVIEW,
    };

    public enum FlickerId {
        NTSC,
        PAL,
        HZ60,
        HZ50
    }

    public enum HypersmoothId {
        HS_OFF          = 0,
        HS_LOW,
        HS_HIGH,
        HS_BOOST,
        HS_AUTO_BOOST,
        HS_STANDARD     = 100,
    }

    public static const HYPERSMOOTH_LABELS = {
        HS_OFF          => Rez.Strings.Disabled,
        HS_LOW          => Rez.Strings.Low,
        HS_HIGH         => Rez.Strings.High,
        HS_BOOST        => Rez.Strings.Boost,
        HS_AUTO_BOOST   => Rez.Strings.AutoBoost,
        HS_STANDARD     => Rez.Strings.Standard,
    };

    protected var settings = {} as Dictionary;

    function initialize() {
        self.settings = {};
    }

    public function getSetting(id as SettingId) as Char? {
        return settings.get(id);
    }

    public function getSettings() as Dictionary {
        return settings;
    }

    public static function getLabel(id as GoProSettings.SettingId, setting as Char?) as String or ResourceId {
        try {
            if (setting == null) {
                setting = getApp().gopro.getSetting(id);
            }
            switch (id) {
                case RESOLUTION:
                    var res = (RESOLUTION_MAP.get(setting) as Array)[0];
                    if (res < 2000) {
                        return res + "p";
                    } else {
                        return res%1000==0 ? res/1000+"K" : (res/1000.0).format("%.1f")+"K"; 
                    }
                case RATIO:
                    var ratio = (RESOLUTION_MAP.get(setting) as Array)[1];
                    if (ratio<45) {
                        ratio = ratio.format("%.2f");
                        return ratio.substring(null, ratio.find(".")) + ":" + ratio.substring(ratio.find(".")+1, ratio.find("0"));
                    } else {
                        return ratio + "°";
                    }
                case LENS:
                    return LENS_LABELS.get(setting);
                case FRAMERATE:
                    return FRAMERATE_MAP.get(setting) + FRAMERATE_LABEL;
                case LED:
                    return LED_LABELS.get(setting);
                case HYPERSMOOTH:
                    return HYPERSMOOTH_LABELS.get(setting);
                default:
                    System.println("Unknown setting ID requested for label");
                    return "";
            }
        } catch (ex) {
            System.println("Error while retrieving setting label");
            System.println(ex.getErrorMessage());
            return ". . .";
        }
    }

    public function getDescription() as String {
        if (settings.isEmpty()) {
            return ". . .";
        }
        return getLabel(RESOLUTION, null) \
                + "@" + FRAMERATE_MAP.get(settings.get(FRAMERATE)) \
                + " " + getLabel(RATIO, null);
    }
}

class ResolutionComparator {
    public function compare(resolutionA as Char, resolutionB as Char) as Number {
        return (GoProSettings.RESOLUTION_MAP.get(resolutionB) as Array)[0] as Number - (GoProSettings.RESOLUTION_MAP.get(resolutionA) as Array)[0] as Number;
    }
}

class RatioComparator {
    public function compare(ratioA as Char, ratioB as Char) as Number {
        return (GoProSettings.RESOLUTION_MAP.get(ratioB) as Array)[1] as Number - (GoProSettings.RESOLUTION_MAP.get(ratioA) as Array)[1] as Number;
    }
}

class FramerateComparator {
    public function compare(framerateA as Char, framerateB as Char) {
        return GoProSettings.FRAMERATE_MAP.get(framerateB) as Number - GoProSettings.FRAMERATE_MAP.get(framerateA) as Number;
    }
}