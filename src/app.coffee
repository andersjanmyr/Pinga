require.paths.unshift('./node_modules')

request = require 'request'
express = require 'express'
email = require 'mailer'

app = express.createServer()

URLS = [
  'http://equilo.se',
  'http://halsansrum.herokuapp.com',
  'http://hjarups-yoga.herokuapp.com',
  'http://pinga.herokuapp.com',
  'https://agenda-riksdagen.heroku.com/admins/sign_in']

PINGS = []


app.configure -> 
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + '/public')



app.get '/', (request, response) ->
  response.send PINGS

port = process.env.PORT or process.env.VMC_APP_PORT or 4000 
console.log "Starting on port #{port}"
app.listen(port)

timestamp = ->
  d = new Date
  date = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
  time = "#{d.getHours()}:#{d.getMinutes()}:#{d.getSeconds()}"
  "#{date} #{time}"

pingHost = (url) ->
  console.log "Making request to #{url}"
  request url, (error, response, body) ->
    PINGS.pop() while PINGS.length > 100
    PINGS.unshift [url, response.statusCode, timestamp()]
    console.log PINGS

sendEmail = (url, status) ->
  email.send {
      host : 'smtp.sendgrid.net',  
      port : "25",
      ssl: false, 
      domain : process.env['SENDGRID_DOMAIN'],
      to : "anders@janmyr.com",
      from : "pinga@janmyr.com",
      subject : "#{url} failed",
      body: "#{url} failed with status #{status}",
      authentication : "plain",
      username : process.env['SENDGRID_USERNAME'],
      password : process.env['SENDGRID_PASSWORD']
    },
    (err, result) -> 
      console.log(err) if err
    
for url in URLS
  do (url) ->
    pingUrl = -> 
      pingHost url
    setInterval pingUrl, 15 * 60 * 1000
    pingUrl()
    sendEmail('url', 'status')


