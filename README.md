# Peer Store

> A peer-to-peer data store using dnode

## Features

* Replicate all operations
* Auto batches operations to prevent flooding the network
* Create data buckets to separate data
* Implement your own bucket types
  * Default bucket type is an [`lru-cache`](https://github.com/isaacs/node-lru-cache) so you may set size and TTL
* Contains an express session store

## Installation

`npm install peer-store`

## Examples

### Simple store

``` javascript
...

```

This will create a `dnode` TCP server, listening for session data on `7001` and will send session data to `8001` and `9001`


### Express/Conect session store

``` javascript
app.use(express.session({
  store: 
  secret: 'secret'
}));

```

# API

## new PeerStore(`options`)

  Creates a new instance

### `options`

  *Todo...*

# Issues

`dnode` depends on `node-gyp`, so in order to `npm install` on Windows, you'll need to follow the `node-gyp` [Installation](https://github.com/TooTallNate/node-gyp#installation) guide. Unix and Mac requires `python` and `make` so it *should* just work.

Quick windows links:

* Download [Python 2.7.5](http://www.filehippo.com/download_python/download/5e2aee049049d618963004ca9245e80d/)
* Download [Visual C++ Express 2010](http://go.microsoft.com/?linkid=9709949)
* Download [Windows 7 SDK](http://www.microsoft.com/en-us/download/details.aspx?displayLang=en&id=8279) (Windows 7 Only)

## Todo

* Stuff...

## Credits

Most of the work is being done by substack's [dnode](https://github.com/substack/dnode)

