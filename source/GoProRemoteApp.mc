import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GoProRemoteApp extends Application.AppBase {
    // var gp;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // gp = new GoProCamera();
        GoProResources.load();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new GoProRemoteView(new GoProCamera()) ] as Array<Views or InputDelegates>;
    }

}

function getApp() as GoProRemoteApp {
    return Application.getApp() as GoProRemoteApp;
}