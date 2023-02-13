import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

var cam;

class GoProRemoteApp extends Application.AppBase {
    // var gp;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        cam = new GoProCamera();
        GoProResources.loadFonts();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        // return [ new GoProRemoteView(new GoProCamera()) ] as Array<Views or InputDelegates>;
        var view = new GoProConnectView();
        return [ view, new GoProConnectDelegate(view) ] as Array<Views or InputDelegates>;
    }

}

function getApp() as GoProRemoteApp {
    return Application.getApp() as GoProRemoteApp;
}