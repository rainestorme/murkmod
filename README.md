# murkmod

murkmod is a utility script that patches fakemurk and mush to include additional useful utilities, with the most prominent being a plugin manager. At this point, it's basically a continuation of what fakemurk tried to be, since MercuryWorkshop ghosted me after asking me to make a PR.

## Installation

> [!WARNING]
> You should have unblocked developer mode in some capacity before following the instructions below, most likely by setting your GBB flags to `0x8000`, `0x8090`, or `0x8091`.

Enter developer mode while enrolled and boot into ChromeOS. Connect to WiFi, but don't log in. Open VT2 by pressing `Ctrl+Alt+F2 (Forward)` and log in as `root`. Run the following command:

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

## Plugin Management

Once murkmod is installed, refresh your mush tab or open a new one with `Ctrl+Alt+T`. You'll see a bunch of new options, but the important ones for this guide are `Install plugins`, `Uninstall plugins` and `Plugins`.

To install a plugin, head over to [this link](https://github.com/rainestorme/murkmod/tree/main/plugins). Find the plugin you want and remember its filename. Select `Install plugins` and enter said filename. The plugin should be fetched from Github, and then you can enter `q` to quit.

You can go to `Plugins` to use your installed plugins. Once you select an option, it should execute the plugin's contents.

## Plugin Development

See [`docs/plugin_dev.md`](docs/plugin_dev.md)

## About Analytics

Analytics are completely anonymous - based on HWID only. You can view the collected data publicly [here](https://murkmod-analytics.besthaxer.repl.co/).
