###
Crypto module to receive WebCrypto API function calls via the PostMessage-API
(kind of RPC)
###
class window.CryptoModule
  
  constructor: (@requesterOrigin) ->
    window.addEventListener("message", @evaluateRequest, false);
  
  evaluateRequest: (event) =>
    origin = event.origin || event.originalEvent.origin
    if origin != @requesterOrigin
      console.warn "Got a message from some unknown origin, discarding"
      return
    {id, method, params} = event.data
    try
      window.crypto.subtle[method].apply(window.crypto.subtle, params).then(
        (result) ->
          event.source.postMessage({id: id, method: method, result: result, error: null}, origin)
        (error) ->  
          event.source.postMessage({id: id, method: method, result: null, error: error}, origin)
      )
    catch error
      event.source.postMessage({id: id, method: method, result: null, error: error}, origin)
