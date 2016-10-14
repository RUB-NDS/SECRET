express = require('express')
router = express.Router()

defaultHeaderVars = {
  scripts: ['bcsocket.js', 'webclient/share.js']
  title: 'SECRET - Secure Live Collaboration'
}

renderSECRET = (req, res) ->
  headerVars = Object.assign({}, defaultHeaderVars) # clone
  headerVars.scripts = headerVars.scripts.concat(['webclient/xml.js', 'xmlEnc.js', 'plainDoc.js', 'encDoc.js', 'secret.js'])
  headerVars.externalScripts = ['https://cloud.nds.rub.de:7021/scripts/kmswrapper.js']
  res.render('secret', {
    header: headerVars
    docId : 'encDoc'
  })

# GET home page
router.get '/', renderSECRET

router.get '/secret', renderSECRET

router.get '/secret_plain', (req, res) ->
  headerVars = Object.assign({}, defaultHeaderVars) # clone
  headerVars.scripts = defaultHeaderVars.scripts.concat(['webclient/xml.js', 'viewXML.js'])
  res.render('secret_plain', {
    header: headerVars
    basePage: 'secret'
    docId : 'encDoc'
    docType : 'xml'
  })

module.exports = router;
