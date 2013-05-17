var udp = require('./out/udp'),
    port = Number(process.argv[2]),
    msg = process.argv[3];

if(port && msg) {
  udp.send("localhost", port, msg);
  console.log("Sent '"+msg+"' to " + port);
}

