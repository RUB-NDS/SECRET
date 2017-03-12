editorDiv = shareJSXMLDoc = encXMLDoc = null
defaultXML = "<document><part id='e9a'><span>abc</span><span>def</span></part><part id='b7d'><span>xyz</span><span>ijk</span><span>opq</span></part><part id='f7c'><span>123</span></part></document>"

window.sharejs.extendDoc 'attach', (divElem) ->
  shareJSXMLDoc = this
  editorDiv = divElem
  encXMLDoc = new window.exports.EncryptedXMLDocument(shareJSXMLDoc)
  if not shareJSXMLDoc.getText()?
    docExists = encXMLDoc.createRoot(defaultXML)
  else
    docExists = Promise.resolve() # this workaround can be removed once coffee-script supports the await-keyword
  docExists.then ->
    renderDocument(encXMLDoc, editorDiv).then ->
      i = 1
    
renderDocument = (encXMLDoc, editorDiv) ->
  s = ''
  i = 1
  encXMLDoc.getDOM().then (dom) ->
    for child in dom.documentElement.childNodes
      if child.nodeName isnt '#text'
        s += "<h3>Part #{i++} - "
        if child.getAttribute('x-encrypted') is 'true'
          s += 'Encrypted</h3>'
          button = "<a class='button locked'>Decrypt</a>"
        else 
          s += 'Plaintext</h3>'
          button = "<a class='button unlocked'>Encrypt</a>"
        s += "<div id='#{child.getAttribute('id')}' class='editfield' contenteditable='true'>#{child.innerHTML}</div>"
        s += button
    editorDiv.innerHTML = s