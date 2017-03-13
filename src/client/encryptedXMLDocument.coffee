if require?
  PlainXMLDocument = require './plainXMLDocument'
else
  PlainXMLDocument = window.exports.PlainXMLDocument

###
An encrypted XML document for use with ShareJSXML
###
class EncryptedXMLDocument extends PlainXMLDocument
  constructor: (@doc) ->
    super(@doc)
    if not window.EncryptedXML?
      throw 'XML Encryption library not found'
    if not window.webcryptoImpl?
      throw 'WebCryptoProxy not found'
    @enc = new EncryptedXML()
    window.webcryptoImpl.importKey("raw", new Uint8Array(16), {name: "AES-CBC"}, false, ["encrypt", "decrypt"]).then (keyObj) =>
      @key = keyObj
    
  encryptElement: (XPath) ->
    return new Promise (resolve, reject) =>
      references = [new Reference(XPath)]
      encParams = new window.EncryptionParams
      encParams.setReferences(references)
      encParams.setSymmetricKey(@key)
      @getDOM().then (dom) =>
        @enc.encrypt(dom, encParams.getEncryptionInfo()).then (cipher) ->
          i = cipher
  
if require?
  module.exports = EncryptedXMLDocument
else
  window.exports ||= {}
  window.exports.EncryptedXMLDocument = EncryptedXMLDocument