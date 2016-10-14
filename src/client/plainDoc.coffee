class PlainDocument
  constructor: (@doc) ->

  createRoot: (xmlString, encryptedParts, callback) ->
    @doc.createRoot(xmlString, callback)
    
  insertElementAt: (XPathToParent, position, XMLString, callback) ->
    @doc.insertElementAt(XPathToParent, position, XMLString, callback)
    
  removeElement: (XPath, callback) ->
    @doc.removeElement(XPath, callback)
    
  moveElement: (XPath, toPosition, callback) ->
    throw 'Not implemented yet'
    
  setElement: (XPathToParent, pos, XMLString, callback) ->
    @doc.setElement(XPathToParent, pos, XMLString, callback)
    
  getReadonlyDecryptedDOM: (callback) ->
    callback(@doc.getReadonlyDOM())
  
  decryptOp: (op, callback) ->
    callback(op)
  
if require?
  module.exports = PlainDocument
else
  window.exports ||= {}
  window.exports.PlainDocument = PlainDocument