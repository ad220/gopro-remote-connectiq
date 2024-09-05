# GoPro remote for Garmin watch
A ConnectIQ widget to control your GoPro from your wrist. Uses the [Open GoPro Bluetooth Low Energy API](https://gopro.github.io/OpenGoPro/ble_2_0) and the [Garmin ConnectIQ SDK](https://developer.garmin.com/connect-iq/overview/).

Built for the vivoactive 3, it only supports touchscreen watches and UI scaling is hardcoded for 240x240 pixels display for now.

Must be used in pair with the [Android companion app](https://github.com/ad220/gopro-remote-companion-android) as a bridge to communicate with the GoPro.

Please note that the app is still under development and while this should be stable enough to play with, it may still encounter a few bugs.

## Features
- allows a Garmin watch to control a GoPro[*](#disclaimer)
- press shutter (start and stop video)
- add hilight when recording
- change camera settings manually
- change camera settings with customizable presets


### Planned
- add support for a wider range of ConnectIQ products
- achieve full support for all Open GoPro cameras (see [*](#disclaimer))
- add photo support
- add hypersmooth + most of toggables states
- better info and error pop-ups message
- release on the ConnectIQ Store

## Installation
I did not released this on the ConnectIQ Store for now as it only supports the vivoactive 3. It can be built with the Garmin SDK using the VSCode extension. Then, plug your watch with the USB cable in mass storage mode, and copy the generated `.prg` file to the `/GARMIN/APPS` folder on your device.

Alternatively you can use the release provided on GitHub.

## How to use it
Once the companion app is [installed](https://github.com/ad220/gopro-remote-companion-android#Installation), started and configured on your Android smartphone, the widget is ready to connect to the GoPro.

Press the connect button on the main screen of the widget and wait for the phone to achieve connection with your camera. Once it's done, you should see the remote screen with the shutter button and the GoPro current settings.

Selecting the settings button will allow you to apply a defined preset, edit one of these or manually change camera's settings.

## Screenshots gallery
![](documentation/screenshots/connect.png)
![](documentation/screenshots/remote_off.png)
![](documentation/screenshots/remote_on.png)
![](documentation/screenshots/settings.png)
![](documentation/screenshots/presets.png)

## Disclaimer
(*): The GoPro settings capabilities are hardcoded in the widget according to the GoPro HERO11 Black Mini's [user manual](https://gopro.com/help/productmanuals). Therefore, it may not be able to use the full capabilities of all the other GoPros 