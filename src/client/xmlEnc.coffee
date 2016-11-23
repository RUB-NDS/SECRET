class XMLEncryption
  encoding = 'utf-8'
  xenc_prefix: 'xenc'
  ds_prefix: 'ds'
  xenc_ns: "xmlns:#{XMLEncryption::xenc_prefix}='http://www.w3.org/2001/04/xmlenc#'"
  ds_ns: "xmlns:#{XMLEncryption::ds_prefix}='http://www.w3.org/2000/09/xmldsig#'"
  algoName: 'AES-GCM'
  algoKeyLength: 128
  algoBlockSizeBytes: 16
  dataAlgoURI: "http://www.w3.org/2009/xmlenc11#aes#{XMLEncryption::algoKeyLength}-gcm"
  keyAlgoURI: "http://www.w3.org/2001/04/xmlenc#kw-aes128"
  encryptedKeyURI: "http://www.w3.org/2001/04/xmlenc#EncryptedKey"
  types: {element: "http://www.w3.org/2001/04/xmlenc#Element", content: "http://www.w3.org/2001/04/xmlenc#Content"}

  constructor: (@oracle) ->
    if not require? and (not window.crypto? or not window.TextDecoder? or not window.atob?)
      throw 'Please use a newer browser'
    @xpath = new window.sharejs.types.xml.api.TinyXPathProcessor() unless require?
    @decoder = new TextDecoder(encoding) unless require?
    @encoder = new TextEncoder(encoding) unless require?
    @importedKeyIDs = {}

  getRandomID: () ->
    rndPool = ''
    # we do not need cryptographic randomness here, these IDs only need uniqueness
    rndPool += (Math.random() + 1).toString(36).substring(2) for i in [0..2]
    return "_#{rndPool[0..31]}"

  _check: (str) ->
    str = str.toString()
    throw "Ampersand not allowed" if /&/.test(str)
    throw "'<' not allowed" if /</.test(str)
    throw "'>' not allowed" if />/.test(str)
    throw "Single quote (') not allowed" if /'/.test(str)
    throw 'Double quote (") not allowed' if /"/.test(str)

  createEncryptedData: (id, ciphertext, keyIDs, type = 'element') ->
    @_check(param) for param in arguments
    @_check(keyID) for keyID in keyIDs
    if not @types.hasOwnProperty(type)
      throw "Type unknown. Use 'element' or 'content'."
    type = @types[type]
    # Technically, the ID-attribute has to be uppercase ("Id"), but then document.getElementById() is not usable. I'm relxing the standard here ;)
#    result = "<#{@xenc_prefix}:EncryptedData #{@xenc_ns} id='#{id}' Type='#{type}'>"
    result = "<ed id='#{id}'>"
#    result += "<#{@xenc_prefix}:EncryptionMethod Algorithm='#{@dataAlgoURI}'/>"
#    result += "<#{@ds_prefix}:KeyInfo #{@ds_ns}>"
#    result += "<#{@ds_prefix}:RetrievalMethod Type='#{@encryptedKeyURI}' URI='##{keyID}'/>" for keyID in keyIDs
#    result += "<rm URI='##{keyID}'/>" for keyID in keyIDs
#    result += "</#{@ds_prefix}:KeyInfo>"
    result += @_createCipherData(ciphertext)
#    result += "</#{@xenc_prefix}:EncryptedData>"
    result += "</ed>"
    return result

  createEncryptedKey: (id, ciphertext, dataIDs, keyName) ->
    @_check(param) for param in arguments
    @_check(dataID) for dataID in dataIDs
    # Technically, the ID-attribute has to be uppercase ("Id"), but then document.getElementById() is not usable. I'm relxing the standard here ;)
#    result = "<#{@xenc_prefix}:EncryptedKey #{@xenc_ns} id='#{id}'>"
    result = "<ek id='#{id}'>"
#    result += "<#{@xenc_prefix}:EncryptionMethod Algorithm='#{@keyAlgoURI}'/>"
    result += @_createCipherData(ciphertext)
#    result += "<#{@xenc_prefix}:ReferenceList>"
#    result += "<#{@xenc_prefix}:DataReference URI='##{dataID}'/>" for dataID in dataIDs
#    result += "</#{@xenc_prefix}:ReferenceList>"
#    result += "<#{@xenc_prefix}:CarriedKeyName>"
    result += "<ckn>"
    result += keyName
    result += "</ckn>"
#    result += "</#{@xenc_prefix}:CarriedKeyName>"
#    result += "</#{@xenc_prefix}:EncryptedKey>"
    result += "</ek>"
    return result

  _createCipherData: (ciphertext) ->
    @_check(param) for param in arguments
#    result = "<#{@xenc_prefix}:CipherData><#{@xenc_prefix}:CipherValue>"
    result = "<cv>"
    result += ciphertext
    result += "</cv>"
#    result += "</#{@xenc_prefix}:CipherValue></#{@xenc_prefix}:CipherData>"
    return result
  
  generateNewEncryptedKey: (keyName, groupIDs, callback) ->
    # groupIDs is currently not used
    @oracle.generateKey {name: @algoName, length: @algoKeyLength}, (docPartKeysArray) =>
      if not docPartKeysArray? or docPartKeysArray.length == 0
        alert('You\'re not logged on with the extension! Click on the little blue circle with the key in the upper right corner!')
        throw {message: 'You\'re not logged on with the extension'}
      @oracle.importKey keyName, docPartKeysArray, ->
        callback(docPartKeysArray)

  encrypt: (p) ->
    p.dataID ?= @getRandomID()
    p.keyIDs ?= []
    p.options ?= {}
    p.type ?= 'element'
    if not (p.plaintext instanceof Uint8Array)
      p.plaintext = @encoder.encode(p.plaintext)
    ivData = new Uint8Array(@algoBlockSizeBytes)
    window.crypto.getRandomValues(ivData)
    encParams = {name: @algoName, length: @algoKeyLength, iv: ivData}     
    @oracle.encrypt encParams, p.keyName, p.plaintext, (ciphertext) =>
      cipherContent = new Uint8Array(ivData.byteLength + ciphertext.byteLength)
      cipherContent.set(ivData, 0)
      cipherContent.set(ciphertext, ivData.byteLength)
      # http://stackoverflow.com/questions/12710001/#12713326
      cipherContent = btoa(String.fromCharCode.apply(null, cipherContent))
      xml = @createEncryptedData(p.dataID, cipherContent, p.keyIDs, p.type)
      p.callback(xml)
  
  update: (encData, newPlaintext, callback) ->
    @_checkEncryptionMethod(encData)
    @importKeys encData, (result) =>
      if !result
        alert('You\'re not logged on with the extension! Click on the little blue circle with the key in the upper right corner!')
        throw {message: 'You\'re not logged on with the extension'}
      keyName = encData.id
#      cipherDatas = @xpath.getChildrenByNodeName(encData, "#{@xenc_prefix}:CipherData")
#      if cipherDatas.length == 0
#        throw "No <#{@xenc_prefix}:CipherData/> found"
#      if cipherDatas.length != 1
#        throw "More than one <#{@xenc_prefix}:CipherData/> per element is no valid XML Encryption"
#      cipherValues = @xpath.getChildrenByNodeName(cipherDatas[0], "#{@xenc_prefix}:CipherValue")
      cipherValues = @xpath.getChildrenByNodeName(encData, "cv")
      if cipherValues.length == 0
        throw "No <#{@xenc_prefix}:CipherValue/> found"
      if cipherValues.length != 1
        throw "More than one <#{@xenc_prefix}:CipherValue/> per element is no valid XML Encryption"
      cipherValue = cipherValues[0]
      if not (newPlaintext instanceof Uint8Array)
        newPlaintext = @encoder.encode(newPlaintext)
      ivData = new Uint8Array(@algoBlockSizeBytes)
      window.crypto.getRandomValues(ivData)
      encParams = {name: @algoName, length: @algoKeyLength, iv: ivData}
      @oracle.encrypt encParams, keyName, newPlaintext, (newCiphertext) =>
        cipherContent = new Uint8Array(ivData.byteLength + newCiphertext.byteLength)
        cipherContent.set(ivData, 0)
        cipherContent.set(newCiphertext, ivData.byteLength)
        # http://stackoverflow.com/questions/12710001/#12713326
        cipherContent = btoa(String.fromCharCode.apply(null, cipherContent))
        callback(cipherValue, cipherContent)
  
  decrypt: (encData, callback) ->
    @_checkEncryptionMethod(encData)
    @importKeys encData, (result) =>
      if !result
        alert('You\'re not logged on with the extension! Click on the little blue circle with the key in the upper right corner!')
        throw {message: 'You\'re not logged on with the extension'}
      cipherContent = @_extractCipherValue(encData)
      # http://stackoverflow.com/questions/12710001/#12713326
      cipherContent = new Uint8Array atob(cipherContent).split('').map (c) ->
        return c.charCodeAt(0)
      ivData = cipherContent.subarray(0, @algoBlockSizeBytes)
      ciphertext = cipherContent.subarray(@algoBlockSizeBytes)
      encParams = {name: @algoName, length: @algoKeyLength, iv: ivData}
      @oracle.decrypt encParams, encData.id, ciphertext, (plaintext) =>
        callback(encData, @decoder.decode(plaintext))
      
  importKeys: (encData, callback) ->
    return callback({}) if encData.id of @importedKeyIDs
#    keyInfos = @xpath.getChildrenByNodeName(encData, "#{@ds_prefix}:KeyInfo")
#    if keyInfos.length == 0
#      throw "No <#{@ds_prefix}:KeyInfo/> found"
#    if keyInfos.length != 1
#      throw "More than one <#{@ds_prefix}:KeyInfo/> per element is no valid XML Encryption"
#    keyInfo = keyInfos[0]
#    retrievalMethods = @xpath.getChildrenByNodeName(keyInfo, "#{@ds_prefix}:RetrievalMethod")
#    if retrievalMethods.length == 0
#      throw "No <#{@ds_prefix}:RetrievalMethod/> found. All other children of <#{@ds_prefix}:KeyInfo/> are not supported"
#    encKeyIDs = []
#    for retrievalMethod in retrievalMethods
#      if retrievalMethod.attributes["Type"].value != @encryptedKeyURI
#        throw "RetrievalMethod #{retrievalMethod.attributes["Type"].value} not supported"
#      if not retrievalMethod.attributes["URI"]? or retrievalMethod.attributes["URI"].value[0] != '#'
#        throw "No ID-based reference found. External references are not supported"
#      encKeyIDs.push(retrievalMethod.attributes["URI"].value.substring(1))
#    if encKeyIDs.length == 0
#      throw "No references to encrypted keys found"
    encKeyArray = []
    for encKeyID in (encKey.attributes['id'].value for encKey in @xpath.getChildrenByNodeName(encData.parentNode, 'ek'))
      encKey = encData.ownerDocument.getElementById(encKeyID) # works because we use lowercase IDs (see xml_enc.coffee)
      if not encKey?
        console.warn("Dead reference to encrypted key found (#{encKeyID})")
        continue
#      encMethods = @xpath.getChildrenByNodeName(encKey, "#{@xenc_prefix}:EncryptionMethod")
#      if encMethods.length == 0
#        throw "No <#{@xenc_prefix}:EncryptionMethod/> found"
#      if encMethods.length != 1
#        throw "More than one <#{@xenc_prefix}:EncryptionMethod/> per element is no valid XML Encryption"
#      if not encMethods[0].attributes["Algorithm"]? or encMethods[0].attributes["Algorithm"].value != @keyAlgoURI
#        throw "Encryption method #{encMethods[0].attributes["Algorithm"].value} not supported"
#      carriedKeyNames = @xpath.getChildrenByNodeName(encKey, "#{@xenc_prefix}:CarriedKeyName")
      carriedKeyNames = @xpath.getChildrenByNodeName(encKey, "ckn")
      if carriedKeyNames.length == 0
        throw "No <#{@xenc_prefix}:CarriedKeyName/> found"
      if carriedKeyNames.length != 1
        throw "More than one <#{@xenc_prefix}:CarriedKeyName/> per element is no valid XML Encryption"
      [encDataID, groupID] = carriedKeyNames[0].textContent.split('-')
      cipherValue = @_extractCipherValue(encKey)
      encKeyArray.push([cipherValue, groupID])
    @oracle.importKey encData.id, encKeyArray, (result) =>
      @importedKeyIDs[encData.id] = true
      callback(result)
  
  _extractCipherValue: (encType) ->
#    cipherDatas = @xpath.getChildrenByNodeName(encType, "#{@xenc_prefix}:CipherData")
#    if cipherDatas.length == 0
#      throw "No <#{@xenc_prefix}:CipherData/> found"
#    if cipherDatas.length != 1
#      throw "More than one <#{@xenc_prefix}:CipherData/> per element is no valid XML Encryption"
#    cipherValues = @xpath.getChildrenByNodeName(cipherDatas[0], "#{@xenc_prefix}:CipherValue")
    cipherValues = @xpath.getChildrenByNodeName(encType, "cv")
    if cipherValues.length == 0
      throw "No <#{@xenc_prefix}:CipherValue/> found"
    if cipherValues.length != 1
      throw "More than one <#{@xenc_prefix}:CipherValue/> per element is no valid XML Encryption"
    return cipherValues[0].textContent
  
  _checkEncryptionMethod: (encData) ->
#    encMethods = @xpath.getChildrenByNodeName(encData, "#{@xenc_prefix}:EncryptionMethod")
#    if encMethods.length == 0
#      throw "No <#{@xenc_prefix}:EncryptionMethod/> found"
#    if encMethods.length != 1
#      throw "More than one <#{@xenc_prefix}:EncryptionMethod/> per element is no valid XML Encryption"
#    if not encMethods[0].attributes["Algorithm"]? or encMethods[0].attributes["Algorithm"].value != @dataAlgoURI
#      throw "Encryption method #{encMethods[0].attributes["Algorithm"].value} not supported"
    return
    
if require?
  module.exports = XMLEncryption
else
  window.exports ||= {}
  window.exports.XMLEncryption = XMLEncryption
