###
An abstract class that defines what one can do with a document.
All methods are asynchroneus and return Promises.
###
class Document
  createRoot: (xmlString) ->
    throw 'Abstract class, not implemented'
    
  insertElementAt: (XPathToParent, position, XMLString) ->
    throw 'Abstract class, not implemented'
    
  removeElement: (XPath) ->
    throw 'Abstract class, not implemented'
    
  setElement: (XPathToParent, pos, XMLString) ->
    throw 'Abstract class, not implemented'
    
  getDOM: () ->
    throw 'Abstract class, not implemented'
  
if require?
  module.exports = Document
else
  window.exports ||= {}
  window.exports.Document = Document