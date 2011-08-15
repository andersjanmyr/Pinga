(function() {
  var PINGS, URLS, app, express, http, pingHost, port, url, _fn, _i, _len;
  require.paths.unshift('./node_modules');
  http = require('http');
  express = require('express');
  app = express.createServer();
  URLS = ['equilo.se', 'halsansrum.heroku.com'];
  PINGS = [];
  app.configure(function() {
    app.use(express.bodyParser());
    return app.use(express.methodOverride());
  });
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
  app.get('/', function(request, response) {
    return response.send(PINGS);
  });
  port = process.env.PORT || process.env.VMC_APP_PORT || 4000;
  console.log("Starting on port " + port);
  app.listen(port);
  pingHost = function(url) {
    var client, req;
    console.log("Making request to " + url);
    client = http.createClient(80, url);
    req = client.request('GET', '/', {
      Host: url
    });
    req.end();
    return req.on('response', function(res) {
      console.log(url, res.statusCode);
      if (PINGS.length > 100) {
        PINGS = [];
      }
      PINGS.push("" + url + ": " + res.statusCode);
      return console.log(PINGS);
    });
  };
  _fn = function(url) {
    var pingUrl;
    pingUrl = function() {
      return pingHost(url);
    };
    return setInterval(pingUrl, 15 * 60 * 1000);
  };
  for (_i = 0, _len = URLS.length; _i < _len; _i++) {
    url = URLS[_i];
    _fn(url);
  }
}).call(this);