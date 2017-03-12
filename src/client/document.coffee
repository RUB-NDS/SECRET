###
An abstract class that defines what one can do with a document.
All methods are asynchroneus and return Promises.
###
class Document
  createRoot: (xmlString) ->
    abstractError()
    
  insertElementAt: (XPathToParent, position, XMLString) ->
    abstractError()
    
  removeElement: (XPath) ->
    abstractError()
    
  setElement: (XPathToParent, pos, XMLString) ->
    abstractError()
    
  getDOM: () ->
    abstractError()
  
  abstractError: () ->
    Promise.reject('Abstract class, not implemented')
    
if require?
  module.exports = Document
else
  window.exports ||= {}
  window.exports.Document = Document