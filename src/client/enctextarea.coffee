magicPlaceholder = '$' # any other char would be ok too, the choice is irrelevant

class ModeOfOperation
  constructor: (key) -> 
    if not window.sjcl
      throw new Error 'You have to include the sjcl libarary for this to work'
    @cipher = new window.sjcl.cipher.aes(key)
  
  # AES uses 128 bit blocks, which always lead to a 24-char Base64 encoded
    # form with "==" at the end. We omit the "==", therefore our blocks a
    # 22-chars long
  getBlocksize: -> 22

  # function to split a string into an array of chunks of size len
  split: (str, len) ->
    for offset in [0...str.length] by len
      str[offset...offset+len]
  
  createFirstBlock: -> throw 'You called an abstract method'
  decrypt: (ciphertext) -> throw 'You called an abstract method'
  decryptFull: (ciphertext) -> throw 'You called an abstract method'
  encrypt: (plaintext) -> throw 'You called an abstract method'

class rECB extends ModeOfOperation
  constructor: (key) -> 
    super(key)
    @masternonce = []
    # first half of first block, to detect if key is correct
    # must not be longer than 64 bit in binary form
    # This is "RealSOASec" after Base64 decoding and truncating to 64 bits
    @magicPattern = [1172743496, -535660096]
  
  # function to create a first block with a fresh masternonce
  createFirstBlock: ->
    @masternonce = window.sjcl.random.randomWords(2); # magicpattern takes 64 bit, the others are the master nonce
    firstCiphertextBlock = @cipher.encrypt(@magicPattern.concat(@masternonce))
    firstCiphertextBlock = window.sjcl.codec.base64.fromBits(firstCiphertextBlock)
    return firstCiphertextBlock[0...-2] # remove "==", see comment above
  
  # function to decrypt a ciphertext-block
  decrypt: (ciphertext) ->
    if ciphertext.length % @getBlocksize() != 0
      throw 'Invalid ciphertext, not a multiple of blocksize'
    return '' if ciphertext is ''
    if @masternonce.length == 0
      throw 'Master-Nonce not set, something in the call-stack is broken'
    plaintext = ''
    for block in @split(ciphertext, @getBlocksize())
      ciphertextBlock = window.sjcl.codec.base64.toBits(block + '==') # add "==", see comment above
      plaintextBlock = @cipher.decrypt(ciphertextBlock)
      noncehalf = plaintextBlock[1] ^ @masternonce[1]
      plaintext += String.fromCharCode(plaintextBlock[3] ^ noncehalf)
    return plaintext

  # function to decrypt an encrypted document
  decryptFull: (ciphertext) ->
    if ciphertext.length % @getBlocksize() != 0
      throw 'Invalid ciphertext, not a multiple of blocksize'
    return '' if ciphertext is ''
    firstBlock = ciphertext[0...@getBlocksize()] + '==' # add "==", see comment above
    firstBlock = window.sjcl.codec.base64.toBits(firstBlock)
    firstBlock = @cipher.decrypt(firstBlock)
    if firstBlock[0] != @magicPattern[0] or firstBlock[1] != @magicPattern[1]
      throw 'Wrong key or invalid ciphertext'
    @masternonce = firstBlock[2...]
    return magicPlaceholder + @decrypt(ciphertext[@getBlocksize()...])

  # function to encrypt a plaintext-char
  encrypt: (plaintext) ->
    if @masternonce.length == 0
      throw 'Master-Nonce not set, something in the call-stack is broken'
    ciphertext = ''
    for char in plaintext
      nonce = window.sjcl.random.randomWords(2); # 64 bit nonce
      plaintextBlock = [nonce[0] ^ @masternonce[0],
                        nonce[1] ^ @masternonce[1],
                        nonce[0] ^ 0x00000000,
                        nonce[1] ^ char.charCodeAt(0)]
      ciphertextBlock = @cipher.encrypt(plaintextBlock)
      ciphertext += window.sjcl.codec.base64.fromBits(ciphertextBlock)[0...-2] # remove "==", see comment above
    return ciphertext

# function to process a local edit
processLocalEdit = (doc, cachedPlaintext, editedPlaintext, cipherObj) ->
  # we have to fake a first character so that ShajreJS does not insert the 
  # user's input before the first ciphertext block
  editedPlaintext = magicPlaceholder + editedPlaintext
  return if cachedPlaintext == editedPlaintext # no change, leave immediately
  
  if cachedPlaintext == '' # starting with a new document
    doc.insert(0, cipherObj.createFirstBlock())
    cachedPlaintext = magicPlaceholder
  
  # Usually, the previous state and the new one will have some common text at
  # the beginning and at the end. We search for these parts and omit them from
  # processing
  commonStart = 1
  while cachedPlaintext.charAt(commonStart) == editedPlaintext.charAt(commonStart)
    commonStart++ 

  commonEnd = 0
  while cachedPlaintext.charAt(cachedPlaintext.length - 1 - commonEnd) == editedPlaintext.charAt(editedPlaintext.length - 1 - commonEnd) and commonEnd + commonStart < cachedPlaintext.length and commonEnd + commonStart < editedPlaintext.length
    commonEnd++ 
    
  # if some text was removed, tell the server to delete the corresponding ciphertext blocks
  if cachedPlaintext.length != commonStart + commonEnd
    doc.del(commonStart * cipherObj.getBlocksize(), (cachedPlaintext.length - commonStart - commonEnd) * cipherObj.getBlocksize())
    
  # if some text was inserted, encrypt it and tell the server to insert the ciphertext blocks
  if editedPlaintext.length != commonStart + commonEnd
    doc.insert(commonStart * cipherObj.getBlocksize(), cipherObj.encrypt(editedPlaintext[commonStart...editedPlaintext.length - commonEnd]))
  
  return editedPlaintext

key = [0x00000000, 0x00000000, 0x00000000, 0x00000000]

# function to attach to an HTML <textarea>
window.sharejs.extendDoc 'attach_encrypted_textarea', (elem) ->
  doc = this
  cipher = new rECB(key)
  localPlaintextCache = cipher.decryptFull(@getText()) # initial decryption
  elem.value = localPlaintextCache[1...] # remove placeholder

  # method to update the text and the selection in the <textarea>
  updateTextArea = (newText, selection) ->
    localPlaintextCache = newText
    scrollTop = elem.scrollTop
    elem.value = newText[1...]
    if elem.scrollTop != scrollTop
      elem.scrollTop = scrollTop
    if window.document.activeElement is elem
      [elem.selectionStart, elem.selectionEnd] = selection

  # react on new ciphertext from the server
  @on 'insert', insert_listener = (pos, insertedCiphertext) ->
    # insert of first block means: new masternonce, so a full decrypt is needed
    if pos == 0
      localPlaintextCache = cipher.decryptFull(@getText())
      elem.value = localPlaintextCache[1...] # remove placeholder
      return
    
    pos /= cipher.getBlocksize()
    # The user might have selected some text in the <textarea>, this prevents
    # messing with the selection by inserting text
    updatedSelection = [
      if pos - 1 <= elem.selectionStart then elem.selectionStart + insertedCiphertext.length / cipher.getBlocksize() else elem.selectionStart
      if pos - 1 <= elem.selectionEnd   then elem.selectionEnd   + insertedCiphertext.length / cipher.getBlocksize() else elem.selectionEnd
    ]
    #for IE8 and Opera that replace \n with \r\n.
    oldText = magicPlaceholder + elem.value.replace(/\r\n/g, '\n')
    updateTextArea(oldText[...pos] + cipher.decrypt(insertedCiphertext) + oldText[pos..], updatedSelection)
  
  # react on deleted ciphertext from the server
  @on 'delete', delete_listener = (pos, deletedCiphertext) ->
    pos /= cipher.getBlocksize()
    # The user might have selected some text in the <textarea>, this prevents
    # messing with the selection by deleting text
    updatedSelection = [
      if pos - 1 <= elem.selectionStart then elem.selectionStart - Math.min(deletedCiphertext.length / cipher.getBlocksize(), elem.selectionStart - pos + 1) else elem.selectionStart
      if pos - 1 <= elem.selectionEnd   then elem.selectionEnd   - Math.min(deletedCiphertext.length / cipher.getBlocksize(), elem.selectionEnd   - pos + 1) else elem.selectionEnd
    ]
    #for IE8 and Opera that replace \n with \r\n.
    oldText = magicPlaceholder + elem.value.replace(/\r\n/g, '\n')
    updateTextArea(oldText[...pos] + oldText[pos + deletedCiphertext.length / cipher.getBlocksize()..], updatedSelection)

  # function to constantly check whether the user edited the text
  processEditEvent = (event) ->
    onNextTick = (fn) -> setTimeout fn, 0 # re-queue the processing
    onNextTick ->
      if elem.value != localPlaintextCache[1...]
        # IE constantly replaces unix newlines with \r\n. ShareJS docs
        # should only have unix newlines.
        localPlaintextCache = processLocalEdit(doc, localPlaintextCache, elem.value.replace(/\r\n/g, '\n'), cipher)

  # register for editing events
  observedEvents = ['textInput', 'keydown', 'keyup', 'select', 'cut', 'paste']
  for event in observedEvents
    if elem.addEventListener
      elem.addEventListener(event, processEditEvent, false)
    else
      elem.attachEvent("on#{event}", processEditEvent)

  # method to detach the <textarea> from the server
  elem.detach_share = =>
    @removeListener 'insert', insert_listener
    @removeListener 'delete', delete_listener

    for event in observedEvents
      if elem.removeEventListener
        elem.removeEventListener(event, processEditEvent, false)
      else
        elem.detachEvent("on#{event}", processEditEvent)