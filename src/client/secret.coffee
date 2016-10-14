editorDiv = null
maxCharsPerSpan = 4
timeoutMilliseconds = 1000
defaultXML = "<document><part id='e9a'><span>abc</span><span>def</span></part><part id='b7d'><span>xyz</span><span>ijk</span><span>opq</span></part><part id='f7c'><span>123</span></part></document>"
lastTarget = null

window.sharejs.extendDoc 'setMaxCharsPerSpan', (num) ->
  if parseInt(num, 10) is num
    maxCharsPerSpan = num

window.sharejs.extendDoc 'getMaxCharsPerSpan', () ->
  return maxCharsPerSpan

window.sharejs.extendDoc 'attach_parts', (elem) ->
  shareJSDoc = this
  editorDiv = elem
  doc = new window.exports.EncDocument(shareJSDoc)
  processEditEvent = (event) ->
    onNextTick event, (event) ->
      selection = window.getSelection()
      return if not isEditing(selection)
      target = determineTarget(selection)
      if lastTarget? and lastTarget isnt target
        syncTarget(lastTarget)
      lastTarget = target
      syncTarget(target, selection)
  syncTarget = (target, selection) ->
    if target.cache != target.textContent 
      # IE constantly replaces unix newlines with \r\n. ShareJS docs should only have unix newlines.
      newval = target.textContent.replace(/\r\n/g, '\n')
      # Chrome sometimes inputs NBSP-Entities which should be omitted
      if '&nbsp;' in newval
        debugme = 1
      oldval = target.cache
      target.cache = newval
      commonStart = commonEnd = 0
      commonStart++ while oldval.charAt(commonStart) == newval.charAt(commonStart)
      commonEnd++ while oldval.charAt(oldval.length - 1 - commonEnd) == newval.charAt(newval.length - 1 - commonEnd) and
        commonEnd + commonStart < oldval.length and commonEnd + commonStart < newval.length
      if oldval.length != commonStart + commonEnd
        doc.removeTextAt target, commonStart, oldval.length - commonStart - commonEnd, ->
      if newval.length != commonStart + commonEnd
        if target.textContent.length > maxCharsPerSpan and commonEnd is 0 and not target.nextSibling?
          target.cache = target.textContent = oldval
          newSpan = document.createElement('span')
          newSpan.appendChild(document.createTextNode(newval[commonStart..]))
          target.parentNode.appendChild(newSpan)
          newSpan.cache = newSpan.textContent
          moveCursor(newSpan, selection) if selection?
          doc.insertElementAt target.parentNode, target.parentNode.childNodes.length - 1, newSpan.outerHTML, ->
        else
          doc.insertTextAt target, commonStart, newval[commonStart ... newval.length - commonEnd], ->
    return
  isEditing = (selection) ->
    return false if not selection.anchorNode?
    editableFound = false
    node = selection.anchorNode
    owner = node.ownerDocument
    until node == owner
      if node.getAttribute?('contenteditable') is 'true'
        return true
      node = node.parentNode
    return false
  processMoveFocus = () ->
    selection = window.getSelection()
    if not isEditing(selection) 
      if lastTarget?
        syncTarget(lastTarget)
    else
      target = determineTarget(selection)
      if lastTarget? and lastTarget isnt target
        syncTarget(lastTarget)
        lastTarget = target
  init = () ->
    doc.getReadonlyDecryptedDOM (dom) ->
      buildParts(dom.documentElement, editorDiv, doc)
      # register for editing events
      for child in editorDiv.childNodes
        if child.nodeName.toLowerCase() is 'div'
          window.setInterval(processEditEvent, timeoutMilliseconds)
          for event in ['textInput', 'keydown', 'keyup', 'select', 'cut', 'paste']
            if child.addEventListener
              child.addEventListener(event, processMoveFocus, false)
            else
              child.attachEvent("on#{event}", processMoveFocus)
          observer = new MutationObserver (mutations) ->
            mutations.forEach (mutation) ->
              Array.prototype.slice.call(mutation.removedNodes).forEach (removedNode) ->
                if removedNode.nodeName.toLowerCase() is 'span' and not removedNode.ignore?
                  removedNode.previousExistingSibling = mutation.previousSibling
                  removedNode.nextExistingSibling = mutation.nextSibling
                  doc.removeElement mutation.target, removedNode, ->
          observer.observe child, { childList: true }
      return
      
  if not shareJSDoc.getText()?
    doc.createRoot(defaultXML, [{"xpath": "/document/part[@id=e9a]", "groupIDs": ['1','2']},{"xpath": "/document/part[@id=b7d]", "groupIDs": ['2']}], init)
  else
    init()

moveCursor = (elem, selection) ->
  range = document.createRange()
  range.setStart(elem.firstChild, elem.textContent.length)
  range.collapse(true)
  selection.removeAllRanges()
  selection.addRange(range)
  
determineTarget = (selection) ->
  anchor = selection.anchorNode
  if anchor.nodeName.toLowerCase() is 'span'
    return anchor
  else if anchor.nodeName.toLowerCase() is '#text'
    target = anchor.parentNode
    if target.nextSibling?.nodeName.toLowerCase() is 'span' and selection.anchorOffset >= anchor.textContent.length and target.nextSibling.cache != target.nextSibling.textContent
      return target.nextSibling # browser moved cursor to previous span
    else
      return target
  else if anchor.nodeName.toLowerCase() is 'span' and anchor.firstChild?.nodeName.toLowerCase() is 'br' and anchor.parentNode.nodeName.toLowerCase() is 'div' and anchor.parentNode.parentNode.nodeName.toLowerCase() is 'div' 
    throw 'Entering new lines is unsupported!'
  else 
    throw 'Unsupported edit!'

buildParts = (domElem, editorDiv, doc) ->
  s = ''
  i = 1
  for child in domElem.childNodes
    if child.nodeName isnt '#text'
      s += "<h3>Part #{i++} - "
      if child.getAttribute('id') is 'e9a' or child.getAttribute('id') is 'b7d'
        s += 'Encrypted</h3>'
      else 
        s += 'Plaintext</h3>'
      s += "<div id='#{child.getAttribute('id')}' style='width: 95%; border: 1px dashed black;' contenteditable='true'>#{child.innerHTML}</div>"
  editorDiv.innerHTML = s
  # build cache
  Array.prototype.slice.call(editorDiv.childNodes).forEach (child) -> # implicitely converts the NodeList to an array
    if child.nodeName.toLowerCase() is 'div'
      div = child
      Array.prototype.slice.call(div.childNodes).forEach (subChild) ->
        if subChild.nodeName.toLowerCase() is 'span'
          subChild.cache = subChild.textContent
      #react on new XML from the server
      doc.addListener div, 'desc-or-self op', (path, op) ->
        doc.getReadonlyDecryptedDOM (dom) ->
          reactOnOp(dom, div, path, op)
  return
  
reactOnOp = (decDom, div, path, op) ->
  editorElem = div
  elem = decDom.getElementById(editorElem.getAttribute('id'))
  for step in path
    elem = elem.childNodes[step]
    editorElem = editorElem.childNodes[step]
    break if elem?.nodeName.toLowerCase() is 'span' # assuming we don't have nested spans
  if op.ti? or op.td?
    if editorElem?.nodeName.toLowerCase() isnt 'span'
      throw 'There is no span element to edit!'
    editorElem.textContent = elem.textContent
    editorElem.cache = editorElem.textContent
  else if op.ei?
    newSpan = document.createElement('span')
    newSpan.ignore = true
    div.appendChild(newSpan)
    newSpan.outerHTML = elem.outerHTML
    div.lastChild.cache = div.lastChild.textContent
  else if op.ed?
    editorElem.ignore = true
    div.removeChild(editorElem)
  else
    throw 'Not implemented yet'
  
# function to constantly check whether the user edited the text
onNextTick = (event, fn) -> setTimeout fn, 0, event # function to re-queue the processing