# murkmod JS Plugins

JavaScript (JS) plugins are exclusive to the murkmod helper extension, and are able to create rich GUIs for better user interactivity.

## Usage

Installation of JS plugins is no different than that of bash plugins through the helper extension.

## Development

In any given JS plugin, the following contents **must** exist for it to be functional:

```js
var PLUGIN_NAME = "My JS Plugin";
var PLUGIN_FUNCTION = "Click me!!!";
var PLUGIN_DESCRIPTION = "An example JS plugin"
var PLUGIN_AUTHOR = "Me!";
var PLUGIN_VERSION = 1;
// optionally:
var PLUGIN_DEPENDENCIES = [];

function plugin_init() {
  // this is run on plugin initialization, when a helper tab is opened
  console.log("Initializing My JS Plugin...");
  // do init stuff here
}

function plugin_main() {
  // this is run when you click the button in the helper extension
  alert("You clicked the button!");
}
```

Optionally, you can add an array of strings, `PLUGIN_DEPENDENCIES`, to provide a list of plugins published in murkmod that your plugin requires to run correctly. Plugin dependencies are resolved recursively, so be careful about creating deep dependency trees that may increase installation times.

Otherwise, publishing of a JS plugin is identical to that of a bash plugin - fork the murkmod repo, add the file to `/plugins`, and make a PR.

## APIs and Methods

Any code in a JS plugin runs directly through an `eval()` statement on an extension page with privileged access to `chrome.terminalPrivate`, as well as the murkmod helper API, which contains helper methods to allow for easier scripting. The `terminalPrivate` API will not be documented here, but reading the source of the helper extension should yield the necessary basic information if you wish to use it on other projects.

Additionally, the tab that your plugin is run on has the following utilities accessible to your script:

- [Xterm.js](https://xtermjs.org/)
- [Sweetalert2](https://sweetalert2.com/download)
- [jQuery](https://jquery.com/) v3.7.1

The murkmod helper API contains the following methods:

- `window.send(string input)`: Sends raw input to the primary mush session. Accepts escape sequences.
- `window.bash(string input)`: Sends raw input to the root bash session. Also accepts escape sequences.
- `window.show_term()` and `window.hide_term()`: Shows and hides the primary mush terminal. Generally, you won't need to use these.
- `window.start_crouton()` and `window.stop_crouton()`: Starts and stops a Crouton session running in a separate terminal.
- `window.purge_exts()`: Purge/kill all running extension processes. Required after hard enabling or disabling an extension.

Additionally, there are two other methods not in that list. They have been omitted due to their complexity and are documented below.

### About `window.run_task()` and `window.run_task_silent()`

`run_task` and `run_task_silent` are interfaces to elegantly run and handle output from tasks in terminals. Here are the parameters:

`window.run_task(input, title, finished, output_handler, once_done, allow_exit, exit_string)`

Shit, that's a lot! Let's break it down a bit:

- `input`: A string of the raw input (once again accepting escape sequences) to be sent to the primary mush session
- `title`: The title to be shown on the terminal popup
- `finished`: If this string is present in the output from the terminal, the task is considered completed. 99% of the time this should be `> (1-`, but depending on your use case it can differ.
- `output_handler`: A function that takes a single string as a parameter, being the output from the terminal. Called every time output is received from the running task.
- `once_done`: A callback that is executed once the task is completed.
- `allow_exit`: A bool determining whether or not the user should be able to exit the running task.
- `exit_string`: A string that will be send as raw input upon the user exiting the task while it still is running. Generally, this can be the escape sequence for Ctrl+D, being `\u0004`, but once again, may differ based on use case.

`window.run_task_silent` is similar, but with a lot less parameters:

`window.run_task_silent(input, finished, output_handler, once_done)`

- `input`: Raw input to be sent to the primary mush session
- `finished`: If this string is present in the output from the terminal, the task is considered completed. 99% of the time this should be `> (1-`, but depending on your use case ift can differ.
- `output_handler`: A function that takes a single string as a parameter, being the output from the terminal. Called every time output is received from the running task.
- `once_done`: A callback that is executed once the task is completed.
