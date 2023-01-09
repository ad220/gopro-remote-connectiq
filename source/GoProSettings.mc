
class GoProSettings {
    var resolution;
    var ratio;
    var framerate;
    var lens;
    var region; //TODO: change to enum NTSC:0 / PAL:1
    
    private static var resolutionList = ["5.3K", "4K", "2.7K", "1080p"];
    private static var ratioList = ["8:7", "4:3", "16:9"];
    private static var framerateList = [240,120,60,30,24]; //TODO: convert NTSC fps -> PAL fps
    private static var lensList = ["HyperView", "SuperView", "Large", "Linéaire + VH", "Linéaire"];

    function initialize() {
        resolution = resolutionList[0];
        ratio = ratioList[0];
        framerate = framerateList[3];
        lens = lensList[2];
    }

    function possibleResolutions() {
        return resolutionList;
    }

    function possibleRatios() {
        switch(resolution) {
            case "5.3K":
            case "4K":
                return ratioList;
            case "2.7K":
                return ratioList.slice(1,3);
            default: // 1080p
                return ratioList.slice(2,3);
        }
    }

    function possibleLenses() {
        switch(ratio) {
            case "8:7":
                return lensList.slice(2,3);
            case "4:3":
                return lensList.slice(2,5);
            default: // 16:9
                if(resolution=="2.7K" or resolution =="1080p") {
                    return lensList.slice(1,5);
                } else {
                    return lensList;
                }
        }
    }

    function possibleFramerates() {
        switch(resolution) {
            case "5.3K":
                if (ratio=="8:7") {
                    return framerateList.slice(3,4);
                } else if (lens=="HyperView" or ratio=="4:3") {
                    return framerateList.slice(3,5);
                } else {
                    return framerateList.slice(2,4);
                }
            case "4K":
                if (ratio=="8:7" or lens=="HyperView") {
                    return framerateList.slice(2,3);
                } else if (ratio=="4:3") {
                    return framerateList.slice(2,5);
                } else {
                    return framerateList.slice(1,5);
                }
            case "2.7K":
                if (ratio=="4:3" or lens=="SuperView") {
                    return framerateList.slice(1,3);
                } else {
                    return framerateList.slice(0,3);
                }
            default: // 1080p
                if (lens=="SuperView") {
                    return framerateList.slice(1,5);
                } else {
                    return framerateList;
                }
        }
    }

}