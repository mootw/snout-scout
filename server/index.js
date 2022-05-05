 
const http = require('http');


const config = {
    
};



const requestListener = function (req, res) {

    //Cors stuff
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', '*');
    res.setHeader('Access-Control-Allow-Methods', '*');


    res.writeHead(200);
    res.end('Hello, World!');
  }
  
  const server = http.createServer(requestListener);
  server.listen(8080);