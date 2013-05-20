# P2P Session Store

>> A simple peer-to-peer session store for connect and express

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

Listening for session data on `7001` and will send session data to `8001` and `9001`

# API

## new P2PSessionStore(`options`)

  Creates a new instance

### `options`

  Some options

# Credits

Thanks to substack as most of the work is being done by [dnode](https://github.com/substack/dnode)