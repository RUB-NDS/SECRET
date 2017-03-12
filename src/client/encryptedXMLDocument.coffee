if require?
  Document = require './document'
else
  Document = window.exports.Document

###
An encrypted XML document for use with ShareJSXML
###
class EncryptedXMLDocument extends Document
  constructor: (@doc) ->
    if not window.KMSWrapper?
      console.error 'You have to install the Google Chrome Extension for this to work'
      throw 'You have to install the Google Chrome Extension for this to work'
    @enc = new XMLEncryption(window.KMSWrapper)
    @parser = new window.DOMParser()
    @serializer = new window.XMLSerializer()
    @xpath = new window.sharejs.types.xml.api.TinyXPathProcessor()
    @idMap = {}
  
  _register: ->
    @_listeners = []
    @doc.addListener "/#{@doc.getReadonlyDOM().documentElement.nodeName}", 'desc-or-self op', (p, c) =>
      for {path, event, cb} in @_listeners
        if @doc.type.pathMatches(path, p[...-1])
          switch event
            when 'insert'
              throw 'Not implemented yet'
              #if c.ei != undefined and c.ed == undefined
              #  cb(c.p[c.p.length-1], c.ei)
              #else if c.as != undefined and c.ad == undefined
              #  cb(c.p[c.p.length-1], c.as)
            when 'delete'
              throw 'Not implemented yet'
              #if c.ei == undefined and c.ed != undefined
              #  cb(c.p[c.p.length-1], c.ed)
              #else if c.as == undefined and c.ad != undefined
              #  cb(c.p[c.p.length-1], c.ad)
            when 'replace'
              throw 'Not implemented yet'
              #if c.ei != undefined and c.ed != undefined
              #  cb(c.p[c.p.length-1], c.ed, c.ei)
            when 'move'
              throw 'Not implemented yet'
              #if c.em != undefined
              #  cb(c.p[c.p.length-1], c.em)
            when 'textInsert'
              if c.ti != undefined
                cb(c.p[c.p.length-1], c.ti)
            when 'textDelete'
              if c.td != undefined
                cb(c.p[c.p.length-1], c.td)
        if event == 'desc-or-self op' and @_isDescOrSelf(path, c.p)
          child_path = c.p[path.length..]
          cb(child_path, c)
      return
    
  _isDescOrSelf: (ancestorPath, descendantPath) ->
    return true if ancestorPath.length == 0
    return false if descendantPath.length == 0
    return false if ancestorPath.length > descendantPath.length
    
    for p, i in descendantPath
      if i >= ancestorPath.length
        return true
      if p != ancestorPath[i]
        return false
    return true
    
  addListener: (elem, event, cb) ->
    encDOM = @doc.getReadonlyDOM()
    partId = elem.getAttribute('id')
    if partId of @idMap
      tinyXPath = "/document#{@_getXPath(elem, 0).replace('div','encryptedpart')}"
    else
      tinyXPath = "/document#{@_getXPath(elem, 0).replace('div','part')}"
    [steps, attributeName] = @xpath.checkTinyXPath(encDOM, tinyXPath)
    [path, elem] = @xpath.traverseXMLTree(encDOM, steps)
    l = {path, event, cb}
    @_listeners.push l
    return l
  
  removeListener: (l) ->
    i = @_listeners.indexOf l
    return false if i < 0
    @_listeners.splice i, 1
    return true
  
  createRoot: (xmlString, encryptedParts = [], callback) ->
    dom = @parser.parseFromString(xmlString, @doc.type.docType)
    @encryptedParts = encryptedParts
    encryptPart = (partNum, callback) =>
      if partNum < 0
        @doc.createRoot(@serializer.serializeToString(dom))
        @_register() if not @_listeners?
        return callback()
      newDataID = @enc.getRandomID()
      encryptedPart = @encryptedParts[partNum]
      encKeys = ''
      @enc.generateNewEncryptedKey newDataID, encryptedPart.groupIDs, (docPartKeysArray) =>
        # generate encrypted key elements
        keyIDs = []
        for docPartKey in docPartKeysArray
          [cipher, gid] = docPartKey
          if encryptedPart.groupIDs.indexOf(gid) == -1 # we did not ask for this one
            continue # should not be necessary in the final version
          newKeyID = @enc.getRandomID()
          encKeys += @enc.createEncryptedKey(newKeyID, cipher, [], "#{newDataID}-#{gid}")
          keyIDs.push(newKeyID)
        #generate encrypted data element
        [path, elem] = @xpath.traverseXMLTree(dom, encryptedPart.xpath)
        pos = path[path.length - 1]
        if not elem.getAttribute('id')?
          elem.setAttribute('id', newDataID)
        @idMap[elem.getAttribute('id')] = newDataID
        xml = "<encrypted#{elem.nodeName} id='#{elem.getAttribute('id')}'>"
        spans = @xpath.getChildrenByNodeName(elem, "span").reverse()
        encryptSpan = (spanNum, callback) =>
          if spanNum < 0
            xml += encKeys + "</encrypted#{elem.nodeName}>"
            return callback(xml)
          span = spans[spanNum]
          @enc.encrypt {keyName: newDataID, keyIDs: keyIDs, plaintext: @serializer.serializeToString(span), callback: (encryptedData) =>
            xml += encryptedData
            encryptSpan(--spanNum, callback)
          }
        encryptSpan spans.length - 1, (xml) =>
          newElem = @doc.type.api._extractPayload(@parser.parseFromString(xml, @doc.type.docType).documentElement)
          elem.parentNode.replaceChild(newElem, elem.parentNode.childNodes[pos])
          encryptPart(--partNum, callback)
      return
    encryptPart(@encryptedParts.length - 1, callback)
    
  insertElementAt: (parent, pos, XMLString, callback)  ->
    encDOM = @doc.getReadonlyDOM()
    partID = parent.getAttribute('id')
    if partID not of @idMap
      @doc.insertElementAt("/document#{@_getXPath(parent, 0).replace('div','part')}", pos + 1, XMLString, callback)
    else
      part = encDOM.getElementById(partID)
      encData = part.firstChild
      while encData?.nodeName != "#{@enc.xenc_prefix}:EncryptedData"
        encData = encData.nextSibling
      if not encData?
        throw 'Something terrible happened'
      copy = encData.cloneNode(true)
      copy.setAttribute('id', @enc.getRandomID())
      @enc.update copy, XMLString, (cipherValue, newCiphertext) =>
        cipherValue.textContent = newCiphertext
        @doc.insertElementAt(@_getTinyXPath(part), pos + 1, copy.outerHTML, callback)
    
  removeElement: (parent, elem, callback) ->
    encDOM = @doc.getReadonlyDOM()
    increase = elem.previousExistingSibling isnt null
    sibling = elem.previousExistingSibling or elem.nextExistingSibling
    array = @_getXPathArray(sibling, 1)
    if parent.getAttribute('id') not of @idMap
      array[0].n = 'part'
      if increase then array[array.length - 1].i++
      @doc.removeElement("/document#{@_getXPathForArray(array, true)}", callback)
    else
      array[0].n = 'encryptedpart'
      array[array.length - 1].n = "#{@enc.xenc_prefix}:EncryptedData"
      if increase then array[array.length - 1].i++
      @doc.removeElement("/document#{@_getXPathForArray(array, false)}", callback)
 
  insertTextAt: (elem, pos, value, callback) ->
    encDOM = @doc.getReadonlyDOM()
    partID = elem.parentNode.getAttribute('id')
    if partID not of @idMap
      @doc.insertTextAt("/document#{@_getXPath(elem, 1).replace('div','part')}/text()", pos, value, callback)
    else
      spanNum = Array.prototype.indexOf.call(elem.parentNode.childNodes, elem)
      encData = @xpath.getChildrenByNodeName(encDOM.getElementById(partID), "#{@enc.xenc_prefix}:EncryptedData")[spanNum]
      @getReadonlyDecryptedDOM (decDOM) =>
        plainSpan = @xpath.getChildrenByNodeName(decDOM.getElementById(partID), 'span')[spanNum]
        plainSpan.textContent = plainSpan.textContent[...pos] + value + plainSpan.textContent[pos..]
        @enc.update encData, plainSpan.outerHTML, (cipherValue, newCiphertext) =>
          @doc.replaceTextAt(@_getTinyXPath(cipherValue) + '/text()', 0, newCiphertext, callback)
    
  removeTextAt: (elem, pos, length, callback) ->
    encDOM = @doc.getReadonlyDOM()
    partID = elem.parentNode.getAttribute('id')
    if partID not of @idMap
      @doc.removeTextAt("/document#{@_getXPath(elem, 1).replace('div','part')}/text()", pos, length, callback)
    else
      spanNum = Array.prototype.indexOf.call(elem.parentNode.childNodes, elem)
      encData = @xpath.getChildrenByNodeName(encDOM.getElementById(partID), "#{@enc.xenc_prefix}:EncryptedData")[spanNum]
      @getReadonlyDecryptedDOM (decDOM) =>
        plainSpan = @xpath.getChildrenByNodeName(decDOM.getElementById(partID), 'span')[spanNum]
        plainSpan.textContent = plainSpan.textContent[...pos] + plainSpan.textContent[pos + length..]
        @enc.update encData, plainSpan.outerHTML, (cipherValue, newCiphertext) =>
          @doc.replaceTextAt(@_getTinyXPath(cipherValue) + '/text()', 0, newCiphertext, callback)
  
  replaceElement: (XPath, XMLString, callback)  ->
    throw 'Not implemented yet'
    
  moveElement: (XPath, toPosition, callback) ->
    throw 'Not implemented yet'
  
  # In reality, this function provides a cloned DOM, that may be altered.
  # However, the modifications are not reflected back into the encrypted DOM.
  # And to be consistent with the superclass, it is called read-only
  getReadonlyDecryptedDOM: (callback) ->
    encryptedDOM = @doc.getReadonlyDOM()
    newDoc = document.implementation.createDocument('','') # this is not HTML-safe, omitted for now
    copy = encryptedDOM.documentElement.cloneNode(true)
    newDoc.appendChild(newDoc.importNode(copy,true))
    newDocumentElement = newDoc.documentElement
    idMap = {}
    remainingDecryptions = []
    for child in newDocumentElement.childNodes
      encDatasForChild = @xpath.getChildrenByNodeName(child, "#{@enc.xenc_prefix}:EncryptedData")
      if encDatasForChild.length == 0
        continue
      idMap[child.getAttribute('id')] = newDoc.createElement(child.tagName.toLowerCase().replace('encrypted',''))
      remainingDecryptions = remainingDecryptions.concat(encDatasForChild)
    decryptSpan = (spanNum, callback) =>    
      if spanNum < 0
        @_register() if not @_listeners?
        @idMap = idMap
        for child in newDocumentElement.childNodes
          if child.nodeName != '#text' and child.getAttribute('id') of idMap
            childId = child.getAttribute('id')
            newDocumentElement.replaceChild(idMap[childId], child)
            idMap[childId].setAttribute('id', childId)
        return callback(newDocumentElement.ownerDocument)
      else
        encData = remainingDecryptions[spanNum]
        @enc.decrypt encData, (encData, plainChildString) =>
          plainChild = @doc.type.api._extractPayload(@parser.parseFromString(plainChildString, @doc.type.docType).documentElement)
          idMap[encData.parentNode.getAttribute('id')].appendChild(plainChild)
          decryptSpan(--spanNum, callback)
    remainingDecryptions = remainingDecryptions.reverse()
    decryptSpan(remainingDecryptions.length - 1, callback)
  
  _isWithinEncryptedPart: (encDOM, XPathInDecDOM) ->
    try 
      [path, elem] = @xpath.traverseXMLTree(encDOM, XPathInDecDOM)
      return false
    catch error
      return true
  
  _getXPathArray: (node, maxParents = -2) ->
    xPathArray = []
    owner = node.ownerDocument
    maxParents++
    until node == owner
      tmp = node.previousSibling
      i = 1
      while tmp?
        if tmp.nodeName == node.nodeName
          i++
        tmp = tmp.previousSibling
      xPathArray.unshift({n:"#{if node.nodeName != '#text' then node.tagName.toLowerCase() else 'text()'}", i:i, id:node.getAttribute('id')})
      node = node.parentNode
      maxParents--
      if maxParents == 0
        node = owner
    return xPathArray
    
  _getXPath: (node, maxParents = -2) ->
    return @_getXPathForArray(@_getXPathArray(node, maxParents), true)
    
  _getTinyXPath: (node, maxParents = -2) ->
    return @_getXPathForArray(@_getXPathArray(node, maxParents), false)
    
  _getXPathForArray: (array, withIDs) ->
    s = ''
    for entry in array
      if withIDs and entry.id?
        s += '/' + entry.n + '[@id=' + entry.id + ']'
      else
        s += '/' + entry.n + '[' + entry.i + ']'
    return s
  
if require?
  module.exports = EncryptedXMLDocument
else
  window.exports ||= {}
  window.exports.EncryptedXMLDocument = EncryptedXMLDocument