import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class GoProSettings {

    public enum SettingId {
        RESOLUTION  = 2,
        FRAMERATE   = 3,
        LENS        = 121,
        FLICKER     = 134,

        RATIO = -1
    }

    public static const RESOLUTION_MAP = {
        1   => [:_4K, :_16R9],
        4   => [:_2K7, :_16R9],
        6   => [:_2K7, :_4R3],
        7   => [:_1440, :_16R9],
        9   => [:_1080, :_16R9],
        12  => [:_720, :_16R9],
        18  => [:_4K, :_4R3],
        24  => [:_5K, :_16R9],
        25  => [:_5K, :_4R3],
        26  => [:_5K3, :_8R7],
        27  => [:_5K3, :_4R3],
        28  => [:_4K, :_8R7],
        35  => [:_5K3, :_21R9],
        36  => [:_4K, :_21R9],
        37  => [:_4K, :_1R1],
        38  => [:_900, :_16R9],
        100 => [:_5K3, :_16R9],
        107 => [:_5K3, :_8R7],
        108 => [:_4K, :_8R7],
        109 => [:_4K, :_9R16],
        110 => [:_1080, :_9R16],
        111 => [:_2K7, :_4R3],
        112 => [:_4K, :_4R3],
        113 => [:_5K3, :_4R3],
    };

    public static const RESOLUTION_SORT_MAP = {
        26  => 0,   // 5K3, 8R7
        107 => 1,   // 5K3, 8R7
        27  => 2,   // 5K3, 4R3
        113 => 3,   // 5K3, 4R3
        100 => 4,   // 5K3, 16R9
        35  => 5,   // 5K3, 21R9
        25  => 6,   // 5K, 4R3
        24  => 7,   // 5K, 16R9
        37  => 8,   // 4K, 1R1
        28  => 9,   // 4K, 8R7
        108 => 10,  // 4K, 8R7
        18  => 11,  // 4K, 4R3
        112 => 12,  // 4K, 4R3
        1   => 13,  // 4K, 16R9
        109 => 14,  // 4K, 9R16
        36  => 15,  // 4K, 21R9
        6   => 16,  // 2K7, 4R3
        111 => 17,  // 2K7, 4R3
        4   => 18,  // 2K7, 16R9
        7   => 19,  // 1440, 16R9
        9   => 20,  // 1080, 16R9
        110 => 21,  // 1080, 9R16
        38  => 22,  // 900, 16R9
        12  => 23,  // 720, 16R9
    };

    public static const RESOLUTION_LABELS = {
        :_5K3   => WatchUi.loadResource(Rez.Strings._5K3),
        :_5K    => WatchUi.loadResource(Rez.Strings._5K),
        :_4K    => WatchUi.loadResource(Rez.Strings._4K),
        :_2K7   => WatchUi.loadResource(Rez.Strings._2K7),
        :_1440  => WatchUi.loadResource(Rez.Strings._1440),
        :_1080  => WatchUi.loadResource(Rez.Strings._1080),
        :_900   => WatchUi.loadResource(Rez.Strings._900),
        :_720   => WatchUi.loadResource(Rez.Strings._720)
    };

    public static const RATIO_LABELS = {
        :_8R7   => WatchUi.loadResource(Rez.Strings._8R7),
        :_4R3   => WatchUi.loadResource(Rez.Strings._4R3),
        :_16R9  => WatchUi.loadResource(Rez.Strings._16R9),
        :_9R16  => WatchUi.loadResource(Rez.Strings._9R16),
        :_21R9  => WatchUi.loadResource(Rez.Strings._21R9)
    };

    public static const FRAMERATE_MAP = {
        0  => 240,
        1  => 120,
        2  => 100,
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
        WIDE            => WatchUi.loadResource(Rez.Strings._WIDE),
        NARROW          => WatchUi.loadResource(Rez.Strings._NARROW),
        SUPERVIEW       => WatchUi.loadResource(Rez.Strings._SUPERVIEW),
        LINEAR          => WatchUi.loadResource(Rez.Strings._LINEAR),
        MAXSUPERVIEW    => WatchUi.loadResource(Rez.Strings._MAXSUPERVIEW),
        LINEARLEVEL     => WatchUi.loadResource(Rez.Strings._LINEARLEVEL),
        HYPERVIEW       => WatchUi.loadResource(Rez.Strings._HYPERVIEW),
        LINEARLOCK      => WatchUi.loadResource(Rez.Strings._LINEARLOCK),
        MAXHYPERVIEW    => WatchUi.loadResource(Rez.Strings._MAXHYPERVIEW),
        ULTRASUPERVIEW  => WatchUi.loadResource(Rez.Strings._ULTRASUPERVIEW),
        ULTRAWIDE       => WatchUi.loadResource(Rez.Strings._ULTRAWIDE),
        ULTRALINEAR     => WatchUi.loadResource(Rez.Strings._ULTRALINEAR),
        ULTRAHYPERVIEW  => WatchUi.loadResource(Rez.Strings._ULTRAHYPERVIEW),
    };

    public enum Flicker {
        NTSC,
        PAL,
        HZ50,
        HZ60
    }

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

    public static function getLabel(settingId as GoProSettings.SettingId, setting as Char) as String {
        try {
            switch (settingId) {
                case RESOLUTION:
                    var resolution = RESOLUTION_MAP.get(setting);
                    if (resolution instanceof Array) {
                        return RESOLUTION_LABELS.get(resolution[0]);
                    }
                    return "";
                case LENS:
                    return LENS_LABELS.get(setting);
                case FRAMERATE:
                    return FRAMERATE_MAP.get(setting) + FRAMERATE_LABEL;
                case RATIO:
                    var ratio = RESOLUTION_MAP.get(setting);
                    if (ratio instanceof Array) {
                        return RATIO_LABELS.get(ratio[1]);
                    }
                    return "";
                default:
                    System.println("Unknown setting ID requested for label");
                    return "";
            }
        } catch (ex) {
            System.println("Error while retrieving setting label");
            return "...";
        }
    }

    public function getDescription() as String {
        if (settings.isEmpty()) {
            return "...";
        }
        return getLabel(RESOLUTION, settings.get(RESOLUTION)) \
                + "@" + FRAMERATE_MAP.get(settings.get(FRAMERATE)) \
                + " " + getLabel(RATIO, settings.get(RATIO));
    }

    public function save() {
        // Implemented in subclasses
    }
}

class ResolutionComparator {
    public function compare(resolutionA as Char, resolutionB as Char) as Number {
        return GoProSettings.RESOLUTION_SORT_MAP.get(resolutionA) as Number - GoProSettings.RESOLUTION_SORT_MAP.get(resolutionB) as Number;
    }
}

class LensComparator {
    public function compare(lensA as Char, lensB as Char) as Number {
        return (GoProSettings.LENS_LABELS.get(lensA) as String).compareTo(GoProSettings.LENS_LABELS.get(lensB) as String);
    }
}

class FramerateComparator {
    public function compare(framerateA as Char, framerateB as Char) {
        return GoProSettings.FRAMERATE_MAP.get(framerateA) as Number - GoProSettings.FRAMERATE_MAP.get(framerateB) as Number;
    }
}