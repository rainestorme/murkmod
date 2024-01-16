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
    window.no_ext_icon = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAADA0lEQVQ4jX2TvW9bZRjFz/O8773+rBPHju2mbklCTQgIAVWiVpGQkEBsRexMHZgYkfgXYOcPgKFMDEhF6kgHUBCqCKiloq2bpAngOG6+ajvXvve+7/MwJK1g4WxHOsvROT/68savy7VGfYUBBQACyMPDGEMBB0jTVD0AA8ADeJYTgHrd3VVba9RXKuViHaKpqjAEMKHVKErccDjQSqVsjGEWETyXQsEUAFhhAArR1Il458XDsD887PvR3uPXq5nh+9sb9xtJ6px6kTR13qfinYiHaApAGQBEhQggJ5oKm9H6+iYvzDfeunzp1SVJxq2/u0dxKhQTs560BJgZAGABT9Za9PtDfdrdfKVYzBXyZhRH4zgaHI/dTnefZrPZpaNOLzv2Zr05u7AvPmFRIcCTBQTWWuzs9mjp4szKy60XZlPnYK2FF9WPr119OwgsRaMYX3/30/W5MOxRKuydI8CAAYCJNU1iG4Y2AwDWWjgnqiLEbFQUGidpurXV4d9/WysNBpEGYagA1Hz40SdX8rlMfhiNRdPRuT/af0WGiaYmi1kRqKiSKsCGMVMrTy/OT19+0H7Uz5WqT7x3MQOAcw61alVv33l496tvV2/+cnejzURETApARZSgQK1anr5wrj5FXs8fPu2zNQwLCMIg1PbDtrn67vI7H7x3RfP5XEEUGAwjLhRyxEw6PB7J51988+NCq0ljCdvLL5V4GI1OZgSBRIE0ETd/4WyzUZ0s37y19ujTz67f2Hjc2bMMMLOdm2seTp5t3br05ms7lgFxnhg43TOTTw+O+sfPzhZawmQxM6xOTUwwERnLlA0o36iWNJOxooAKG1jAaJIkOD9Tx/17d24/2Px+3zCysZMn83PN+Ief763t7g98NEqO82fObAeBZXECNkwMqAUAeFEOmFqLb6x3entb0TgxtVLRV8pF2e7s/VmqVcxMISPliZIwBMqsRCynTwTBmsCKwmaFL842wAx1TlhFePHFGQgAkRNPbPVfMJHtdQ9WT6l6jin+R//F+WD1H8YOlNy3uSdQAAAAAElFTkSuQmCC";

    window.propagate_plugins = function(id, output){
        if (window.propagation_stage == 0 && output.includes("> (1-")) {
            tp.sendInput(id, "113\n");
            window.propagation_stage++;
        } else if (window.propagation_stage == 1 && output.includes("[][]")) {
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
                    window.run_task("4\n", "", "> (1-", function (output) {
                        if (output.includes("> Select a plugin (or q to quit): ")) {
                            window.send(`${(parseInt(i) + 1).toString()}\n`);
                        }
                    }, function () {}, true, "\u0003");
                });
            }
        }
    }

    tp.onProcessOutput.addListener(function (id, type, buffer) {
        if (id == window.process_id) {
            var decoded = enc.decode(buffer);
            console.log(decoded);
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
            var decoded = enc.decode(buffer);
            console.log(decoded);
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
            var decoded = enc.decode(buffer);
            console.log(decoded);
            window.bash_term.write(decoded);
            if (decoded.includes("> (1-")) {
                tp.sendInput(window.bash_id, "1\n");
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

    // update murkmod
    document.querySelector("#update_murkmod").addEventListener("click", function () {
        window.run_task("25\n", "Updating murkmod - please respond to prompts if neccesary.", "key to exit.", function (output) {
            if (output.toLowerCase().includes("[y/n]")) {
                var lines = output.split('\n');
                for (let i in lines) {
                    if (lines[i].toLowerCase().includes("[y/n]")) {
                        Swal.fire({
                            text: lines[i].split(" [")[0],
                            showCancelButton: true,
                            confirmButtonColor: '#3085d6',
                            cancelButtonColor: '#d33',
                            confirmButtonText: 'Yes',
                            cancelButtonText: 'No'
                        }).then((result) => {
                            if (result.isConfirmed) {
                                window.send("y\n");
                            } else {
                                window.send("n\n")
                            }
                        });
                    }
                }
            }
        },
            function () {
                console.log("Reloading mush...");
                window.mush_ready = false;
                tp.openTerminalProcess("crosh", id => {
                    window.process_id = id;
                });
            }, false, "");
    });

    // root shell
    document.querySelector("#root_shell").addEventListener("click", function () {
        window.run_task("1\n", "", "> (1-", function (output) { }, function () { }, true, "\u0004");
    });

    // chronos shell
    document.querySelector("#chronos_shell").addEventListener("click", function () {
        window.run_task("2\n", "", "> (1-", function (output) { }, function () { }, true, "\u0004");
    });

    // crosh
    document.querySelector("#crosh").addEventListener("click", function () {
        window.run_task("3\n", "", "> (1-", function (output) { }, function () { }, true, "\u0004");
    });

    // emergency revert
    document.querySelector("#emergency_revert").addEventListener("click", function () {
        Swal.fire({
            title: 'Are you sure?',
            text: "This option will re-enroll your chromebook and restore it to its exact state before fakemurk was run. This is useful if you need to quickly go back to normal. This is *permanent*. You will not be able to use murkmod again unless you re-run everything from the beginning.",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#3085d6',
            cancelButtonColor: '#d33',
            confirmButtonText: 'Yes! Burn it to the ground!'
        }).then((result) => {
            if (result.isConfirmed) {
                window.run_task("8\n", "", "> (1-", function (output) {
                    if (output.includes("Are you sure - 100% sure - that you want to continue?")) {
                        window.send("\n");
                    }
                }, function () { }, false, "");
            }
        });
    });

    // powerwash
    document.querySelector("#powerwash").addEventListener("click", function () {
        Swal.fire({
            title: 'Are you sure you wanna powerwash?',
            text: "This will wipe everything but won't remove murkmod.",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#3085d6',
            cancelButtonColor: '#d33',
            confirmButtonText: 'Yes! Burn it to the ground!'
        }).then((result) => {
            if (result.isConfirmed) {
                window.run_task("14\n", "", "> (1-", function (output) {
                    if (output.includes("(Press enter to continue, ctrl-c to cancel)")) {
                        window.send("\n");
                    }
                }, function () { }, false, "");
            }
        });
    });

    // install crouton
    document.querySelector("#install_crouton").addEventListener("click", function () {
        window.run_task("14\n", "", "> (1-", function (output) { }, function () { }, false, "");
    });

    // start/stop crouton
    document.querySelector("#start_crouton").addEventListener("click", window.start_crouton);
    document.querySelector("#stop_crouton").addEventListener("click", window.stop_crouton);

    // extension controls
    document.querySelector("#automagically").addEventListener("click", function () {
        window.run_task("12\n", "", "> (1-", function (output) { }, function () { }, false, "");
    });
    document.querySelector("#closeexts").addEventListener("click", function () {
        document.querySelector("#ext-modal").style.display = "none";
    });
    document.querySelector("#purge_exts").addEventListener("click", window.purge_exts);
    document.querySelector("#manage_exts").addEventListener("click", function () {
        chrome.management.getAll(exts => {
            var modal = document.querySelector("#ext-modal");
            var content = document.querySelector("#ext-content");
            var html = `<button id="ext-save-changes">Save changes</button>
                        <br>
                        <p id="exts-loading">Loading...</p>
                        <table id="ext-table" style="display: none; width: 100%;">
                            <tr>
                                <th>Name</th>
                                <th>ID</th>
                                <th>Enabled</th>
                            </tr>`;
            for (let i in exts) {
                var ext = exts[i];
                html += `<tr><td>${ext.name}</td> <td>${ext.id}</td> <td><input type="checkbox" id="checkbox-exts-${i}"></input></td></div></tr>`;
            }
            html += `</table>`
            content.innerHTML = html;
            for (let i in exts) {
                var ext = exts[i];
                var ext_icon = window.toDataURL(ext.icons[0].url).then(ext_icon=>{
                    console.log(ext_icon);
                    var hard_enabled = (ext_icon != window.no_ext_icon);
                    exts[i].hard_enabled = hard_enabled;
                    document.querySelector(`#checkbox-exts-${i}`).checked = hard_enabled;
                    if (i == (exts.length - 1)) {
                        document.querySelector("#exts-loading").style.display = "none";
                        document.querySelector("#ext-table").style.display = "block";
                    }
                });
            }
            document.querySelector("#ext-save-changes").addEventListener("click", function () {
                window.to_enable = [];
                window.to_disable = [];
                for (let i in exts) {
                    var ext = exts[i];
                    var checkbox = document.getElementById(`checkbox-exts-${i}`);
                    let checked = checkbox.checked;
                    let id = ext.id;
                    if (ext.hard_enabled != checked) {
                        if (checked) {
                            window.to_enable.push(ext.id);
                        } else {
                            window.to_disable.push(ext.id);
                        }
                    }
                }
                console.log(window.to_enable);
                console.log(window.to_disable);
                modal.style.display = "none";
                window.hard_enable(function () {
                    window.hard_disable(function () {
                        window.purge_exts();
                    });
                });
            });
            modal.style.display = "block";
        });
    });

    // experiments
    document.querySelector("#update_chromeos").addEventListener("click", function () {
        window.run_task("20\n", "", "> (1-", function (output) { }, function () { }, false, "");
    });
    document.querySelector("#update_backup").addEventListener("click", function () {
        window.run_task("21\n", "", "> (1-", function (output) { }, function () { }, false, "");
    });
    document.querySelector("#restore_backup_backup").addEventListener("click", function () {
        window.run_task("22\n", "", "> (1-", function (output) { }, function () { }, false, "");
    });
    document.querySelector("#chromebrew").addEventListener("click", function () {
        window.run_task("23\n", "", "> (1-", function (output) { }, function () { }, false, "");
    });
    document.querySelector("#dev_install").addEventListener("click", function () {
        window.run_task("24\n", "", "> (1-", function (output) { }, function () { }, false, "");
    });
    document.querySelector("#boot_usb_on").addEventListener("click", function () {
        window.run_task("16\n", "", "> (1-", function (output) { }, function () { }, false, "");
    });
    document.querySelector("#boot_usb_off").addEventListener("click", function () {
        window.run_task("17\n", "", "> (1-", function (output) { }, function () { }, false, "");
    });

    //system control
    document.querySelector("#fans").addEventListener("input", function () {
        document.getElementById('fanprecent').innerHTML = this.value.toString() + '%';
        window.send_fans = true;
    });
    document.querySelector("#reboot").addEventListener("click", function(){
        window.bash("reboot\n");
    });
    setInterval(function () {
        if (window.send_fans) {
            window.send_fans = false;
            window.bash(`ectool fanduty ${document.querySelector("#fans").value.toString()}\n`);
        }
    }, 1000);
    
    // plugin store
    const extractValue = (variable, script) => {
        const regex = new RegExp(`${variable}="(.*?)"`);
        const match = script.match(regex);
        return match ? match[1] : null;
    };
    document.querySelector("#store").addEventListener("click", function() {
        Swal.fire({
            title: 'Loading plugin store...',
            didOpen: () => {
              Swal.showLoading();
            },
            allowOutsideClick: true,
            allowEscapeKey: true,
            allowEnterKey: true,
            showConfirmButton: false
        });
        fetch("https://api.github.com/repos/rainestorme/murkmod/contents/plugins")
            .then(response => {return response.json()})
            .then(json => {
                Swal.close();
                html = "";
                for (let i in json) {
                    var file = json[i];
                    if (file.type == "file" && (file.name.endsWith(".sh") || file.name.endsWith(".js"))) {
                        console.log("generating card for " + file.name);
                        html += `<div class="card" id="card-${file.name.split(".")[0]}-${file.name.split(".")[1]}">
                                    <div class="card-title">${file.name}</div>
                                    <div class="card-description">loading...</div>
                                </div>`;
                    }
                }
                document.querySelector("#store-content").innerHTML = html;
                for (let i in json) {
                    let file = json[i];
                    console.log(file);
                    if (file.type == "file" && (file.name.endsWith(".sh") || file.name.endsWith(".js"))) {
                        if (file.name.endsWith(".sh")) {
                            fetch(file.download_url)
                                .then(response => {return response.text()})
                                .then(text => {
                                    var card = document.querySelector(`#card-${file.name.split(".")[0]}-${file.name.split(".")[1]}`);
                                    console.log(card);
                                    const PLUGIN_NAME = extractValue("PLUGIN_NAME", text);
                                    const PLUGIN_FUNCTION = extractValue("PLUGIN_FUNCTION", text);
                                    const PLUGIN_DESCRIPTION = extractValue("PLUGIN_DESCRIPTION", text);
                                    const PLUGIN_AUTHOR = extractValue("PLUGIN_AUTHOR", text);
                                    console.log(PLUGIN_NAME, PLUGIN_FUNCTION, PLUGIN_DESCRIPTION, PLUGIN_AUTHOR);
                                    var install_btn = "Install";
                                    var installed = false;
                                    for (let i in window.legacy_plugins) {
                                        if (window.legacy_plugins[i].name === PLUGIN_NAME) {
                                            installed = true;
                                            install_btn = "Uninstall";
                                        }
                                    }
                                    card.innerHTML = `<div class="card-title">${PLUGIN_NAME}<div>
                                                      <div class="card-author">By ${PLUGIN_AUTHOR} - Bash</div>
                                                      <div class="card-description">${PLUGIN_DESCRIPTION}</div>
                                                      <button id="card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-installbtn">${install_btn}</button>`;
                                    document.querySelector(`#card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-installbtn`).addEventListener("click", function(){
                                        if (document.querySelector(`#card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-installbtn`).innerHTML === "Uninstall") {
                                            window.run_task("115\n", "", "> (1-", function (output) {
                                                if (output.includes("Enter the name of a plugin (including the .sh) to uninstall it (or q to quit):")) {
                                                    window.send(`${file.name}\n`);
                                                }
                                            }, function () {
                                                window.location.reload();
                                            }, false, "");
                                            return;
                                        }
                                        window.run_task("114\n", "", "> (1-", function (output) {
                                            if (output.includes("Enter the name of a plugin (including the .sh) to install it (or q to quit):")) {
                                                window.send(`${file.name}\n`);
                                            }
                                        }, function () {
                                            window.location.reload();
                                        }, false, "");
                                    });
                                });
                        } else {
                            var installed_plugins = JSON.parse(localStorage.getItem("plugins"));
                            var already_installed = false;
                            for (let i in installed_plugins) {
                                plugin = installed_plugins[i];
                                if (plugin.file.name === file.name) {
                                    already_installed = true;
                                }
                            }
                            fetch(file.download_url)
                                .then(response => {return response.text()})
                                .then(text => {
                                    var card = document.querySelector(`#card-${file.name.split(".")[0]}-${file.name.split(".")[1]}`);
                                    eval(text);
                                    var install_btn = "Install";
                                    if (already_installed) {
                                        install_btn = "Uninstall";
                                    }
                                    card.innerHTML = `<div class="card-title">${PLUGIN_NAME}<div>
                                                      <div class="card-author">By ${PLUGIN_AUTHOR} - JavaScript</div>
                                                      <div class="card-description">${PLUGIN_DESCRIPTION}</div>
                                                      <button id="card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-installbtn">${install_btn}</button>`;
                                    document.querySelector(`#card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-installbtn`).addEventListener("click", function(){
                                        // uninstall
                                        if (document.querySelector(`#card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-installbtn`).innerHTML === "Uninstall") {
                                            var keep = [];
                                            for (let i in installed_plugins) {
                                                if (installed_plugins[i].file.name !== file.name) {
                                                    keep.push(installed_plugins[i]);
                                                }
                                            }
                                            localStorage.setItem("plugins", JSON.stringify(keep));
                                            window.location.reload();
                                            return;
                                        }
                                        // install
                                        installed_plugins.push({
                                            file: file,
                                            text: text
                                        });
                                        localStorage.setItem("plugins", JSON.stringify(installed_plugins));
                                        window.location.reload();
                                    });
                                });
                        }
                    }
                }
                document.querySelector("#store-modal").style.display = "block";
            });
    });
    document.querySelector("#closestore").addEventListener("click", function(){
        document.querySelector("#store-modal").style.display = "none";
    });

    // plugin builder
    // document.querySelector("#builder").addEventListener("click", function() {
    //     Swal.fire("under construction");
    // });

    // debug
    document.querySelector("#show_mush").addEventListener("click", function() {
        show_term();
    });
    var allowedKeys = {
        37: 'left',
        38: 'up',
        39: 'right',
        40: 'down',
        65: 'a',
        66: 'b'
    };
    var konamiCode = ['up', 'up', 'down', 'down', 'left', 'right', 'left', 'right', 'b', 'a'];
    var konamiCodePosition = 0;
    document.addEventListener('keydown', function (e) {
        var key = allowedKeys[e.keyCode];
        var requiredKey = konamiCode[konamiCodePosition];
        if (key == requiredKey) {
            konamiCodePosition++;
            if (konamiCodePosition == konamiCode.length) {
                window.l337_hax0r();
                konamiCodePosition = 0;
            }
        } else {
            konamiCodePosition = 0;
        }
    });
    document.querySelector("#close-bash").addEventListener('click', function(){
        document.querySelector("#terminal-bash-container").style.display = "none";
    });
    document.querySelector("#show_bash").addEventListener('click', function(){
        document.querySelector("#terminal-bash-container").style.display="block";
    });
    document.querySelector("#no_term_autoclose").addEventListener('click', function(){
        window.allow_autoclose = false;
    });
    document.querySelector("#do-xss").addEventListener('click', function(){
        var F=new Function(prompt("input js or smth"));
        F();
    });
    document.querySelector("#disable_debug").addEventListener('click', function(){
        document.querySelector("#debug").style.display = "none";
    });

    document.querySelector("#point_blank").addEventListener('click', function(){
        open();
    });
});