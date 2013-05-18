
var createServer = require('./create-server');

var port = Number(process.argv[2]),
    ports = Number(process.argv[3]);

createServer(port, port+1, [ports]);
