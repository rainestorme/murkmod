# murkmod

murkmod is a utility script that patches fakemurk and mush to include additional useful utilities, with the most prominent being a plugin manager. This tool enables you to easily install and manage various packages and plugins for mush, and, eventually, fakemurk itself. murkmod also includes additional useful tools and features that can aid you in your various Chromebook hacking tasks.

## Installation
To install murkmod, simply spawn a root shell (option 1) from mush, and paste in the following command:

```sh
bash <(curl -SLk https://raw.githubusercontent.com/rainestorme/murkmod/main/murkmod.sh)
```

This command will download and install murkmod and its (almost minimal) dependencies. Once the installation is complete, you can start using murkmod by running mush as usual.

## Plugin Management
Once murkmod is installed, refresh your mush tab or open a new one with `Ctrl+Alt+T`. You'll see a few new options, such as the ability to run `neofetch`, but the important ones here are `Install plugins`, `Uninstall plugins` and `Plugins`.

To install a plugin, head over to [this link](https://github.com/rainestorme/murkmod/tree/main/plugins). Find the plugin you want and remember its filename. You'll need it in a bit. Select `Install plugins` and enter the filename. The file should be installed, then you can enter `q` to quit.

You can go to `Plugins` to use your installed plugins. Once you select an option, it should execute the plugin's contents.

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

Of course, you should change this to match your plugin. Every time you update your plugin, you should increment `PLUGIN_VERSION`. Everything below the initial variables, though, is what is executed when you run the plugin from the mush menu.

