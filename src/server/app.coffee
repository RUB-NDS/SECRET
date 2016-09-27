express = require('express')
connect = require('connect')
browserchannel = require('browserchannel')
path = require('path')
logger = require('morgan')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
sharejs = require('./shareJSServer.js')

routes = require('./routes/index')

app = express()

# view engine setup
app.set('views', path.join(__dirname, 'templates'))
app.set('view engine', 'ejs')

app.use(logger('dev'))
app.use(bodyParser.json())
app.use(bodyParser.urlencoded())
app.use(cookieParser())
app.use(express.static(path.join(__dirname, 'static')))
sharejs.attachShareJS(app)

app.use('/', routes)

# catch 404 and forwarding to error handler
app.use (req, res, next) -> 
  err = new Error('Not Found')
  err.status = 404;
  next(err)

# error handlers

# development error handler
# will print stacktrace
if app.get('env') == 'development'
  app.use( (err, req, res, next) ->
    res.status(err.status || 500)
    res.render 'error',
      message: err.message
      error: err
  )

# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next) ->
  res.status(err.status || 500)
  res.render 'error',
    message: err.message
    error:
      status: ''
      stack : ''

module.exports = app;
