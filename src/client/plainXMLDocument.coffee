if require?
  Document = require './document'
else
  Document = window.exports.Document

###
An unencrypted XML document for use with ShareJSXML
###
class PlainXMLDocument extends Document
  constructor: (@doc) ->

  createRoot: (xmlString) ->
    return new Promise (resolve, reject) =>
      @doc.createRoot(xmlString, resolve)
    
  insertElementAt: (XPathToParent, position, XMLString) ->
    return new Promise (resolve, reject) =>
      @doc.insertElementAt(XPathToParent, position, XMLString, resolve)
    
  removeElement: (XPath) ->
    return new Promise (resolve, reject) =>
      @doc.removeElement(XPath, resolve)
    
  setElement: (XPathToParent, pos, XMLString) ->
    return new Promise (resolve, reject) =>
      @doc.setElement(XPathToParent, pos, XMLString, resolve)
    
  getDOM: () ->
    return Promise.resolve(@doc.getReadonlyDOM())
  
if require?
  module.exports = PlainXMLDocument
else
  window.exports ||= {}
  window.exports.PlainXMLDocument = PlainXMLDocument