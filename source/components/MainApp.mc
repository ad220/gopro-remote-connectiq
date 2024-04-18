import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

var cam as GoProCamera?;
var mobile as MobileStub?; //TODO: reverse this to MobileDevice
var onRemoteView as Boolean?;

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