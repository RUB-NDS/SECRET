var KMSWrapper = (function() {
  'use strict';
  /**
   * This is the Extension's 'unique' ID which may be differ per installation.
   * Make sure this matches the ID displayed in your Chrome browser on the 
   * Extensions page (chrome://extensions)!
   */
  var commPort,
      requests = {};
  
  function arrayify(toArray) {
  'use strict';
  var i = 0,
      arrayed = [];
  while (typeof toArray[i] !== "undefined") {
    arrayed.push(toArray[i]);
    i++;
  }
  return arrayed;
}
  
  function evaluateResponse(obj) {
    'use strict';
    var callback,
        id,
        result,
        method,
        aResponse;
    aResponse = obj.data;
    method = aResponse.method;
    if (method === "encrypt" || method === "decrypt" || method === "importKey"
            || method === "generateKey") {
      if (aResponse.method === "encrypt" || aResponse.method === "decrypt") {
        aResponse.result = new Uint8Array(arrayify(aResponse.result));
      }
      console.info(aResponse);
      id = aResponse.id;
      result = aResponse.result;
      callback = requests[id];
      callback(result);
      delete requests[id];
    } else if (method === "Force") {
      console.log("Connection to keyserver established!");
    } else {
      console.error("We received a message from the dark side, master.");
      console.error(aResponse);
    }
  }
  
  function generateRandomId(length) {
    var id;
    // All credit for the id generation goes to broofa@stackoverflow http://stackoverflow.com/a/2117523
    id = 'xxxxxxxx-NxxT-Dxx1-SxxR-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
      return v.toString(16);
    });
    return Promise.resolve(id);
  }
  
  // commPort = chrome.runtime.connect(EDITOR_EXTENSION_ID);
  //commPort = keyserverFrame;
  // commPort.onMessage.addListener(evaluateResponse);
  window.addEventListener("message", evaluateResponse, false);
  
  return {
    encrypt: function encrypt(algo, keyId, data, callback) {
      generateRandomId().then(function(requestId) {
        requests[requestId] = callback;
        commPort.postMessage({id: requestId, method: "encrypt",
                              algo: algo, keyId: keyId, data: data}, "*");
        });
    },

    decrypt: function decrypt(algo, keyId, data, callback) {
      generateRandomId().then(function(requestId) {
        requests[requestId] = callback;
        commPort.postMessage({id: requestId, method: "decrypt",
                              algo: algo, keyId: keyId, data: data}, "*");
      });
    },

    importKey: function importKey(keyId, encryptedKeys, callback) {
      generateRandomId().then(function(requestId) {
        requests[requestId] = callback;
        commPort.postMessage({id: requestId, method: "importKey",
                              keyId: keyId, encryptedKeys: encryptedKeys}, "*");
      },
      function (err) {
        console.warn(err);
      });
    },

    generateKey: function generateKey(algo, callback) {
      generateRandomId().then(function(requestId) {
        requests[requestId] = callback;
        commPort.postMessage({id: requestId, method: "generateKey",
                              algo: algo}, "*");
      });
    },

    setupCommPort: function setupCommPort(commPortFrame) {
        commPort = commPortFrame;
    }
  };
}());
