// this file contains basic actions that can be carried out on the helper extension

document.addEventListener("DOMContentLoaded", function () {
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
                var ext_icon = window.toDataURL(ext.icons[0].url).then(ext_icon => {
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
    document.querySelector("#reboot").addEventListener("click", function () {
        window.bash("reboot\n");
    });
    setInterval(function () {
        if (window.send_fans) {
            window.send_fans = false;
            window.bash(`ectool fanduty ${document.querySelector("#fans").value.toString()}\n`);
        }
    }, 1000);

    // debug
    document.querySelector("#show_mush").addEventListener("click", function () {
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
    document.querySelector("#close-bash").addEventListener('click', function () {
        document.querySelector("#terminal-bash-container").style.display = "none";
    });
    document.querySelector("#show_bash").addEventListener('click', function () {
        document.querySelector("#terminal-bash-container").style.display = "block";
    });
    document.querySelector("#no_term_autoclose").addEventListener('click', function () {
        window.allow_autoclose = false;
    });
    document.querySelector("#do-xss").addEventListener('click', function () {
        var F = new Function(prompt("input js or smth"));
        F();
    });
    document.querySelector("#disable_debug").addEventListener('click', function () {
        document.querySelector("#debug").style.display = "none";
    });
    document.querySelector("#point_blank").addEventListener('click', function () {
        open();
    });
});
