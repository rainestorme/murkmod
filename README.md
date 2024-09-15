# murkmod

murkmod is a continuation of fakemurk and mush that includes additional useful utilities, with the most prominent being a plugin manager.

## Installation

> [!WARNING]
> You should have unblocked developer mode in some capacity before following the instructions below, most likely by setting your GBB flags to `0x8000`, `0x8090`, or `0x8091`.

Enter developer mode (either while enrolled or unenrolled) and boot into ChromeOS. Connect to WiFi, but don't log in. Open VT2 by pressing `Ctrl+Alt+F2 (Forward)` and log in as `root`. Run the following command:

```sh
bash <(curl -SLk https://bit.ly/murkmod)
```

Select the chromeOS milestone you want to install with murkmod. The script will then automatically download the correct recovery image, patch it, and install it to your device. Once the installation is complete, the system will reboot into a murkmod-patched rootfs.

If initial enrollment after installation fails after a long wait with an error about enrollment certificates, DON'T PANIC! This is normal. Perform an EC reset (`Refresh+Power`) and press space and then enter to *disable developer mode*. As soon as the screen backlight turns off, perform another EC reset and wait for the "ChromeOS is missing or damaged" screen to appear. Enter recovery mode (`Esc+Refresh+Power`) and press Ctrl+D and enter to enable developer mode, then enroll again. This time it should succeed.

It is also highly reccomended to install the murkmod helper extension. To do so:

- Download the repo from [here](https://codeload.github.com/rainestorme/murkmod/zip/refs/heads/main).
- Unzip the `helper` folder and place it in your Downloads folder on your Chromebook. Do not rename it.
- Go to `chrome://extensions` and enable developer mode, then select "Load unpacked" and select the `helper` folder.

For more information on installation of murkmod, including alternate instructions, see [`docs/installation.md`](docs/installation.md)

## Features

- Plugin manager
   - Multiple supported languages: Bash and JavaScript (Python support is in the works)
   - Easy system development: Plugins can run as daemons in the background, upon startup, or when a user triggers them
   - Simple API: Read the docs [here](https://github.com/rainestorme/murkmod/blob/main/docs/plugin_dev.md)
- Support for newer versions of ChromeOS (R116 and up)
   - Experimental Crouton audio support on newer versions
- Improved privacy (*[Opt-in, anonymous analytics](https://murkmod-analytics.besthaxer.repl.co/)*\*\* and no automatic updates)
- Multiple versatile [installation methods](https://github.com/rainestorme/murkmod/blob/main/docs/installation.md)
   - Direct flashing to system storage via [SH1mmer-SMUT](https://github.com/cognito-inc-real/SH1mmer-SMUT)
   - Installation from VT2 via the devmode installer
   - Or upgrade *any pre-existing fakemurk installation*\* to murkmod with a single command
- Graphical helper extension
- Password-protection for mush to prevent unauthorized tampering by inexperienced invidividuals
- Automatic extension disabling to save time during repeated installations
- Alliterated name that sounds pretty cool
- And all base fakemurk features:
   - crossystem spoofing with crossystem.sh
   - Convenient shell access
   - Enabling and disabling extensions
   - User policy modification with Pollen
   - Built-in Crouton support

\*fakemurk v1.1.0 has been the most tested with murkmod, but v1.2.1 is the latest version and is recommended if you wish to install murkmod in this way

\*\*Analytics are completely anonymous - based on HWID only. You can view the collected data publicly [here](https://murkmod-analytics.besthaxer.repl.co/).
