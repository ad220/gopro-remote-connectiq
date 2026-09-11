# User Guide

This guide explains how to install, pair, and use the GoPro Remote widget on your Garmin watch.

## Links
- [Supported devices](#supported-devices)
- [Installation](#installation)
- [First launch](#first-launch-and-pairing)
- [Home menu](#home-menu)
- [Glance](#glance)
- [Remote screen](#remote-screen)
- [Video settings](#video-settings-menu)
- [Camera settings](#camera-settings-togglables)
- [Disconnecting](#exiting-and-disconnecting)
- [Troubleshooting](#troubleshooting)


## Supported devices

### GoPro cameras
- HERO4 Silver / Black
- HERO5 Black / Session
- Fusion
- HERO6 Black
- HERO7 Black / White / Silver
- HERO 2018
- HERO8 Black
- MAX
- HERO9 Black
- HERO10 Black
- HERO11 Black (Mini)
- HERO12 Black
- MAX2
- HERO13 Black
- HERO (2024)
- HERO Lit
- Mission1 (Pro)

### Garmin smartwatches
- Approach® S70
- D2™ Mach 1
- D2™ Mach 2
- Descent™ G2
- Descent™ MK3
- Descent™ MK3i
- Enduro™ 2
- Enduro™ 3
- epix™ (Gen 2)
- epix™ Pro
- fēnix® 7(S/X) (Pro / Solar)
- fēnix® 8 (Pro / Solar)
- fēnix® 9 (Pro / Solar)
- fēnix® E
- Forerunner® 255(S) (Music)
- Forerunner® 265(S)
- Forerunner® 570
- Forerunner® 955 Dual Power
- Forerunner® 965
- Forerunner® 970
- Instinct® 3
- MARQ® Gen 2 (Athlete / Adventurer / Captain / Golfer / Carbon Edition / Commander - Carbon Edition)
- tactix® 7
- tactix® 8
- Venu® 4
- Venu® X1
- vívoactive® 6


> [!IMPORTANT]
> While the app *should* now support every BLE capable camera, it was only physically tested with the forerunner 955 / GoPro HERO11 Black Mini.
> Any constructive feedback which could help me enhance compatibility with every GoPro model is welcome ! (see [troubleshooting](#troubleshooting))


## Installation

### ConnectIQ Store
The widget is available on the [Garmin Connect IQ store](https://apps.garmin.com/apps/f9e09224-1c60-4e94-a616-f9ef10932fdf). You can install it directly from your Garmin Connect app on your smartphone.

### GitHub release
1. Download [latest release](https://github.com/ad220/gopro-remote-connectiq/releases/latest) from GitHub
2. Connect your watch to your computer using a USB cable
3. Find your device in Garmin's [Device Reference](https://developer.garmin.com/connect-iq/device-reference/)
4. Scroll down to "Part Number" and write it down
5. Unzip the .iq release file (it works with 7Zip)
6. Open the folder named after your part number
7. Copy the .prg file to your device's "GARMIN/APPS" directory

### From source
You can also build the widget for your specific device with the Garmin SDK and the VSCode extension. Then, plug your watch to the computer with the USB cable in mass storage mode, and copy the generated `.prg` file to the `/GARMIN/APPS` folder on your device.


## First launch and pairing

1. Open the widget on your watch.
2. On the connect screen, press the pair button.
3. Put your GoPro into pairing mode (from the camera's connections menu).
4. Your watch scans for nearby cameras. Select your GoPro from the list (cameras are shown with their model name) once it appears.
5. Wait for the camera to accept the pairing request.

Once paired, your watch remembers the camera. On future launches, the button on the connect screen will say "Connect" instead of "Pair", pressing it reconnects directly to the last used camera.

If you want to pair a different camera later, open the home menu from the connect screen and choose to scan for a new camera.


## Home menu

From the connect screen, open the home menu to:

- #### Scan for a new camera
  Discover and pair with a different GoPro.

- #### Toggle error reports
  Enable or disable automatic sending of error reports (see below). The widget automatically stores error codes shown as an alert when something wrong happens (for example, a dropped Bluetooth connection or an unexpected camera behavior). At each start of the widget it checks if last execution raised any error and if applicable sends them to the developer's error dashboard to help improve stability.

No personal data or footage is ever transmitted, only anonymous the error code and your app version - the code of both this widget and the dashboard is open source anyway, you can check by yourself if you're curious. You can turn this off at any time from the home menu.


## Glance

On watches that support Glances, the widget can be added to a watch face. It shows the name of the last used camera (or "Scan for camera" if none is paired yet) and opens the widget directly into the connect flow when tapped.


## Remote screen

Once connected, you'll see the main remote screen with:

- #### Shutter button
  Starts and stops recording (or takes a photo when the camera is in photo mode, see [Switch capture mode](#switch-capture-mode)).

- #### Hilight button
  Adds a Hilight tag while recording, so you can find key moments later when editing your footage.

- #### Settings button
  Shows the camera's current video settings (resolution, framerate, aspect ratio), or `. . .` while settings are still loading. Opens the video settings menu (see below). When the camera is in photo mode, it shows the current photo lens instead and opens the photo lens picker. Only available while the camera is idle (not recording).

- #### Recording timer
  While recording, a blinking red dot and the recording duration (minutes:seconds) are shown at the top of the screen.

### Navigation

The remote screen is controlled as follows (on touchscreens, the shutter, hilight and settings touch targets work the same way):

- **Up button**: adds a Hilight tag while recording, or opens the camera settings menu when the camera is idle.
- **Settings button**: opens the video settings menu in video mode, or the photo lens picker in photo mode, while the camera is idle.
- **Menu key**: opens the advanced settings menu, which lets you switch the capture mode (see below).

While recording, only the shutter and hilight actions remain active.

### Switch capture mode

Press the **menu key** on the remote screen and choose *Switch capture mode* to alternate the camera between video and photo mode. In photo mode, the shutter takes a photo, the settings description shows the current photo lens (e.g. "27MP Wide"), and the settings button lets you change the photo lens (megapixels and composition).


## Video settings menu

Opened from the remote screen while the camera is idle. It offers:

- #### Cinema / Sport / Eco
  Three built-in presets that instantly apply a set of resolution, lens, framerate, and anti-flicker settings suited to different situations.
 
- #### Manually edit camera settings
  Lets you change, one by one:
  - Resolution
  - Aspect ratio
  - Lens (field of view)
  - Framerate

- #### Save settings as preset
  Saves the camera's currently applied video settings over one of the three preset slots (Cinema, Sport, or Eco), so you can recall your own custom configuration later.

  Applying a preset that uses a different anti-flicker frequency (50 Hz vs 60 Hz) than the one currently set on the camera may not apply correctly. Set the anti-flicker frequency to match your region first if you run into this.

> [!TIP]
> Not all GoPro models are capable of using the default presets as they may not have the corresponsing settings available. Edit them when using the widget for the first time so that they match your camera capabilities.


## Camera settings (togglables)

A second menu, separate from video settings, is opened with the **up button** from the remote screen while the camera is idle. It groups camera-level toggles:

- **LED**: turns the camera LEDs on or off. If your camera supports more than two LED states, a picker with all of them is opened instead.
- **GPS**: enables or disables GPS on cameras that have it.
- **Anti-flicker**: toggles the video frequency between 50 Hz and 60 Hz to avoid flicker under artificial light.
- **HyperSmooth / stabilization**: disables or changes the stabilization level (a picker with the levels your camera offers is opened).
- **Power off**: puts the camera to sleep.

This screen also shows the camera's current **battery level** and **remaining SD card recording time**.

On watches with a touchscreen, tap a button to select it; on button-only watches, use the up/down buttons to move between items and select to toggle or open the picker.


## Exiting and disconnecting

Going back from the remote screen puts the camera to sleep (unless it is currently recording, in which case it simply disconnects without powering off the camera). Closing the widget while connected also disconnects automatically to save the camera's battery.


## Troubleshooting

- #### Camera won't pair
  Make sure the GoPro is in pairing mode and Bluetooth is enabled on your watch. Try scanning again.

- #### Settings show `. . .`
  The watch hasn't finished reading the current settings from the camera yet; wait a moment or reopen the remote screen.

- #### A preset didn't apply as expected
  Check that its anti-flicker frequency matches the one currently active on the camera.

- #### The app seems unstable or shows a repeating error
  Please leave error reports enabled which helps me diagnose and fix the issue in a future update. If you can spend 5 minutes of your time, you're more than welcome to send any feedback (bug reports, feature requests, or questions) by email at "dev *at* ad220 *dot* fr" or by opening an issue on [GitHub](https://github.com/ad220/gopro-remote-connectiq).
