# wssocks (`wssocks.sh`)

This plugin allows you to connect to SOCKS5 proxies over networks where it might be restricted via [wssocks](https://github.com/genshen/wssocks) - the entire SOCKS5 protocol transmitted over websockets.

There is a [default (replit-hosted) proxy](https://10cf60a3-1599-4cc6-a7b5-db06769a323e.id.repl.co/status/) available in the plugin, but it is not guaranteed to be fast. Instead, download wssocks and host a proxy yourself for the fastest speeds.

## Hosting your Own

If you're willing to port-forward, just download the [relevant executable](https://github.com/genshen/wssocks/releases/tag/v0.5.0) for your platform and hop into the same directory as the file. Now, run the following, depending on your platform:

```sh
# On Windows
wssocks-windows-amd64.exe server --status
# On Linux
chmod +x wssocks-linux-amd64
./wssocks-linux-amd64
```

If you want to add authentication, too bad. Cope.

Seriously though, that's coming in a future update.
