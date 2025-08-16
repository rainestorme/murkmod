// contains logic for the plugin store

function generate_loading_cards(json, elem) {
    var html = "";
    for (let i in json) {
        var file = json[i];
        if (file.type == "file" && (file.name.endsWith(".sh") || file.name.endsWith(".js"))) {
            html += `<div class="card" id="card-${file.name.split(".")[0]}-${file.name.split(".")[1]}">
                                <div class="card-title">${file.name}</div>
                                <div class="card-description">loading...</div>
                            </div>`;
        }
    }
    elem.innerHTML = html;
}
function extractValue(variableName, scriptContent) {
    const regex = new RegExp(`^${variableName}="([^"]*)"`, "m");
    const match = scriptContent.match(regex);
    return match?.[1];
}

function generate_bash_card(file) {
    fetch(file.download_url)
        .then(response => { return response.text() })
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
            if (installed) {
                card.innerHTML = card.innerHTML + `<button id="card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-updatebtn">Update</button>`
                document.querySelector(`#card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-updatebtn`).addEventListener("click", function () {
                    window.run_task("115\n", "", "> (1-", function (output) {
                        if (output.includes("Enter the name of a plugin (including the .sh) to uninstall it (or q to quit):")) {
                            window.send(`${file.name}\n`);
                        }
                    }, function () {
                        window.run_task("114\n", "", "> (1-", function (output) {
                            if (output.includes("Enter the name of a plugin (including the .sh) to install it (or q to quit):")) {
                                window.send(`${file.name}\n`);
                            }
                        }, function () {
                            window.location.reload();
                        }, false, "");
                    }, false, "");
                });
            }
            document.querySelector(`#card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-installbtn`).addEventListener("click", function () {
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
}

function generate_js_card(file) {
    var installed_plugins = JSON.parse(localStorage.getItem("plugins"));
    var already_installed = false;
    for (let i in installed_plugins) {
        plugin = installed_plugins[i];
        if (plugin.file.name === file.name) {
            already_installed = true;
        }
    }
    fetch(file.download_url)
        .then(response => { return response.text() })
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
            document.querySelector(`#card-${file.name.split(".")[0]}-${file.name.split(".")[1]}-installbtn`).addEventListener("click", function () {
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

function generate_cards(json) {
    for (let i in json) {
        let file = json[i];
        if (file.type == "file" && (file.name.endsWith(".sh") || file.name.endsWith(".js"))) {
            if (file.name.endsWith(".sh")) {
                generate_bash_card(file);
            } else {
                generate_js_card(file);
            }
        }
    }
}

function show_store(json) {
    Swal.close();
    generate_loading_cards(json, document.querySelector("#store-content"));
    generate_cards(json);
    document.querySelector("#store-modal").style.display = "block";
}

document.addEventListener("DOMContentLoaded", function () {

    document.querySelector("#store").addEventListener("click", function () {
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
            .then(response => { return response.json() })
            .then(show_store);
    });

    document.querySelector("#closestore").addEventListener("click", function () {
        document.querySelector("#store-modal").style.display = "none";
    });


    // plugin builder
    // document.querySelector("#builder").addEventListener("click", function() {
    //     Swal.fire("under construction");
    // });
});
