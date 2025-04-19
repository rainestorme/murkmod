class MurkmodStack {
    constructor(stack_name) {
        this.stack_name = stack_name;
        this.mush_id = null;
        this.listeners = [];
        this.read_tripped = false;
        this.read_buffer = "";
        var self = this;
        tp.openTerminalProcess("crosh", id => {
            self.mush_id = id;
            window.secondary_classes.push(self);
        });
    }

    handle_output(decoded) {
        for (var key in this.listeners) {
            this.listeners[key](decoded);
        }
    }

    push(value) {
        var self = this;
        return new Promise((resolve, reject) => {
            tp.sendInput(self.mush_id, "301\n");
            self.listeners.push(function(decoded){
                if (decoded.includes("stack name?")) {
                    tp.sendInput(self.mush_id, self.stack_name + "\n");
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

    pop() {
        var self = this;
        return new Promise((resolve, reject) => {
            tp.sendInput(self.mush_id, "301\n");
            self.listeners.push(function(decoded){
                if (self.read_start_tripped) {
                    self.read_buffer = self.read_buffer + decoded;
                }
                if (decoded.includes("stack name?")) {
                    tp.sendInput(self.mush_id, self.stack_name+"\n");
                }
                if (decoded.includes("start")) {
                    self.read_tripped = true;
                }
                if (self.read_buffer.includes("end")) {
                    var startIndex = self.read_buffer.indexOf("start") + "start".length;
                    var endIndex = self.read_buffer.indexOf("end");
                    var content = self.read_buffer.substring(startIndex, endIndex);
                    self.read_buffer = "";
                    self.read_tripped = false;
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