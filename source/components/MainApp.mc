import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

var cam as GoProCamera?;
var mobile as MobileStub?; //TODO: reverse this to MobileDevice
var onRemoteView as Boolean?;

var screenH as Number?;
var screenW as Number?;
var halfH as Number?;
var halfW as Number?;
var kMult as Float?; // compared to 240x240 screen
var imgOff as Float?;

class GoProRemoteApp extends Application.AppBase {
    // var gp;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        cam = new GoProCamera();
        mobile = new MobileStub(); //TODO: reverse this to MobileDevice
        onRemoteView = false;
        MainResources.loadFonts();
    
        var deviceSettings = System.getDeviceSettings() as DeviceSettings;
        screenH = deviceSettings.screenHeight;
        screenW = deviceSettings.screenWidth;
        halfH = screenH / 2;
        halfW = screenW / 2;
        kMult = (screenH / 120)*0.5;
        imgOff = 0.05*screenH-12*kMult;
        deviceSettings = null;
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        mobile.send([COM_CONNECT, 1]);
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        // return [ new RemoteView(new GoProCamera()) ] as Array<Views or InputDelegates>;
        var view = new ConnectView();
        return [ view, new GoProConnectDelegate(view) ] as Array<Views or InputDelegates>;
    }

}

function getApp() as GoProRemoteApp {
    return Application.getApp() as GoProRemoteApp;
}