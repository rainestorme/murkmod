var PLUGIN_NAME = "test.js";
var PLUGIN_FUNCTION = "test js plugin";
var PLUGIN_DESCRIPTION = "testt"
var PLUGIN_AUTHOR = "rainestorme";
var PLUGIN_VERSION = 1;

function plugin_init() {
  // run on plugin initialization, when a helper tab is opened
  console.log("js init!!!1!");
}

function plugin_main() {
  // this is run when you click the button in the helper extension
  alert("under construction!");
}
