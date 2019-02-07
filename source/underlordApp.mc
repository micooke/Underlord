using Toybox.Application;

class underlordApp extends Application.AppBase {
	hidden var UA;
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
    	UA = new underlordView();
    
    	if( Toybox.WatchUi.WatchFace has :onPartialUpdate ) {
        	return [ UA, new underlordDelegate()];
        } else {
        	return [ UA ];
        }        
    }   
	
	function onSettingsChanged() {
		UA.onSettingsChanged();
	}
}