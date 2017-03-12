express = require('express')
router = express.Router()

DEBUG = true
suffix = ''
suffix = '.uncompressed' if DEBUG

defaultHeaderVars = {
  scripts: ['bcsocket.js', "webclient/share#{suffix}.js"]
  title: 'SECRET - Secure Live Collaboration'
}

renderSECRET = (req, res) ->
  headerVars = Object.assign({}, defaultHeaderVars) # clone
  headerVars.scripts = defaultHeaderVars.scripts.concat(["webclient/xml#{suffix}.js", "xmlsec-webcrypto.js", "cryptoProxy#{suffix}.js", "secret_v2#{suffix}.js"])
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
