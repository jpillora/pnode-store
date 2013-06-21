# P2P Session Store

> A simple peer-to-peer session store for connect and express

# Installation

`npm install p2p-session-store`

# Usage

In Express:
``` javascript

app.use(express.session({
  store: new P2PSessionStore({
    port: 7001,
    peers: [8001, 9001]
  }),
  secret: 'secret'
}));

```

This will create a `dnode` TCP server, listening for session data on `7001` and will send session data to `8001` and `9001`

# API

## new P2PSessionStore(`options`)

  Creates a new instance

### `options`

  *Todo...*

# Issues

`dnode` depends on `node-gyp`, so in order to `npm install` on Windows, you'll need to follow the `node-gyp` [Installation](https://github.com/TooTallNate/node-gyp#installation) guide. Unix and Mac requires `python` and `make` so it *should* just work.

Quick windows links:

* Download [Python 2.7.5](http://www.filehippo.com/download_python/download/5e2aee049049d618963004ca9245e80d/)
* Download [Visual C++ Express 2010](http://go.microsoft.com/?linkid=9709949)
* Download [Windows 7 SDK](http://www.microsoft.com/en-us/download/details.aspx?displayLang=en&id=8279) (Windows 7 Only)

# Credits

Most of the work is being done by substack's [dnode](https://github.com/substack/dnode)

