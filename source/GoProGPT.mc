/* // Import the Connect IQ libraries
#import
#import

// Create a new Connect IQ app
class MyApp extends ConnectIQApp {
  
  // Declare a variable to store the selected video resolution
  var selectedResolution;
  
  // Declare a list of available video resolutions
  var resolutions = ["5.3K", "4K", "2.7K", "1080p"];
  
  // Declare a variable to store the selected frame rate
  var selectedFrameRate;
  
  // Declare a list of available frame rates
  var frameRates = ["240 FPS", "200 FPS", "120 FPS", "100 FPS", "60 FPS", "50 FPS", "30 FPS", "25 FPS"];
  
  // Declare a variable to store the selected field of view
  var selectedFOV;
  
  // Declare a list of available fields of view
  var fovs = ["Wide", "Medium", "Narrow"];
  
  // Override the onStart method to display the video settings screen when the app starts
  override function onStart() {
    // Display the video settings screen
    showVideoSettingsScreen();
  }
  
  // Define a function to display the video settings screen
  function showVideoSettingsScreen() {
    // Clear the screen
    Graphics.clear();
    
    // Display the title
    Graphics.drawText("Video Settings", 0, 0, Graphics.FONT_LARGE, Graphics.ALIGN_LEFT);
    
    // Display the resolution options
    Graphics.drawText("Resolution:", 0, 20, GoProResources.fontSmall, Graphics.ALIGN_LEFT);
    for (var i = 0; i < resolutions.length; i++) {
      if (selectedResolution == resolutions[i]) {
        Graphics.drawText("[X] " + resolutions[i], 40, 40 + i * 20, GoProResources.fontSmall, Graphics.ALIGN_LEFT);
      } else {
        Graphics.drawText("[ ] " + resolutions[i], 40, 40 + i * 20, GoProResources.fontSmall, Graphics.ALIGN_LEFT);
      }
    }
    
    // Display the frame rate options
    Graphics.drawText("Frame Rate:", 0, 100, GoProResources.fontSmall, Graphics.ALIGN_LEFT);
    for (var i = 0; i < frameRates.length; i++) {
      if (selectedFrameRate == frameRates[i]) {
        Graphics.drawText("[X] " + frameRates[i], 40, 120 + i * 20, GoProResources.fontSmall, Graphics.ALIGN_LEFT);
      } else {
        Graphics.drawText("[ ] " + frameRates[i], 40, 120 + i * 20, GoProResources.fontSmall, Graphics.ALIGN_LEFT);
      }
    }
    
    // Display the field of view options
    Graphics.drawText("Field of View:", 0, 180, GoProResources.fontSmall, Graphics.ALIGN_LEFT);
    for (var i = 0; i < fovs.length; i++) {
      if (selectedFOV == fovs[i]) {
        Graphics.drawText("[X] " + fovs[i], 40, 200 + i * 20, GoProResources.fontSmall, Graphics.ALIGN_LEFT);
      } else {
        Graphics.drawText("[ ] " + fovs[i], 40, 200 + i * 20, GoProResources.fontSmall, Graphics.ALIGN_LEFT);
      }
    }
    
    // Display the "Save" button
    Graphics.drawText("Save", 0, 280, Graphics.FONT_LARGE, Graphics.ALIGN_LEFT);
  }
  
  // Override the onKeyDown event to handle user input
  override function onKeyDown(key) {
    // Check if the up arrow key was pressed
    if (key == KeyEvent.KEY_UP) {
      // Decrement the selected option
      selectedOption--;
      
      // If the selected option is less than 0, set it to the last option
      if (selectedOption < 0) {
        selectedOption = numOptions - 1;
      }
      
      // Redraw the screen
      showVideoSettingsScreen();
    }
    
    // Check if the down arrow key was pressed
    if (key == KeyEvent.KEY_DOWN) {
      // Increment the selected option
      selectedOption++;
      
      // If the selected option is greater than the number of options, set it to the first option
      if (selectedOption >= numOptions) {
        selectedOption = 0;
      }
      
      // Redraw the screen
      showVideoSettingsScreen();
    }
    
    // Check if the select key was pressed
    if (key == KeyEvent.KEY_SELECT) {
      // Check which option is selected
      if (selectedOption == 0) {
        // Toggle the selected resolution
        if (selectedResolution == resolutions[0]) {
          selectedResolution = null;
        } else {
          selectedResolution = resolutions[0];
        }
      } else if (selectedOption == 1) {
        // Toggle the selected frame rate
        if (selectedFrameRate == frameRates[0]) {
          selectedFrameRate = null;
        } else {
          selectedFrameRate = frameRates[0];
        }
      } else if (selectedOption == 2) {
        // Toggle the selected field of view
        if (selectedFOV == fovs[0]) {
          selectedFOV = null;
        } else {
          selectedFOV = fovs[0];
        }
      } else if (selectedOption == 3) {
        // Save the selected video settings
        saveVideoSettings();
      }
      
      // Redraw the screen
      showVideoSettingsScreen();
    }
  }
  
  // Define a function to save the selected video settings
  function saveVideoSettings() {
    // TODO: Save the selected video settings to the GoPro camera
  }
} */