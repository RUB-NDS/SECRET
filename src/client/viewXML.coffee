window.sharejs.extendDoc 'attach_plainxml_to_textarea', (elem) ->
  doc = this
  elem.value = @getText()
  
  # react on new XML from the server
  @on 'remoteop', listener = (op) ->
    elem.value = @getText()

  # method to detach the <textarea> from the server
  elem.detach_share = =>
    @removeListener 'remoteop', listener