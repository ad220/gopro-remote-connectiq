import Toybox.WatchUi;


// private static const modeList = ["Video", ]
const resolutionList = [:_5K, :_4K, :_3K, :_2K];
const ratioList = [:_8R7, :_4R3, :_16R9];
const lensList = [:_HyperView, :_SuperView, :_Large, :_Linear, :_LinearLock];
const framerateList = [:_240,:_120,:_60,:_30,:_24]; //TODO: convert NTSC fps -> PAL fps

const settingTitle = {
    :resolution => WatchUi.loadResource(Rez.Strings.Resolution),
    :ratio => WatchUi.loadResource(Rez.Strings.Ratio),
    :lens => WatchUi.loadResource(Rez.Strings.Lens),
    :framerate => WatchUi.loadResource(Rez.Strings.Framerate),
};

const settingLabel = {
    // Resolutions
    :_5K => WatchUi.loadResource(Rez.Strings._5K),
    :_4K => WatchUi.loadResource(Rez.Strings._4K),
    :_3K => WatchUi.loadResource(Rez.Strings._3K),
    :_2K => WatchUi.loadResource(Rez.Strings._2K),
    // Aspect Ratios
    :_8R7 => WatchUi.loadResource(Rez.Strings._8R7),
    :_4R3 => WatchUi.loadResource(Rez.Strings._4R3),
    :_16R9 => WatchUi.loadResource(Rez.Strings._16R9),
    // Framerates
    :_240 => WatchUi.loadResource(Rez.Strings._240),
    :_200 => WatchUi.loadResource(Rez.Strings._200),
    :_120 => WatchUi.loadResource(Rez.Strings._120),
    :_100 => WatchUi.loadResource(Rez.Strings._100),
    :_60 => WatchUi.loadResource(Rez.Strings._60),
    :_50 => WatchUi.loadResource(Rez.Strings._50),
    :_30 => WatchUi.loadResource(Rez.Strings._30),
    :_25 => WatchUi.loadResource(Rez.Strings._25),
    :_24 => WatchUi.loadResource(Rez.Strings._24),
    // Lenses 
    :_HyperView => WatchUi.loadResource(Rez.Strings.HyperView),
    :_SuperView => WatchUi.loadResource(Rez.Strings.SuperView),
    :_Large => WatchUi.loadResource(Rez.Strings.Large),
    :_Linear => WatchUi.loadResource(Rez.Strings.Linear),
    :_LinearLock => WatchUi.loadResource(Rez.Strings.LinearLock)
};

const icon = {
    :resolution => WatchUi.loadResource(Rez.Drawables.Resolution),
    :ratio => WatchUi.loadResource(Rez.Drawables.Ratio),
    :lens => WatchUi.loadResource(Rez.Drawables.Lens),
    :framerate => WatchUi.loadResource(Rez.Drawables.Framerate)
};


class GoProResources {
    static public var fontTiny;
    static public var fontSmall;
    static public var fontMedium;
    static public var fontLarge;

    static public function load() {
        fontTiny = WatchUi.loadResource(Rez.Fonts.Tiny);
        fontSmall = WatchUi.loadResource(Rez.Fonts.Small);
        fontMedium = WatchUi.loadResource(Rez.Fonts.Medium);
        fontLarge = WatchUi.loadResource(Rez.Fonts.Large);
    }
}

