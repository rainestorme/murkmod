# murkmod

murkmod is a utility script that patches fakemurk and mush to include additional useful utilities, with the most prominent being a plugin manager. This tool enables you to easily install and manage various packages and plugins for mush, and, eventually, fakemurk itself. murkmod also includes additional useful tools and features that can aid you in your various Chromebook hacking tasks.

## Installation
To install murkmod, simply spawn a root shell (option 1) from mush, and paste in the following command:

```sh
bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod.sh)
```

This command will download and install murkmod and its (almost minimal) dependencies. Once the installation is complete, you can start using murkmod by running mush as usual.

## Plugin Management
Once murkmod is installed, refresh your mush tab or open a new one with `Ctrl+Alt+T`. You'll see a few new options, such as the ability to run `neofetch`, but the important ones here are `Install plugins` and `Uninstall plugins`.

**Heads up: The following instructions are broken at the moment. Look at the bottom of this readme for up-to-date instructions.**

To install a plugin, select the relevant option and find the plugin you want to install. murkmod will automatically fetch the plugin from this repo and install it to `/mnt/stateful_partition/murkmod/plugins`. You can then select `q` to quit, and the newly installed plugin should show up on the list of options for mush.

## Plugin Development
It's pretty straightforward to create a pluign. Just create a `.sh` file with the following content:

```sh
#!/bin/bash
PLUGIN_NAME="Hello World Plugin"
PLUGIN_FUNCTION="Print a hello world message"
PLUGIN_DESCRIPTION="The friendliest murkmod plugin you'll ever see."
PLUGIN_AUTHOR="rainestorme"
PLUGIN_VERSION=1
echo "Hello, World!"
```

Of course, you should change this to match your plugin. Every time you update your plugin, you should increment `PLUGIN_VERSION`. Everything below the initial variabls, though, is what is executed when you run the plugin from the mush menu.

## Plugin installation
Although the plugin uninstallation feature is working, the plugin "shop"/installation is not (although I welcome a PR to fix it). In the meantime, you can still install murkmod plugins by opening a root shell and downloading them (probably via `curl`) to `/mnt/stateful_partition/murkmod/plugins`. An example of how to download the Hello World Plugin (`plugins/helloworld.sh`) is below:

```sh
pushd /mnt/stateful_partition/murkmod/plugins && curl https://raw.githubusercontent.com/rainestorme/murkmod/main/plugins/helloworld.sh -O helloworld.sh && popd && exit
```
