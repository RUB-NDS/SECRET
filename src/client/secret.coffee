editorDiv = shareJSXMLDoc = encXMLDoc = null
defaultXML = "<?xml version='1.0'?><document><part id='e9a'><span>abc</span><span>def</span></part><part id='b7d'><span>xyz</span><span>ijk</span><span>opq</span></part><part id='f7c'><span>123</span></part></document>"

window.sharejs.extendDoc 'attach', (divElem) ->
  shareJSXMLDoc = this
  editorDiv = divElem
  encXMLDoc = new window.exports.EncryptedXMLDocument(shareJSXMLDoc)
  if not shareJSXMLDoc.getText()?
    docExists = encXMLDoc.createRoot(defaultXML)
  else
    docExists = Promise.resolve() # this workaround can be removed once coffee-script supports the await-keyword
  docExists.then ->
    renderDocument(encXMLDoc, editorDiv)

renderDocument = (encXMLDoc, editorDiv) ->
  s = ''
  i = 1
  encXMLDoc.getDOM().then (dom) ->
    for child in dom.documentElement.childNodes
      if child.nodeName isnt '#text'
        caption = editorDiv.ownerDocument.createElement('h3')
        caption.textContent = "Part #{i++} - "
        button = editorDiv.ownerDocument.createElement('a')
        button.classList.add('button')
        button.onclick = doEncDecButtonAction
        editField = editorDiv.ownerDocument.createElement('div')
        editField.id = child.getAttribute('id')
        editField.classList.add('editfield')
        editField.setAttribute('contenteditable', 'true')
        for grandchild in child.childNodes
          if grandchild.nodeName is 'span'
            span = editorDiv.ownerDocument.createElement('span')
            span.textContent = grandchild.textContent
            editField.appendChild(span)
        if child.getAttribute('x-encrypted') is 'true'
          caption.textContent += 'Encrypted'
          button.classList.add('locked')
          button.textContent = 'Decrypt'
        else
          caption.textContent += 'Plaintext'
          button.classList.add('unlocked')
          button.textContent = 'Encrypt'
        editorDiv.appendChild(caption)
        editorDiv.appendChild(editField)
        editorDiv.appendChild(button)

doEncDecButtonAction = (event) ->
  button = event.target
  editField = button.previousSibling
  caption = editField.previousSibling
  if button.textContent is 'Encrypt'
    encryptEditField(editField).then ->
      button.className = button.className.replace('unlocked', 'locked')
      button.textContent = 'Decrypt'
      caption.textContent = caption.textContent.replace('Plaintext', 'Encrypted')
  else
    if window.confirm('This action exposes the protected content to the server! Proceed?')
      decryptEditField(editField).then ->
        button.className = button.className.replace('locked', 'unlocked')
        button.textContent = 'Encrypt'
        caption.textContent = caption.textContent.replace('Encrypted', 'Plaintext')
    
encryptEditField = (editField) ->
  encXMLDoc.encryptElement("/document/part[@id='#{editField.id}']")

decryptEditField = (editField) ->
  encXMLDoc.decryptElement("/document/part[@id='#{editField.id}']")