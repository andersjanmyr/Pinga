request = require 'request'
express = require 'express'
jade = require 'jade'
socketio = require 'socket.io'
SendGrid = require('sendgrid').SendGrid

sendgrid = new SendGrid(
  process.env.SENDGRID_USERNAME,
  process.env.SENDGRID_PASSWORD
)

URLS = [
  'http://equilo.se',
  'http://halsansrum.herokuapp.com',
  'http://hjarups-yoga.herokuapp.com',
  'http://pinga.herokuapp.com',
  'http://functional-javascript.heroku.com',
  'https://agenda-riksdagen.heroku.com/admins/sign_in']

PINGS = []

app = express.createServer()

app.configure ->
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static "#{__dirname}/../public"
  app.set('views', "#{__dirname}/../views")
  app.set('view engine', 'jade')
  app.set('view options', { layout: false })

app.get '/', (req, resp) ->
  resp.render 'index'

app.get '/pings', (req, resp) ->
  resp.send PINGS

port = process.env.PORT or process.env.VMC_APP_PORT or 4000

console.log(process.env);
console.log "Starting on port #{port}"
console.log "Serving files from #{__dirname}/../public"
app.listen(port)

timestamp = ->
  d = new Date
  date = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
  time = "#{d.getHours()}:#{d.getMinutes()}:#{d.getSeconds()}"
  "#{date} #{time}"

pingHost = (url) ->
  request url, (err, response, body) ->
    console.log(err) if err
    PINGS.pop() while PINGS.length > 100
    PINGS.unshift [url, response.statusCode, timestamp()]
    if response.statusCode isnt 200
      sendEmail("#{url} failed", "#{url} failed with status #{response.statusCode}")

sendEmail = (subject, body) ->
  sendgrid.send {
      from: 'pinga@janmyr.com',
      to: 'anders@janmyr.com',
      subject: subject,
      text: body
    },
    (success, errors) ->
      console.log(errors) unless success


for url in URLS
  do (url) ->
    pingUrl = ->
      pingHost url
    setInterval pingUrl, 15 * 60 * 1000
    pingUrl()

sendEmail('Pinga restarted', timestamp())

since = timestamp()

io = socketio.listen(app)

io.sockets.on 'connection', (socket) ->
  socket.emit 'status', {runningSince: since }
  socket.on 'urls:read', (data, callback) ->
    console.log data
    callback null, URLS


