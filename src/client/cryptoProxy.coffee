###
Proxy to redirect function calls to the WebCrypto API to a different origin 
using the PostMessage-API (kind of RPC)
###
class window.WebCryptoProxy
  
  constructor: (@commPort, @targetOrigin) ->
    throw "CommPort invalid" if not @commPort.postMessage?
    window.addEventListener("message", @evaluateResponse, false);
    @promises = {}
  
  # we do not need cryptographic randomness here, these IDs only need uniqueness
  generateRandomId: () ->
    rndPool = ''
    rndPool += (Math.random() + 1).toString(36).substring(2) for i in [0..2]
    return Promise.resolve(rndPool[0..31])
  
  # fetch the promise according to the response and fulfill it
  evaluateResponse: (event) =>
    origin = event.origin || event.originalEvent.origin
    if origin != @targetOrigin
      console.warn "Got a message from some unknown origin, discarding"
      return
    {id, result, error} = event.data
    if id of @promises
      if not error?
        @promises[id].resolve(result)
      else
        @promises[id].reject(error)
      delete @promises[id]
    return
   
  # take the function call and redirect it to the commPort 
  __dispatchMessage: (method, params) ->
    @generateRandomId().then (requestId) =>
      @commPort.postMessage({id: requestId, method: method, params: [params...]}, @targetOrigin)
      return new Promise (resolve, reject) =>
        @promises[requestId] = {resolve: resolve, reject: reject}
  
  # digesting does not use keys, no need to redirect these calls
  digest: window.crypto.subtle.digest
  
  # creates a stub for every function of the WebCrypto API (except "digest")
  # it's not very readable, but every created function basically looks like this:
  # encrypt: -> @__dispatchMessage("encrypt", arguments)
  for method in ["encrypt", "decrypt", "sign", "verify", "generateKey", "deriveKey", "deriveBits", "importKey", "exportKey", "wrapKey", "unwrapKey"]
    @::[method] = ((method) -> -> @__dispatchMessage(method, arguments))(method)
