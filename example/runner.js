
var createServer = require('./create-server');

var port = Number(process.argv[2]),
    ports = process.argv.slice(3).map(Number);

createServer(port, port+1, ports);