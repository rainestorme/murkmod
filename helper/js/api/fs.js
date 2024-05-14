class MurkmodFsAccess {
    constructor() {
        this.working_dir = "/";
        this.mush_id = null;
        this.listeners = [];
        this.read_buffer = "";
        this.read_start_tripped = false;
        var self = this;
        tp.openTerminalProcess("crosh", id => {
            self.mush_id = id;
            window.fs_accessers.push(self);
        });
    }

    _generic_singlestep_promise(input, wait_for, response) {
        var self = this;
        return new Promise((resolve, reject) => {
            tp.sendInput(self.mush_id, input);
            self.listeners.push(function(decoded){
                if (decoded.includes(wait_for)) {
                    tp.sendInput(self.mush_id, response);
                } else if (decoded.includes("> (1-")) {
                    const index = self.listeners.indexOf(this);
                    if (index > -1) {
                        array.splice(index, 1);
                    }
                    resolve();
                }
            });
        });
    }

    _generic_doublestep_promise(input, wait_for1, response1, wait_for2, response2) {
        var self = this;
        return new Promise((resolve, reject) => {
            tp.sendInput(self.mush_id, input);
            self.listeners.push(function(decoded){
                if (decoded.includes(wait_for1)) {
                    tp.sendInput(self.mush_id, response1);
                } else if (decoded.includes(wait_for2)) {
                    tp.sendInput(self.mush_id, response1);
                } else if (decoded.includes("> (1-")) {
                    const index = self.listeners.indexOf(this);
                    if (index > -1) {
                        array.splice(index, 1);
                    }
                    resolve();
                }
            });
        });
    }

    handle_output(decoded) {
        for (var key in this.listeners) {
            this.listeners[key](decoded);
        }
    }

    cd(new_dir) {
        var self = this;
        return new Promise((resolve, reject) => {
            tp.sendInput(self.mush_id, "209\n");
            self.listeners.push(function(decoded){
                if (decoded.includes("dir?")) {
                    tp.sendInput(self.mush_id, new_dir + "\n");
                } else if (decoded.includes("> (1-")) {
                    self.working_dir = new_dir;
                    const index = self.listeners.indexOf(this);
                    if (index > -1) {
                        array.splice(index, 1);
                    }
                    resolve();
                }
            });
        });
    }

    ls() {
        return this._generic_singlestep_promise("208\n",
                                                "dirname? (or . for current dir)",
                                                ".\n");
    }

    ls(dir) {
        return this._generic_singlestep_promise("208\n",
                                                "dirname? (or . for current dir)",
                                                dir + "\n");
    }

    rm_dir(dir) {
        return this._generic_singlestep_promise("207\n",
                                                "dirname?",
                                                dir + "\n");
    }

    rm_file(file) {
        return this._generic_singlestep_promise("206\n",
                                                "filename?",
                                                file + "\n");
    }

    mkdir(dir) {
        return this._generic_singlestep_promise("205\n",
                                                "dirname?",
                                                dir + "\n");
    }

    touch(file) {
        return this._generic_singlestep_promise("204\n",
                                                "filename?",
                                                file + "\n");
    }

    append(file, content){
        return this._generic_doublestep_promise("203\n",
                                                "file to write to?",
                                                file + "\n",
                                                "base64 contents to append?",
                                                btoa(content));
    }

    write(file, content) {
        return this._generic_doublestep_promise("202\n",
                                                "file to write to?",
                                                file + "\n",
                                                "base64 contents?",
                                                btoa(content));
    }

    read(file) {
        var self = this;
        return new Promise((resolve, reject) => {
            tp.sendInput(self.mush_id, input);
            self.listeners.push(function(decoded){
                if (self.read_start_tripped) {
                    self.read_buffer = self.read_buffer + decoded;
                }
                if (decoded.includes("file to read?")) {
                    tp.sendInput(self.mush_id, file+"\n");
                }
                if (decoded.includes("start content: ")) {
                    self.read_start_tripped = true;
                }
                if (self.read_buffer.includes("end content")) {
                    var startIndex = self.read_buffer.indexOf("start content: ") + "start content: ".length;
                    var endIndex = self.read_buffer.indexOf("end content");
                    var content = atob(self.read_buffer.substring(startIndex, endIndex));
                    self.read_buffer = "";
                    self.read_start_tripped = false;
                    const index = self.listeners.indexOf(this);
                    if (index > -1) {
                        array.splice(index, 1);
                    }
                    resolve(content);
                }
            });
        });
    }
}