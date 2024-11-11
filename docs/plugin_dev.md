# Plugin Development

There are now two different types of plugins. If you would like to create a terminal-based plugin in Bash, continue reading this file. Otherwise, see [`docs/js_plugins.md`](/docs/js_plugins.md)

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

The second comment at the top defines the type of the plugin. There are three plugin types:

- `menu_plugin`
- `daemon_plugin`
- `startup_plugin`

Menu plugins aren't run as root - all other plugins are. Startup plugins run once, in a late stage of the boot process, and daemon plugins are run infinitely in a loop after startup.

Make sure that your startup plugin runs quickly - or, at least, as quickly as possible. It'll hold up the boot process until it exits.

> [!IMPORTANT]
> If your startup plugin tries to use /mnt/stateful_partition, it will fail! Startup plugins are run before stateful is mounted. If your startup plugin needs to access stateful, see [`docs/example-plugins/startup/read_file_from_stateful.sh`](/docs/example-plugins/startup/read_file_from_stateful.sh) for an example.
