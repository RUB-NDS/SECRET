express = require('express')
router = express.Router()

DEBUG = false
suffix = ''
suffix = '.uncompressed' if DEBUG

defaultHeaderVars = {
  scripts: ['bcsocket.js', "webclient/share#{suffix}.js"]
  title: 'SECRET - Secure Live Collaboration'
}

renderSECRET = (req, res) ->
  headerVars = Object.assign({}, defaultHeaderVars) # clone
  headerVars.scripts = headerVars.scripts.concat(["webclient/xml#{suffix}.js", "xmlEnc#{suffix}.js", "plainDoc#{suffix}.js", "encDoc#{suffix}.js", "secret#{suffix}.js"])
  headerVars.externalScripts = ['https://134.147.198.48:7021/scripts/kmswrapper.js']
  res.render('secret', {
    header: headerVars
    docId : 'encDoc'
  })

# GET home page
router.get '/', renderSECRET

router.get '/secret', renderSECRET

router.get '/secret_plain', (req, res) ->
  headerVars = Object.assign({}, defaultHeaderVars) # clone
  headerVars.scripts = defaultHeaderVars.scripts.concat(["webclient/xml#{suffix}.js", "viewXML#{suffix}.js"])
  res.render('secret_plain', {
    header: headerVars
    basePage: 'secret'
    docId : 'encDoc'
    docType : 'xml'
  })

module.exports = router;
