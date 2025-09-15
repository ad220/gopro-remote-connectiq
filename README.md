# <p align="center"> <br/> <img src="documentation/remote128.png" alt="remote icon" width="128"/> <br/> <br/> GoPro Remote for Garmin<br/> </p>
A ConnectIQ widget to control your GoPro from your wrist. It uses the [Open GoPro Bluetooth Low Energy API](https://gopro.github.io/OpenGoPro/ble/index.html) and the [Garmin ConnectIQ SDK](https://developer.garmin.com/connect-iq/overview/).

The widget should support every watch with API level 3.2.0 and above and every GoPro camera supporting the Open GoPro API (HERO9+). However, it has only been tested with a HERO11 Black Mini. A previous version of this app for smartwatches without BLE capabilities can be found and built with the [legacy branch](https://github.com/ad220/gopro-remote-connectiq/tree/legacy) or in the GitHub releases versions prior to 3.0.

Please note that this app was mainly developed for personal use, it should now be stable enough but you may still encounter a few bugs.

## Features
- allows a Garmin watch to control a GoPro HERO9+
- press shutter (start and stop video)
- add hilight when recording
- change camera settings manually
- change camera settings with customizable presets


### Planned [(*)](#disclaimer)
- add photo and timelapse support
- add hypersmooth + most of toggables states
- better info and error pop-ups message

## Installation
The widget is available on the [Garmin Connect IQ store](https://apps.garmin.com/apps/f9e09224-1c60-4e94-a616-f9ef10932fdf). You can install it directly from your Garmin Connect app on your smartphone.

You can also build the widget for your specific device with the Garmin SDK and the VSCode extension. Then, plug your watch to the computer with the USB cable in mass storage mode, and copy the generated `.prg` file to the `/GARMIN/APPS` folder on your device.

## How to use it
On the first launch, press the pair button on the main screen of the widget and put your GoPro in pairing mode. After being scanned by the watch, select the camera and wait for it to validate pairing. Once it is done, you should see the remote screen with the shutter button and the GoPro current settings.

On this view, press the select button on your watch to start recording, the up button to hilight during capture and the down button to open the settings menu when the camera is idle. In this menu, you can apply a defined preset, manually change camera settings or save the current applied settings as a preset.

## Screenshots gallery
![](documentation/screenshots/connect.png)
![](documentation/screenshots/remote_off.png)
![](documentation/screenshots/remote_on.png)
![](documentation/screenshots/settings.png)
![](documentation/screenshots/presets.png)

## Changelog

### v3.0
- Allow direct BLE connection to GoPro cameras without companion app.
- Remove support for device with API support lower than 3.2.0
- Add support for HERO13 (not tested)
- Improve stability

### v2.0
- Add support for more cameras (HERO9 to HERO12)

### v1.1
- Add support for Garmin watches without touchscreen and bigger screens with a scalable ui.

### v1.0
- First version of the app, hardcoded for 240x240 garmin watches with touchscreen and HERO11 Black Mini ; needs companion app.

## Disclaimer
(*): The planned features are not guaranteed to be implemented. The development of this app is done on my free time, and with the compatibility additions done in v2, I don't feel like continuing this anymore (at least for now). If you want to help, feel free to contribute to the project.