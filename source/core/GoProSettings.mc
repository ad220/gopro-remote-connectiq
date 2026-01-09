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
        1   => [4000,   16 + 9  << 16],
        4   => [2700,   16 + 9  << 16],
        6   => [2700,   4  + 3  << 16],
        7   => [1440,   16 + 9  << 16],
        9   => [1080,   16 + 9  << 16],
        12  => [720,    16 + 9  << 16],
        18  => [4000,   4  + 3  << 16],
        21  => [5600,   360 << 16],
        24  => [5000,   16 + 9  << 16],
        25  => [5000,   4  + 3  << 16],
        26  => [5300,   8  + 7  << 16],
        27  => [5300,   4  + 3  << 16],
        28  => [4000,   8  + 7  << 16],
        31  => [8000,   360 << 16],
        35  => [5300,   21 + 9  << 16],
        36  => [4000,   21 + 9  << 16],
        37  => [4000,   1  + 1  << 16],
        38  => [900,    16 + 9  << 16],
        39  => [4000,   360 << 16],
        100 => [5300,   16 + 9  << 16],
        107 => [5300,   8  + 7  << 16],
        108 => [4000,   8  + 7  << 16],
        109 => [4000,   9  + 16 << 16],
        110 => [1080,   9  + 16 << 16],
        111 => [2700,   4  + 3  << 16],
        112 => [4000,   4  + 3  << 16],
        113 => [5300,   4  + 3  << 16],
    } as Dictionary<Char, [Number, Number]>;

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
    } as Dictionary<Char, Number>;

    public static const FRAMERATE_LABEL = WatchUi.loadResource(Rez.Strings._FPS) as String;

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
    } as Dictionary<LedId or Char, ResourceId>;

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
    } as Dictionary<LensId or Char, ResourceId>;

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
    } as Dictionary<HypersmoothId or Char, ResourceId>;

    protected var settings as Dictionary<SettingId, Char>;

    function initialize() {
        self.settings = {} as Dictionary<SettingId, Char>;
    }

    public function getSetting(id as SettingId) as Char? {
        return settings.get(id);
    }

    public function getSettings() as Dictionary<SettingId, Char> {
        return settings;
    }

    public static function getLabel(id as GoProSettings.SettingId, setting as Char?) as String or ResourceId {
        var label = "";

        if (setting == null) {
            setting = getApp().gopro.getSetting(id);
            if (setting == null) { return label; }
        }

        if (id <= RESOLUTION)   {
            var tuple = RESOLUTION_MAP.get(setting);
            if (tuple == null) { return label; }

            // Resolution label
            if (id == RESOLUTION) {
                var res = tuple[0];
                if (res < 2000) {
                    return res + "p";
                } else {
                    return res%1000==0 ? res/1000+"K" : (res/1000.0).format("%.1f")+"K"; 
                }
            
            // Ratio label
            } else {
                var ratio = tuple[1];
                if (ratio & 0xFFFF != 0) {
                    return ratio & 0xFF + ":" + ratio >> 16;
                } else {
                    return ratio >> 16 + "°";
                }
            }
        }
        else if (id == LENS)         { label = LENS_LABELS.get(setting); }
        else if (id == FRAMERATE)    {
            var fps = FRAMERATE_MAP.get(setting);
            return fps != null ? fps + FRAMERATE_LABEL : "";
        }
        else if (id == LED)          { label = LED_LABELS.get(setting); }
        else if (id == HYPERSMOOTH)  { label = HYPERSMOOTH_LABELS.get(setting); }
        else {
            System.println("Unknown setting ID requested for label");
            return label;
        }
        
        return label == null ? "" : label;
        // TODO: error msg for unknown ids
    }

    public function getDescription() as String {
        if (settings.isEmpty() or settings.get(FRAMERATE)==null) {
            return ". . .";
        }
        var resId = settings.get(RESOLUTION);
        var res = getLabel(RESOLUTION, resId) as String;
        var fps = settings.get(FRAMERATE);
        if (fps!=null) { fps = FRAMERATE_MAP.get(fps); }
        var ratio = getLabel(RATIO, resId) as String;

        if (!res.equals("") and fps!=null and !ratio.equals("")) {
            return res + "@" + fps + " " + ratio;
        } else {
            return ". . .";
        }
    }
}

(:typecheck(false))
class ResolutionComparator {
    public function wrappedCompare(a as Char, b as Char, id as Number) as Numeric {
        var tupleA = GoProSettings.RESOLUTION_MAP.get(a);
        var tupleB = GoProSettings.RESOLUTION_MAP.get(b);

        if (tupleA == null) { tupleA = [0,0]; }
        if (tupleB == null) { tupleB = [0,0]; }

        if (id == 0) {
            return tupleB[0] - tupleA[0];
        } else {
            var ratioA = tupleA[1];
            var ratioB = tupleB[1];
            return (ratioA & 0xFFFF / (ratioA >> 16).toFloat()) - (ratioB & 0xFFFF / (ratioB >> 16).toFloat());
        }
    }

    public function compare(resolutionA, resolutionB) as Numeric {
        return wrappedCompare(resolutionA as Char, resolutionB as Char, 0);
    }
}

(:typecheck(false))
class RatioComparator extends ResolutionComparator {
    public function compare(ratioA, ratioB) as Numeric {
        return (wrappedCompare(ratioA as Char, ratioB as Char, 1)*10);
    }
}

(:typecheck(false))
class FramerateComparator {
    public function compare(framerateA, framerateB) as Numeric {
        var a = GoProSettings.FRAMERATE_MAP.get(framerateA as Char);
        var b = GoProSettings.FRAMERATE_MAP.get(framerateB as Char);

        if (a == null) { a=0; }
        if (b == null) { b=0; }
        
        return b-a;
    }
}