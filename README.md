# murkmod

murkmod is a utility script that patches fakemurk and mush to include additional useful utilities, with the most prominent being a plugin manager. This tool enables you to easily install and manage various packages and plugins for mush, and, eventually, fakemurk itself. murkmod also includes additional useful tools and features that can aid you in your various Chromebook hacking tasks.

## Heads up!

v1.2.0 of fakemurk is mostly working with murkmod, but in some rare edge cases it breaks, and it breaks badly. Use caution!

## Installation

Want a complete guide, with steps all the way from choosing an exploit to configuring fakemurk? Check out the [Chromebook Exploit Guide](https://chromebook-guide.github.io/).

> In order to use all of the features of murkmod, you **must** create a emergency revert backup during the installation of fakemurk.

To install murkmod, simply spawn a root shell (option 1) from mush, and paste in the following command:

```sh
bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod.sh)
```

This command will download and install murkmod and its (almost minimal) dependencies. Once the installation is complete, you can start using murkmod by running mush as usual.

> Installing (or updating) fakemurk will set the password for the `chronos` user to `murkmod`.

#### Tip:
If you get an error about a filesystem being readonly run
`fsck -f $(rootdev)`
then reboot



## Plugin Management
Once murkmod is installed, refresh your mush tab or open a new one with `Ctrl+Alt+T`. You'll see a few new options, such as the ability to run `neofetch`, but the important ones here are `Install plugins`, `Uninstall plugins` and `Plugins`.

To install a plugin, head over to [this link](https://github.com/rainestorme/murkmod/tree/main/plugins). Find the plugin you want and remember its filename. You'll need it in a bit. Select `Install plugins` and enter the filename. The file should be installed, then you can enter `q` to quit.

You can go to `Plugins` to use your installed plugins. Once you select an option, it should execute the plugin's contents.

## Plugin Development
It's pretty straightforward to create a pluign. Just create a `.sh` file with the following content:

```sh
#!/bin/bash
# menu_plugin
PLUGIN_NAME="Hello World Plugin"
PLUGIN_FUNCTION="Print a hello world message"
PLUGIN_DESCRIPTION="The friendliest murkmod plugin you'll ever see."
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1
echo "Hello, World!"
```

Of course, you should change this to match your plugin. Every time you update your plugin, you should increment `PLUGIN_VERSION`. Everything below the initial variables, though, is what is executed when you run the plugin from the mush menu.

To add a plugin to this repository (for easy download from mush), just fork the repo, add the file in `/plugins/` and make a PR. I'll review it and merge it if it doesn't do anything malicious.

The second comment at the top defines the type of the plugin. There are four plugin types:

- `menu_plugin`
- `daemon_plugin`
- `startup_plugin`

Menu plugins aren't run as root - all other plugins are. Startup plugins run once, in a late stage of the boot process, and daemon plugins are run infinitely in a loop after startup.

Make sure that your startup plugin runs quickly - or, at least, as quickly as possible. It'll hold up the boot process until it exits. 

> Careful! If your startup plugin tries to use /mnt/stateful_partition, it will crash! Startup plugins are run before stateful is mounted. If your startup plugin needs to access stateful, see `example-plugins/startup/read_file_from_stateful.sh` for an example.

## Using Hacked Sudo

Murkmod makes a few changes to system permission to allow chronos to use sudo with no password, and setting the password to the chronos account so that root can `su` into it, meaning that you can properly use sudo in a command line if you run the following at a root bash prompt:

```
su chronos
sudo <your command here>
```

## Regarding Chromebrew

Chromebrew is now functional with the official `cros_debug` patch from MercuryWorkshop.

## Are your menu plugins no longer showing up after updating?

Open a root shell and run the following commands:

```sh
rm /mnt/stateful_partition/murkmod/plugins/*
exit
```

Now, reinstall all plugins you want to use.

## Notes on USB Boot

In order to boot a traditionally built linux distro (one not designed to be used on Chromebook hardware), you'll need to install MrChromebox's RW_LEGACY firmware. To do so, the `mrchromebox-fwscript.sh` plugin is provided. However, it is highly reccomended that you use [depthboot](https://eupnea-linux.github.io/docs/depthboot/requirements) to build a more compatible linux image that you can then boot from with `Ctrl+U` at the developer mode warning screen. Keep in mind that the step requiring the enabling of `dev_boot_usb` can be performed from the mush menu.

## About Analytics

Analytics are completely anonymous - based on HWID only. You can view the collected data publicly [here](https://murkmod-analytics.besthaxer.repl.co/).
