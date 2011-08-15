require.paths.unshift('./node_modules')

http = require 'http'
express = require 'express'

app = express.createServer()

URLS = ['equilo.se', 'halsansrum.heroku.com']
PINGS = []

console.log 'Starting on port 4000'

app.configure -> 
  app.use express.bodyParser()
  app.use express.methodOverride()
#  app.use app.router
#  app.use express.static(__dirname + '/public')



app.get '/', (request, response) ->
  response.send PINGS.inspect

app.listen(process.env.VMC_APP_PORT || 4000)

pingHost = (url) ->
  console.log "Making request to #{url}"
  client = http.createClient 80, url
  req = client.request('GET', '/', { Host: url })
  req.end()

  req.on 'response', (res) ->
    console.log url, res.statusCode
    PINGS = [] if PINGS.length > 100
    PINGS.push "#{url}: #{res.statusCode}"
    console.log PINGS

URLS.forEach (url) ->
  pingUrl = ->
    pingHost url
  setInterval pingUrl, 6 * 1000


