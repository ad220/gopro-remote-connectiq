import Toybox.Lang;

//TODO: switch --> if/else + add other gopros settings restrictions

class GoProSettings {
    protected var settings as Array<Number>;
    // private var region; //TODO: Edit to enum NTSC:0 / PAL:1 --> goto camera settings in v2
    
    public static const resolutionList = [_5K, _4K, _3K, _2K];
    public static const ratioList = [_8R7, _4R3, _16R9];
    public static const lensList = [_HYPERVIEW, _SUPERVIEW, _LARGE, _LINEAR, _LINEARLOCK];
    public static var framerateList = [_240, _120, _60, _30, _24];

    function initialize() {
        settings = [_5K, _8R7, _LARGE, _30];
    }

    public function getSetting(id as Number) as Number {
        return settings[id];
    }

    public function setSetting(id as Number, value as Number) {
        //TODO: fix incompabilities
        settings[id] = value;

        var possibleValues;
        id++;
        while (id<N_SETTINGS) {
            possibleValues = possibleSettings(id); 
            if (!MainUtils.isValueInList(settings[id], possibleValues)) {
                settings[id] = possibleValues[0];
            }
            id++;
        }
    }

    // TODO: replace with available settings request to camera
    public function possibleSettings(id) as Array<Number>{ // for GoPro HERO 11 Black Mini
        switch (id) {
            case RESOLUTION:
            return resolutionList;

            case RATIO:
            switch(settings[RESOLUTION]) {
                case _5K:
                case _4K:
                    return ratioList;
                case _3K:
                    return ratioList.slice(1,3);
                default: // 1080p
                    return ratioList.slice(2,3);
            }

            case LENS:
            switch(settings[RATIO]) {
                case _8R7:
                    return lensList.slice(2,3);
                case _4R3:
                    return lensList.slice(2,5);
                default: // 16:9
                    if(settings[RESOLUTION]==_3K or settings[RESOLUTION]==_2K) {
                        return lensList.slice(1,5);
                    } else {
                        return lensList;
                    }
            }

            case FRAMERATE:
            switch(settings[RESOLUTION]) {
                case _5K:
                    if (settings[RATIO]==_8R7) {
                        return framerateList.slice(3,4);
                    } else if (settings[LENS]==_HYPERVIEW or settings[RATIO]==_4R3) {
                        return framerateList.slice(3,5);
                    } else {
                        return framerateList.slice(2,4);
                    }
                case _4K:
                    if (settings[RATIO]==_8R7 or settings[LENS]==_HYPERVIEW) {
                        return framerateList.slice(2,3);
                    } else if (settings[RATIO]==_4R3) {
                        return framerateList.slice(2,5);
                    } else {
                        return framerateList.slice(1,5);
                    }
                case _3K:
                    if (settings[RATIO]==_4R3 or settings[LENS]==_SUPERVIEW) {
                        return framerateList.slice(1,3);
                    } else {
                        return framerateList.slice(0,3);
                    }
                default: // 1080p
                    if (settings[LENS]==_SUPERVIEW) {
                        return framerateList.slice(1,5);
                    } else {
                        return framerateList;
                    }
            }
            default:
                throw new Exception();
        }
    }


    public function getDescription() as String {
        var frLabel = MainResources.settingLabels[FRAMERATE][settings[FRAMERATE]];
        return MainResources.settingLabels[RESOLUTION][settings[RESOLUTION]] \
            + "@" + frLabel.substring(0, frLabel.length()-4) + " " \
            + MainResources.settingLabels[RATIO][settings[RATIO]]; //[TODO: add lens
    }

    public function save() {
        // Implemented in subclasses
    }
}