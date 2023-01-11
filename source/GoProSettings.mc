import Toybox.Lang;


class GoProSettings {
    private var resolution;
    private var ratio;
    private var lens;
    private var framerate;
    private var region; //TODO: change to enum NTSC:0 / PAL:1

    private var settingsDict;
    

    function initialize() {
        resolution = :_5K;
        ratio = :_8R7;
        lens = :_Large;
        framerate = :_30;
    }

    public function getSetting(setting as Symbol) as Symbol{
        switch (setting) {
            case :resolution:
                return resolution;
            case :ratio:
                return ratio;
            case :lens:
                return lens;
            case :framerate:
                return framerate;
            default:
                return setting;
        }
    }

    public function getResolution() as Symbol {
        return resolution;
    }
    
    public function setResolution(_resolution as Symbol) {
        resolution = _resolution;
    }

    public function possibleResolutions() {
        return resolutionList;
    }


    public function getRatio() as Symbol {
        return ratio;
    }
    
    public function setRatio(_ratio as Symbol) {
        ratio = _ratio;
    }

    function possibleRatios() {
        switch(resolution) {
            case :_5K:
            case :_4K:
                return ratioList;
            case :_3K:
                return ratioList.slice(1,3);
            default: // 1080p
                return ratioList.slice(2,3);
        }
    }

    public function getLens() as Symbol {
        return lens;
    }
    
    public function setLens(_lens as Symbol) {
        lens = _lens;
    }

    function possibleLenses() {
        switch(ratio) {
            case :_8R7:
                return lensList.slice(2,3);
            case :_4R3:
                return lensList.slice(2,5);
            default: // 16:9
                if(resolution==:_3K or resolution ==:_2K) {
                    return lensList.slice(1,5);
                } else {
                    return lensList;
                }
        }
    }

    public function getFramerate() as Symbol {
        return framerate;
    }
    
    public function setFramerate(_framerate as Symbol) {
        framerate = _framerate;
    }
    
    function possibleFramerates() {
        switch(resolution) {
            case :_5K:
                if (ratio==:_L) {
                    return framerateList.slice(3,4);
                } else if (lens==:_HyperView or ratio==:_4R3) {
                    return framerateList.slice(3,5);
                } else {
                    return framerateList.slice(2,4);
                }
            case :_4K:
                if (ratio==:_8R7 or lens==:_HyperView) {
                    return framerateList.slice(2,3);
                } else if (ratio==:_M) {
                    return framerateList.slice(2,5);
                } else {
                    return framerateList.slice(1,5);
                }
            case :_3K:
                if (ratio==:_4R3 or lens==:_SuperView) {
                    return framerateList.slice(1,3);
                } else {
                    return framerateList.slice(0,3);
                }
            default: // 1080p
                if (lens==:_SuperView) {
                    return framerateList.slice(1,5);
                } else {
                    return framerateList;
                }
        }
    }
}