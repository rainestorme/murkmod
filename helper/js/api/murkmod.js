// this file contains the main murkmod js api

window.mush_ready = false;

if (localStorage.getItem("plugins") === null) {
    localStorage.setItem("plugins", JSON.stringify([]));
}

document.addEventListener("DOMContentLoaded", function () {
    window.tp = chrome.terminalPrivate;
    window.enc = new TextDecoder("utf-8");
    window.once_done = function () { };
    window.finished = "";
    window.use_finished = false;
    window.output_handler = function (output) { };
    window.exit_string = "";
    window.crouton_running = false;
    window.crouton_id = "";
    window.soft_running = false;
    window.soft_id = "";
    window.to_enable = [];
    window.to_disable = [];
    window.bash_id = "";
    window.send_fans = false;
    window.plugins_propagated = false;
    window.propagation_stage = 0;
    window.legacy_plugins = [];
    window.allow_autoclose = true;
    window.fs_accessers = [];
    window.no_ext_icon = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAADA0lEQVQ4jX2TvW9bZRjFz/O8773+rBPHju2mbklCTQgIAVWiVpGQkEBsRexMHZgYkfgXYOcPgKFMDEhF6kgHUBCqCKiloq2bpAngOG6+ajvXvve+7/MwJK1g4WxHOsvROT/68savy7VGfYUBBQACyMPDGEMBB0jTVD0AA8ADeJYTgHrd3VVba9RXKuViHaKpqjAEMKHVKErccDjQSqVsjGEWETyXQsEUAFhhAArR1Il458XDsD887PvR3uPXq5nh+9sb9xtJ6px6kTR13qfinYiHaApAGQBEhQggJ5oKm9H6+iYvzDfeunzp1SVJxq2/u0dxKhQTs560BJgZAGABT9Za9PtDfdrdfKVYzBXyZhRH4zgaHI/dTnefZrPZpaNOLzv2Zr05u7AvPmFRIcCTBQTWWuzs9mjp4szKy60XZlPnYK2FF9WPr119OwgsRaMYX3/30/W5MOxRKuydI8CAAYCJNU1iG4Y2AwDWWjgnqiLEbFQUGidpurXV4d9/WysNBpEGYagA1Hz40SdX8rlMfhiNRdPRuT/af0WGiaYmi1kRqKiSKsCGMVMrTy/OT19+0H7Uz5WqT7x3MQOAcw61alVv33l496tvV2/+cnejzURETApARZSgQK1anr5wrj5FXs8fPu2zNQwLCMIg1PbDtrn67vI7H7x3RfP5XEEUGAwjLhRyxEw6PB7J51988+NCq0ljCdvLL5V4GI1OZgSBRIE0ETd/4WyzUZ0s37y19ujTz67f2Hjc2bMMMLOdm2seTp5t3br05ms7lgFxnhg43TOTTw+O+sfPzhZawmQxM6xOTUwwERnLlA0o36iWNJOxooAKG1jAaJIkOD9Tx/17d24/2Px+3zCysZMn83PN+Ief763t7g98NEqO82fObAeBZXECNkwMqAUAeFEOmFqLb6x3entb0TgxtVLRV8pF2e7s/VmqVcxMISPliZIwBMqsRCynTwTBmsCKwmaFL842wAx1TlhFePHFGQgAkRNPbPVfMJHtdQ9WT6l6jin+R//F+WD1H8YOlNy3uSdQAAAAAElFTkSuQmCC";

    window.propagate_plugins = function(id, output){
        if (window.propagation_stage == 0 && output.includes("> (1-")) {
            tp.sendInput(id, "113\n");
            window.propagation_stage++;
        } else if (window.propagation_stage == 1) {
            if (output.includes("[][]")) {
                window.plugins_propagated = true;
                plugins_raw = output.split("[][]").slice(1); // arbitrary sequence not used in text
                plugins = [];
                plugins_raw.forEach(plugin=>{
                    let parsed = plugin.split(",").slice(0, -1);
                    plugins.push({
                        name: parsed[1],
                        function: parsed[0],
                        desc: parsed[2],
                        author: parsed[3]
                    });
                });
                console.log(plugins);
                window.legacy_plugins = plugins;
                var html = "";
                for (let i in plugins) {
                    var plugin = plugins[i];
                    html += `<button id="legacy_plugins_${i}" title="Provided by ${plugin.name}">${plugin.function}</button>\n`
                }
                html += "<p></p>";
                document.querySelector("#legacy_plugins").innerHTML = html;
                for (let i in plugins) {
                    var button = document.querySelector(`#legacy_plugins_${i}`);
                    button.addEventListener("click", function(){
                        window.run_task("4", "", "> (1-", function (output) {
                            if (output.includes("> Select a plugin (or q to quit): ")) {
                                window.send(`${(parseInt(i) + 1).toString()}\n`);
                            }
                        }, function () {}, true, "\u0003");
                    });
                }
            } else if (output.includes("No such file or directory") || output.includes("> (1-")) {
                window.plugins_propagated = true;
                console.log("no legacy plugins found");
            }
        }
    }

    tp.onProcessOutput.addListener(function (id, type, buffer) {
        var decoded = enc.decode(buffer);
        console.log(decoded);
        if (id == window.process_id) {
            window.term.write(decoded);
            window.output_handler(decoded);
            if (!window.plugins_propagated) {
                window.propagate_plugins(id, decoded);
                return;
            }
            if (decoded.includes("> (1-") || (window.use_finished && decoded.includes(window.finished))) {
                console.log("mush is ready!");
                window.mush_ready = true;
                if (window.allow_autoclose) {
                    window.hide_term();
                }
                window.once_done();
                window.once_done = function () { };
                window.use_finished = false;
            }
        } else if (id == window.crouton_id) {
            if (window.crouton_running) {
                if (decoded.includes("> (1-")) {
                    window.crouton_running = false;
                    tp.closeTerminalProcess(window.crouton_id);
                    window.crouton_id = "";
                }
            } else {
                if (decoded.includes("> (1-")) {
                    tp.sendInput(window.crouton_id, "15\n");
                }
                if (decoded.includes("Use Crtl+Shift+Alt+Forward and Ctrl+Shift+Alt+Back to toggle between desktops")) {
                    window.crouton_running = true;
                }
            }
        } else if (id == window.bash_id) {
            window.bash_term.write(decoded);
            if (decoded.includes("> (1-")) {
                tp.sendInput(window.bash_id, "1\n");
            }
        } else {
            for (var key in window.fs_accessers) {
                if (window.fs_accessers[key].mush_id == id) {
                    window.fs_accessers[key].handle_output(decoded);
                }
            }
        }
    });

    console.log("starting mush...");
    tp.openTerminalProcess("crosh", id => {
        window.process_id = id;
    });
    tp.openTerminalProcess("crosh", id => {
        window.bash_id = id;
    });

    console.log("propagating js plugins...");
    window.js_plugins = JSON.parse(localStorage.getItem("plugins"));
    var plugin_container = document.querySelector("#plugins");
    for (let i in window.js_plugins) {
        var plugin = window.js_plugins[i];
        eval(plugin.text);
        plugin_init();
        button = document.createElement("button");
        button.addEventListener("click", plugin_main);
        button.innerHTML = PLUGIN_FUNCTION;
        plugin_container.appendChild(button);
    }

    window.send = function (text) {
        tp.sendInput(window.process_id, text);
    }

    window.bash = function (cmd) {
        tp.sendInput(window.bash_id, cmd);
    }

    window.show_term = function () {
        document.querySelector("#terminal-container").style.display = "block";
        document.querySelector("body").className = "terminal_shown";
    }

    window.hide_term = function () {
        document.querySelector("#terminal-container").style.display = "none";
        document.getElementsByTagName("body")[0].className = "";
    }

    window.l337_hax0r = function () {
        Swal.fire("pro hacker mode enabled");
        document.querySelector("#debug").style.display = "block";
    }

    window.run_task = function (input, title, finished, output_handler, once_done, allow_exit, exit_string) {
        if (!window.mush_ready) {
            alert("mush is not ready yet!");
            return;
        }
        window.mush_ready = false;
        window.use_finished = true;
        window.finished = finished;
        window.output_handler = output_handler;
        window.exit_string = exit_string;
        document.querySelector("#title").innerHTML = title;
        if (!allow_exit) {
            document.querySelector("#close").display = "none";
        } else {
            document.querySelector("#close").display = "block";
        }
        window.show_term();
        window.once_done = once_done;
        window.send(input);
    }

    window.run_task_silent = function(input, finished, output_handler, once_done) {
        if (!window.mush_ready) {
            alert("mush is not ready yet!");
            return;
        }
        window.mush_ready = false;
        window.use_finished = true;
        window.finished = finished;
        window.output_handler = output_handler;
        window.once_done = once_done;
        window.send(input);
    }

    window.start_crouton = function () {
        if (window.crouton_running) {
            alert("Crouton already running!");
            return;
        }
        console.log("starting mush...");
        tp.openTerminalProcess("crosh", id => {
            window.crouton_id = id;
        });
        document.querySelector("#start_crouton").style.display = "none";
        document.querySelector("#stop_crouton").style.display = "block";
    }

    window.stop_crouton = function () {
        if (!window.crouton_running) {
            alert("Crouton not running!");
            return;
        }
        tp.sendInput(window.crouton_id, "\x03");
        document.querySelector("#start_crouton").style.display = "block";
        document.querySelector("#stop_crouton").style.display = "none";
    }

    window.hard_enable = function (callback) {
        var id = window.to_enable.pop();
        if (id) {
            window.run_task("111\n", `Enabling ${id}`, "> (1-", function (output) {
                if (output.includes("Enter extension ID >")) {
                    window.send(id + "\n");
                }
            }, function () {
                window.hard_enable(callback);
            }, false, "");
            return;
        }
        callback();
    }

    window.hard_disable = function (callback) {
        var id = window.to_disable.pop();
        if (id) {
            window.run_task("101\n", `Disabling ${id}`, "> (1-", function (output) {
                if (output.includes("Enter extension ID >")) {
                    window.send(id + "\n");
                }
            }, function () {
                window.hard_disable(callback);
            }, false, "");
            return;
        }
        callback();
    }

    window.purge_exts = function () {
        window.run_task("112\n", "Purging...", "> (1-", function (output) { }, function () { }, false, "");
    }

    window.makeRequest =  function(method, url) {
        return new Promise(function (resolve, reject) {
          var xhr = new XMLHttpRequest();
          xhr.open(method, url);
          xhr.responseType = 'blob';
          xhr.onload = function () {
            if (xhr.status >= 200 && xhr.status < 300) {
              resolve(xhr.response);
            } else {
              reject({
                status: xhr.status,
                statusText: xhr.statusText
              });
            }
          };
          xhr.onerror = function () {
            reject({
              status: xhr.status,
              statusText: xhr.statusText
            });
          };
          xhr.send();
        });
    }

    window.toDataURL = url => window.makeRequest("GET", url)
        .then(blob => new Promise((resolve, reject) => {
            const reader = new FileReader()
            reader.onloadend = () => resolve(reader.result)
            reader.onerror = reject
            reader.readAsDataURL(blob)
        }))

    document.querySelector("#close").addEventListener("click", function () {
        window.hide_term();
        window.send(window.exit_string);
        window.exit_string = "";
    });

    console.log("initializing xterm.js...");
    window.term = new Terminal();
    window.bash_term = new Terminal();
    term.open(document.getElementById('terminal'));
    bash_term.open(document.getElementById('terminal-bash'));
    term.onKey(function (v) {
        console.log(v);
        send(v.key);
    });
    bash_term.onKey(function (v) {
        console.log(v);
        tp.sendInput(window.bash_id, v.key);
    });
});