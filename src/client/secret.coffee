window.sharejs.extendDoc 'attach', (editorDiv) ->
  shareJSDoc = this
  window.webcrypto.importKey("raw", new Uint8Array(16), {name: "AES-CBC"}, false, ["encrypt", "decrypt"]).then (keyObj) ->
    window.webcrypto.encrypt({name: "AES-CBC",iv: new Uint8Array(16)}, keyObj, new Uint8Array(16)).then (ciphertext) ->
      c = new Uint8Array(ciphertext)
      window.webcrypto.decrypt({name: "AES-CBC",iv: new Uint8Array(16)}, keyObj, c).then (plaintext) ->
        i = new Uint8Array(plaintext)
      , (error) ->
        console.error error
    , (error) ->
      console.error error
  