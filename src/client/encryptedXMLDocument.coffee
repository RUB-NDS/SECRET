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
      throw 'XML Security library not found'
    if not window.webcryptoImpl?
      throw 'WebCryptoProxy not found'
    if not window.xpath?
      throw 'XPath library not found'
    @enc = new EncryptedXML()
    @xpath = window.xpath
    @serializer = new window.XMLSerializer()
    @keyPromise = window.webcryptoImpl.importKey("raw", new Uint8Array(16), {name: "AES-CBC"}, false, ["encrypt", "decrypt"])
    @keyPromise.then (keyObj) =>
      @key = keyObj
  
  getDOM: ->
    return new Promise (resolve, reject) =>
      super.then (readonlyDom) =>
        newDOM = readonlyDom.cloneNode(true)
        @keyPromise.then => # necessary to make sure that the key exists
          try
            @enc.decrypt(newDOM, @key).then resolve
          catch error
            if error.message is "No encData found" # that's perfectly fine
              resolve newDOM
            else
              reject error

  encryptElement: (XPath) ->
    return new Promise (resolve, reject) =>
      references = [new Reference('/d/*[1]')]
      encParams = new window.EncryptionParams
      encParams.setReferences(references)
      encParams.setSymmetricKey(@key)
      @getDOM().then (dom) =>
        nodes = @xpath.select(XPath, dom)
        if nodes.length is 0
          return reject 'XPath selected nothing'
        if nodes.length > 1
          return reject 'XPath selected more than one node'
        node = nodes[0].cloneNode(true)
        node.setAttribute('x-encrypted', 'true')
        newDOM = window.utils.parseXML('<d />')
        newDOM.documentElement.appendChild(node)
        @enc.encrypt(node, encParams.getEncryptionInfo()).then =>
          xPathToParent = XPath.split('/')[...-1].join('/')
          pos = Array.prototype.slice.call(nodes[0].parentElement.childNodes).indexOf(nodes[0]) + 1
          xmlString = @serializer.serializeToString(newDOM.documentElement.childNodes[0])          
          @doc.setElement(xPathToParent, pos, xmlString, resolve)
  
if require?
  module.exports = EncryptedXMLDocument
else
  window.exports ||= {}
  window.exports.EncryptedXMLDocument = EncryptedXMLDocument