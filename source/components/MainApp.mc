import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

var cam as GoProCamera?;
var mobile as MobileStub?;

var screenH as Number?;
var screenW as Number?;
var halfH as Number?;
var halfW as Number?;
var kMult as Float?; // compared to 240x240 screen
var imgOff as Float?;

class GoProRemoteApp extends Application.AppBase {
    private var viewController as ViewController?;

    function initialize() {
        AppBase.initialize();
        
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        cam = new GoProCamera();
        mobile = new MobileStub();
        MainResources.loadFonts();
        viewController = new ViewController();
    
        var deviceSettings = System.getDeviceSettings();
        screenH = deviceSettings.screenHeight;
        screenW = deviceSettings.screenWidth;
        halfH = screenH / 2;
        halfW = screenW / 2;
        kMult = (screenH / 120)*0.5;
        if (kMult < 1) {kMult = 1.0;}
        imgOff = 0.05*screenH-12*kMult;
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new ConnectView(), new GoProConnectDelegate(viewController) ];
    }

}

function getApp() as GoProRemoteApp {
    return Application.getApp() as GoProRemoteApp;
}