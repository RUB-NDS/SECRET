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
    @enc = new EncryptedXML();
  
if require?
  module.exports = EncryptedXMLDocument
else
  window.exports ||= {}
  window.exports.EncryptedXMLDocument = EncryptedXMLDocument