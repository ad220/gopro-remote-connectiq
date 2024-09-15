import Toybox.WatchUi;
import Toybox.Lang;

enum ConnectLabels {
    CONNECT,
    CONNECTING,
    CONNECTFAIL
}

const N_EDITABLES = 5;
enum Editables {
    PSET1,
    PSET2,
    PSET3,
    CAM,
    SAVEP7
}

const N_SETTINGS = 4;
enum Settings {
    RESOLUTION,
    RATIO,
    LENS,
    FRAMERATE
}

const N_STATES = 1;
enum States {
    REGION,
    RECORDING
}

enum UserInterface {
    UI_CONNECT,
    UI_HILIGHT,
    UI_STATES,
    UI_MENUS,
    UI_SETTINGSMENU,
    UI_SETTINGEDIT
}

enum Menus {
    SETTINGS,
    PRESETS,
    EDIT
}

// Settings enums
enum Resolutions {
    _5K,
    _4K,
    _2K7,
    _1440,
    _1080,
}

enum Ratios {
    _8R7,
    _4R3,
    _16R9
}

enum Lenses {
    _HYPERVIEW,
    _SUPERVIEW,
    _LARGE,
    _LINEAR,
    _LINEARLOCK
}

enum Framerate {
    _240,
    _120,
    _60,
    _30,
    _24
}

// States enums
enum Region {
    NTSC,
    PAL
}

enum Communication {
    COM_CONNECT,
    COM_FETCH_SETTINGS,
    COM_PUSH_SETTINGS,
    COM_FETCH_STATES,
    COM_PUSH_STATES,
    COM_FETCH_AVAILABLE,
    COM_PUSH_AVAILABLE,
    COM_SHUTTER,
    COM_HIGHLIGHT,
    COM_LOCKED,
    COM_PROGRESS
}

enum PopUpType {
    POP_INFO,
    POP_ERROR
}


class MainResources {
    static public var fontTiny as FontResource?;
    static public var fontSmall as FontResource?;
    static public var fontMedium as FontResource?;
    static public var fontLarge as FontResource?;

    static public function loadFonts() as Void{
        fontTiny = WatchUi.loadResource(Rez.Fonts.Tiny);
        fontSmall = WatchUi.loadResource(Rez.Fonts.Small);
        fontMedium = WatchUi.loadResource(Rez.Fonts.Medium);
        fontLarge = WatchUi.loadResource(Rez.Fonts.Large);
    }

    static public var labels as Array<Array<String>?> = [null, null, null, null, null, null];

    static public function loadLabels(id as Number) as Void{
        if (labels[id]==null) {
            if (id == UI_CONNECT) {
                labels[id] = [
                    WatchUi.loadResource(Rez.Strings.Connect),
                    WatchUi.loadResource(Rez.Strings.Connecting),
                    WatchUi.loadResource(Rez.Strings.ConnectFail)
                ];
            } else if (id == UI_HILIGHT) {
                labels[id] = null;
            } else if (id == UI_STATES) {
                labels[id] = null;
            } else if (id == UI_MENUS) {
                labels[id] = [
                    WatchUi.loadResource(Rez.Strings.Settings),
                    WatchUi.loadResource(Rez.Strings.Presets)
                ];
            } else if (id == UI_SETTINGSMENU) {
                labels[id] = [
                    WatchUi.loadResource(Rez.Strings.Cinema),
                    WatchUi.loadResource(Rez.Strings.Sport),
                    WatchUi.loadResource(Rez.Strings.Eco),
                    WatchUi.loadResource(Rez.Strings.Manually),
                    WatchUi.loadResource(Rez.Strings.SaveP7)
                ];
            } else if (id == UI_SETTINGEDIT) {
                labels[id] = [
                    WatchUi.loadResource(Rez.Strings.Resolution),
                    WatchUi.loadResource(Rez.Strings.Ratio),
                    WatchUi.loadResource(Rez.Strings.Lens),
                    WatchUi.loadResource(Rez.Strings.Framerate)
                ];
            }
        }
    }

    static public function freeLabels (id as Number) as Void {
        labels[id] = null;
    }

    
    static public var settingLabels as Array<Array<String>?> = [null, null, null, null]; // N_SETTINGS times
    static public function loadSettingLabels() as Void {
        settingLabels = [
            [
                WatchUi.loadResource(Rez.Strings._5K),
                WatchUi.loadResource(Rez.Strings._4K),
                WatchUi.loadResource(Rez.Strings._2K7),
                "",
                WatchUi.loadResource(Rez.Strings._1080)
            ], [
                WatchUi.loadResource(Rez.Strings._8R7),
                WatchUi.loadResource(Rez.Strings._4R3),
                WatchUi.loadResource(Rez.Strings._16R9)
            ], [
                WatchUi.loadResource(Rez.Strings._HYPERVIEW),
                WatchUi.loadResource(Rez.Strings._SUPERVIEW),
                WatchUi.loadResource(Rez.Strings._LARGE),
                WatchUi.loadResource(Rez.Strings._LINEAR),
                WatchUi.loadResource(Rez.Strings._LINEARLOCK)
            ], null
        ];
        loadRegionLabels();
    }
    static public function loadRegionLabels() as Void {
        if (cam.getRegion()==NTSC) {
            settingLabels[FRAMERATE] = [
                WatchUi.loadResource(Rez.Strings._240),
                WatchUi.loadResource(Rez.Strings._120),
                WatchUi.loadResource(Rez.Strings._60),
                WatchUi.loadResource(Rez.Strings._30),
                WatchUi.loadResource(Rez.Strings._24),
            ];
        } else {
            settingLabels[FRAMERATE] = [
                WatchUi.loadResource(Rez.Strings._200),
                WatchUi.loadResource(Rez.Strings._100),
                WatchUi.loadResource(Rez.Strings._50),
                WatchUi.loadResource(Rez.Strings._25),
                WatchUi.loadResource(Rez.Strings._24),
            ];
        }
    }


    static public var icons as Array<Array<BitmapResource>?> = [null, null, null, null, null, null];

    static public function loadIcons(id as Number) as Void{
        if (icons[id]==null) {
            if (id == UI_CONNECT) {
                icons[id] = null;
            } else if (id == UI_HILIGHT) {
                icons[id] = WatchUi.loadResource(Rez.Drawables.Hilight);
            } else if (id == UI_STATES) {
                icons[id] = null;
            } else if (id == UI_MENUS) {
                icons[id] = [
                    WatchUi.loadResource(Rez.Drawables.Wheel)
                ];
            } else if (id == UI_SETTINGSMENU) {
                icons[id] = [
                    WatchUi.loadResource(Rez.Drawables.Cinema), //PSET1
                    WatchUi.loadResource(Rez.Drawables.Sport),  //PSET2
                    WatchUi.loadResource(Rez.Drawables.Eco),    //PSET3
                    WatchUi.loadResource(Rez.Drawables.Camera), //CAM
                    WatchUi.loadResource(Rez.Drawables.Edit)    //SAVEP7
                ];
            } else if (id == UI_SETTINGEDIT) {
                icons[id] = [
                    WatchUi.loadResource(Rez.Drawables.Resolution),
                    WatchUi.loadResource(Rez.Drawables.Ratio),
                    WatchUi.loadResource(Rez.Drawables.Lens),
                    WatchUi.loadResource(Rez.Drawables.Framerate)
                ];
            }
        }
    }

    static public function freeIcons(id as Number) as Void{
        icons[id] = null;
    }
}

