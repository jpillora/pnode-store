
# In Development

---


# Peer Store

> A peer-to-peer data store using dnode

## Features

* Fast
  * All data is transfered over [dnode](https://github.com/substack/dnode)
  * Achieve about 1.2k replications/sec
* Replicate mutating operations
* Connections automatically recover
  * Status pings and reconnects are controlled by [upnode](https://github.com/substack/upnode)
* Create smart data buckets for control over replication
  * Prefills buckets with peer data
* Implement your own bucket types
  * Default bucket type is a plain object (pure memory)
  * [lru-cache](https://github.com/isaacs/node-lru-cache) bucket type is operational so you may set size and TTL.
  * LevelDB bucket type in progress...
* Express session store built-in

## Installation

`npm install peer-store`

## Usage

Server A at 10.0.2.1:
``` javascript
var PeerStore = require("peer-store");

var store = new PeerStore({
  peers: ['10.0.2.2'];
});

store.set('foo',42);
```

Server B at 10.0.2.2:
``` javascript
var PeerStore = require("peer-store");

var store = new PeerStore({
  peers: ['10.0.2.1'];
});

store.set('bar',7);
```

On both Sever A and B:

``` javascript
store.getAll(function(data) {
  console.log(data); // { foo: 42, bar: 7 } 
});
```

### Express/Conect session store

In addition to the above, do:

``` javascript
app.use(express.session({
  store: store.sessionStore(),
  secret: 'secr3t'
}));
```

Now all your sessions are magically shared

### API

  *Todo...*

### Issues

`dnode` depends on `node-gyp`, so in order to `npm install` on Windows, you'll need to follow the `node-gyp` [Installation](https://github.com/TooTallNate/node-gyp#installation) guide. Unix and Mac requires `python` and `make` so it *should* just work.

Quick windows links:

* Download [Python 2.7.5](http://www.filehippo.com/download_python/download/5e2aee049049d618963004ca9245e80d/)
* Download [Visual C++ Express 2010](http://go.microsoft.com/?linkid=9709949)
* Download [Windows 7 SDK](http://www.microsoft.com/en-us/download/details.aspx?displayLang=en&id=8279) (Windows 7 Only)

### Credits

Most of the work is being done by substack's [dnode](https://github.com/substack/dnode)

