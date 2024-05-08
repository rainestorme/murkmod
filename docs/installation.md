# Installation

murkmod has seen many iterations, and due to this, there are many methods available to install it. All previously functional methods of installation are still fully maintained.

## Developer Mode Installer (recommended)

> [!WARNING]
> You should have unblocked developer mode in some capacity before following the instructions below, most likely by setting your GBB flags to `0x8000`, `0x8090`, or `0x8091`, or by being on a low enough firmware version for it to not matter.

Enter developer mode while unenrolled and boot into ChromeOS. Connect to WiFi, but don't log in. Open VT2 by pressing `Ctrl+Alt+F2 (Forward)` and log in as `root`. Run the following command:

```sh
bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod-devmode.sh)
```

Select the chromeOS milestone you want to install with murkmod. The script will then automatically download the correct recovery image, patch it, and install it to your device. Once the installation is complete, the system will reboot into an enrolled, murkmod-patched rootfs. Continue to [Common Installation Steps](#common-installation-steps).

## SH1mmer-SMUT

> [!WARNING]
> If you have FWMP set, you will have to use the pencil method/a [3D printed chip clip](https://www.tinkercad.com/things/kWIgDztbX4s-soic-8-on-motherboard-stealth-chip-clip) with a glob of solder or a wire to short out the corresponding pins as to disable WP. Otherwise, if your device has not been affected by the Tsunami, you can continue to the normal instructions.

Create a [SH1mmer-SMUT](https://github.com/cognito-inc-real/sh1mmer-smut) image with a murkmod image built with the image_patcher.sh script - instructions are in the repo.

Once you've done this, flash the image to a drive. Pop off the back of your Chromebook and remove the battery to disable WP.

Now, boot into the flashed USB drive as you would with normal SH1mmer. From there, select `Utiliites` > `Unblock Devmode`. Head back and select `Payloads` > `SH1mmer Multiboot UTility (SMUT)` - answer `Y` at the prompt to defog and select option 1 (`Install fakemurk/murkmod image to unused partition`) and then enter the exact filename of the image you created earlier.

Follow all prompts and wait for the installation to complete (the kernel patch is 512mb and the root patch is 4gb). The system will reboot automatically. Continue to [Common Installation Steps](#common-installation-steps).

### fakemurk > murkmod upgrade

> [!WARNING]
> In order to use all of the features of murkmod, you **must** enable emergency revert during the installation of fakemurk.

> [!IMPORTANT]
> This method will only work with ChromeOS v105 (`og`) or v107 (`mercury`). If you wish to use a newer version (v117 `john` or v118 `pheonix`), you must use the methods above.

To install murkmod, simply spawn a root shell (option 1) from mush, and paste in the following command:

```sh
bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod.sh)
```

This command will download and install murkmod to your device. Once the installation is complete, you can start using murkmod by opening mush as usual.

> [!NOTE]
> Installing (or updating) fakemurk will set the password for the `chronos` user to `murkmod`.

> [!WARNING]
> If you get an error about a filesystem being readonly run `fsck -f $(rootdev)` then reboot.

## Common Installation Steps

If initial enrollment after installation fails after a long wait with an error about enrollment certificates, DON'T PANIC! This is normal. Perform an EC reset (`Refresh+Power`) and press space and then enter to *disable developer mode*. As soon as the screen backlight turns off, perform another EC reset and wait for the "ChromeOS is missing or damaged" screen to appear. Enter recovery mode (`Esc+Refresh+Power`) and press Ctrl+D and enter to enable developer mode, then enroll again. This time it should succeed.

## The murkmod helper extension

murkmod also has an optional, but highly reccomended helper extension that acts as a graphical abstraction over the top of mush, the murkmod developer shell. To install it:

- Download the repo from [here](https://codeload.github.com/rainestorme/murkmod/zip/refs/heads/main)
- Unzip the `helper` folder and place it anywhere you want on your Chromebook, ideally in your Downloads folder
- Go to `chrome://extensions` and enable developer mode, then select "Load unpacked" and select the `helper` folder
