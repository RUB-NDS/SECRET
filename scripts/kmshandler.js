/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

var KMS_ADDRESS = "https://134.147.198.48",
        port = "7021",
        keyPage = "/kms";

var KMSConnector = (function() {
  'use strict';
  /** Additional utilities functions **/
  var Utils = {
    hexDataToByteArray: function hexDataToByteArray(hexData) {
      'use strict';
      if (hexData.length % 2 !== 0) {
        throw new Error("Even number of hex digits required");
      }
      var byteCount = hexData.length / 2,
              byteArray = new Uint8Array(byteCount),
              i;
      for (i = 0; i < byteCount; i = i + 1) {
        byteArray[i] = parseInt(hexData.substr(i * 2, 2), 16);
      }
      return byteArray;
    },
    arrayBufferToHexData: function arrayBufferToHexData(arrayBuffer) {
      'use strict';
      var byteArray = new Uint8Array(arrayBuffer),
              hexData = "",
              next,
              i;
      for (i = 0; i < byteArray.byteLength; i = i + 1) {
        next = byteArray[i].toString(16);
        if (next.length < 2) {
          next = "0" + next;
        }
        hexData += next;
      }
      return hexData;
    },
    stringReverse: function stringReverse(reverse) {
      'use strict';
      var esrever = reverse.split("").reverse().join("");
      return esrever;
    },
    exactStringMatch: function matches(firstString, secondString) {
      'use strict';
      var i,
              firstUndefined = typeof (firstString) === "undefined",
              secondUndefined = typeof (secondString) === "undefinded",
              lengthDiffers = firstString.length !== secondString.length;
//      console.log("First: " + firstUndefined + ", second: " + secondUndefined + ", third: " + lengthDiffers);
      if (firstUndefined || secondUndefined || lengthDiffers) {
//        console.log("The first and second length:  " + firstString.length + ", " + secondString.length);
        return false;
      } else {
        for (i = 0; i < firstString.length; i = i + 1) {
          if (firstString.charCodeAt(i) !== secondString.charCodeAt(i)) {
            return false;
          }
        }
      }
      return true;
    }
  },
  keys = {},
          docKeys = {},
          myGroupIds = [],
          keyUsage = ["encrypt", "decrypt"],
          cryptoSubtle = window.crypto && (window.crypto.subtle || window.crypto.webkitSubtle),
          KEY_FORMAT_JWK = "jwk",
          KEY_FORMAT_RAW = "raw",
          AES_CBC_JSON = {name: "AES-CBC"},
          AES_128_CBC = "A128CBC",
          AES_GCM_JSON = {name: "AES-GCM"},
          AES_128_GCM = "A128GCM",
          AES_KEY_WRAP = "A128KW",
          AES_KEY_WRAP_JSON = {name: "AES-KW"},
          ENCRYPT_DECRYPT_USE = ["encrypt", "decrypt"],
          ENCRYPT_USE = "enc",
          EXTRACTABLE = true,
          NOT_EXTRACTABLE = false,
          ENC_DEC_UN_WRAP_KEY_USAGE = ["encrypt", "decrypt", "wrapKey", "unwrapKey"],
          UN_WRAP_KEY_USAGE = ["wrapKey", "unwrapKey"],
          JWK_KEYTYPE = "kty",
          JWK_KEY_ID = "kid",
          JWK_KEY_BYTES = "k",
          JWK_SYMMETRIC_KEY = "oct",
          JWK_ALG_PROP = "alg",
          JWK_USE_PROP = "use",
          JWK_EXT_PROP = "ext",
          JWK_CONTENT_TYPE = "application/jwk+json",
          JWK_SET_CONTENT_TYPE = "application/jwk-set+json",
          // the following is used for importKey
          ENCRYPTED_KEY_JSON = 0,
          GROUP_ID_INDEX = 1,
          CIPHERTEXT_INDEX = "ciphertext",
          IV_INDEX = "iv",
          GROUP_IDS_CURRENT = "current",
          GROUP_IDS_USER = "user",
          GROUP_IDS_ARRAY = "groupids",
          // TODO: deactivate the debugUser and find a better way of getting the name
          debugUser = "john.doe",
          myUserName = "";

  function fixKeyEncoding(key) {
    return key.replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  }

  /**
   * The (internal) function returns the key with the requested Key ID as a JWK
   * object.
   * 
   * @param {uint64} id - The Key ID
   * @param {String} user - The User for whom to fetch the key
   * @param {Object} localCache - The local key cache to use
   * @returns {Object|JWK} - The requested Key as JWK object
   */
  function getKeyById(id, user, localCache) {
    'use strict';
    var url = "",
            data = {},
            toSend,
            response,
            xhr;
    // check if requested key is already available
//    console.error("ID Type:  " + typeof (localCache[id]));
//    console.error("Length:   " + localCache[id].length);
    if (typeof (localCache[id]) !== "undefined" && localCache[id].length >= 16) {
      console.info("Found key with id " + id + " in local cache. Requesting as JWK.");
      return (jsonify(id, localCache[id]));
    } else {
      // key is not available, so fetch it from KMS
      localCache[id] = [];
      console.info("Key with id " + id + " not found. Requesting from KMS.");
      url = KMS_ADDRESS + ":" + port + keyPage;
      xhr = new XMLHttpRequest();
      xhr.open("POST", url, false);
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.setRequestHeader("Accept", 'application/json');
      data["id"] = id;
      data["user"] = user;
      toSend = JSON.stringify(data);
      // send the request
      xhr.withCredentials = true;
      xhr.send(toSend);
      if (xhr.readyState === 4) {
        response = xhr.responseText;
//        console.log("Response (sync):\n" + response);
        return (parseKey(response, localCache));
      }
    }
  }

  /**
   * Parses (and optionally stores) the supplied string representation of a JSON
   * object. Its intended use is to parse base64-encoded data (e.g., a key) for
   * further use (and caching). The <code>dstArray</code> parameter may be omitted.
   * 
   * @param {string} toParse - the string holding the JSON object
   * @param {string} keyBytesIndex - the index/name to the Key Bytes inside the
   * JSON object
   * @param {string} keyIdIndex - the index/name to the Key ID inside the
   * JSON object (only applicable if <code>dstArray</code> is not omitted)
   * @param {Array} dstArray - the destination array where to store the information <br />
   * Format is <code>dstArray[parsedKey[keyIdIndex]] = keyBytes</code>.<br />
   * <i>May be omitted.</i>
   * 
   * @returns {Array|Object} - the parsed JSON object
   */
  function fromBase64ToByteArray(toParse, keyBytesIndex, keyIdIndex, dstArray) {
    'use strict';
    var aKey,
            keyString,
            keyBytes,
            i;
    aKey = JSON.parse(toParse);
    keyString = window.atob(aKey[keyBytesIndex]);
    keyBytes = new Uint8Array(keyString.length);
//    console.log("Parsed received key: " + toParse[keyBytesIndex]);
    // put key in map for lookups
    for (i = 0; i < keyBytes.length; i = i + 1) {
      keyBytes[i] = keyString.charCodeAt(i);
    }
    if (typeof (dstArray) !== "undefined") {
      dstArray[aKey[keyIdIndex]] = Array.apply([], keyBytes);
    }
    return aKey;
  }

  function parseKey(response, localCache) {
    'use strict';
    var groupKey;
    groupKey = fromBase64ToByteArray(response, JWK_KEY_BYTES, JWK_KEY_ID, localCache);
    return (jsonify(groupKey[JWK_KEY_ID], localCache[groupKey[JWK_KEY_ID]]));
  }

  function jsonify(keyId, keyBytes) {
    'use strict';
    var jsonified = {},
            keyString = "",
            i;
    jsonified[JWK_KEYTYPE] = JWK_SYMMETRIC_KEY;
    jsonified[JWK_KEY_ID] = keyId;
    jsonified[JWK_ALG_PROP] = AES_128_GCM;
//    jsonified[JWK_USE_PROP] = ENCRYPT_USE;
//    jsonified[JWK_EXT_PROP] = EXTRACTABLE;
    for (i = 0; i < keyBytes.length; i = i + 1) {
      keyString += String.fromCharCode(keyBytes[i]);
    }
    jsonified[JWK_KEY_BYTES] = window.btoa(keyString);
//    console.log(JSON.stringify(jsonified));
    return Promise.resolve(jsonified);
  }

  function getMyGroupIds(userName) {
    'use strict';
    var requestData = {},
            xhr,
            url,
            request,
            response,
            parsedResponse;
    requestData[GROUP_IDS_CURRENT] = myGroupIds;
    requestData[GROUP_IDS_USER] = userName;
    url = KMS_ADDRESS + ":" + port + keyPage;
    xhr = new XMLHttpRequest();
    xhr.open("POST", url, false);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader("Accept", 'application/json');
    xhr.withCredentials = true;
    request = JSON.stringify(requestData);
    // send the request
    xhr.send(request);
    if (xhr.readyState === 4) {
      response = xhr.responseText;
//      console.log("Response for Group IDs:  "+response);
      parsedResponse = JSON.parse(response);
      myGroupIds = parsedResponse[GROUP_IDS_ARRAY];
      console.info(userName + "'s Group IDs: " + myGroupIds);
    }
    return myGroupIds;
  }

  function resetCache() {
    console.info("Flushing the cache.");
    keys = {};
    docKeys = {};
    myGroupIds = [];
  }

  function updateUserName(newUserName) {
    'use strict';
    var logMessage = "";
    if (!Utils.exactStringMatch(myUserName, newUserName)) {
      logMessage += "Updating the user name...\n"
              + "Wait a sec. It's not the same user. Let's kill the keys first!\n";
      myUserName = newUserName;
      // reset all cached keys
      resetCache();
      // get the current user's group IDs
      getMyGroupIds(myUserName);
    }
    logMessage += "User name is now " + myUserName;
    console.info(logMessage);
  }

  function resetUserName() {
    console.info("Removing the user name...");
    myUserName = "";
    resetCache();
  }

  /**
   * 
   * @param {type} algo
   * @param {type} generatedKey
   * @param {type} groupId
   * @returns {unresolved}
   */
  function encryptForGroup(algo, generatedKey, groupId) {
    'use strict';
    var destination = [],
            encryptionKey,
            wrappedKey,
            cryptoKey,
            key,
            i,
            keyString;
    // encrypt the generated document part key for the groupId
      keyString = "";
      return Promise.resolve(getKeyById(groupId, myUserName, keys)).then(function(theJsonKey) {
        encryptionKey = theJsonKey;
        // make sure to change the alg property to be AES Key Wrap
        encryptionKey[JWK_ALG_PROP] = AES_KEY_WRAP;
//        console.log("the json key:   "+JSON.stringify(theJsonKey));
        encryptionKey.k = fixKeyEncoding(encryptionKey.k);
        return cryptoSubtle.importKey(KEY_FORMAT_JWK, encryptionKey, algo, EXTRACTABLE, UN_WRAP_KEY_USAGE).then(function(result) {
          console.log("Wrapping Key successfully imported.");
          cryptoKey = result;
          return cryptoSubtle.importKey(KEY_FORMAT_RAW, generatedKey, AES_GCM_JSON, EXTRACTABLE, ENC_DEC_UN_WRAP_KEY_USAGE).then(function(result) {
            key = result;
            return cryptoSubtle.wrapKey(KEY_FORMAT_RAW, key, cryptoKey, algo).then(function(result) {
              wrappedKey = new Uint8Array(result);
              for (i = 0; i < wrappedKey.length; i = i + 1) {
                keyString += String.fromCharCode(wrappedKey[i]);
              }
              destination[ENCRYPTED_KEY_JSON] = btoa(keyString);
              destination[GROUP_ID_INDEX] = groupId.toString();
              console.info("Wrapping performed for Group ID " + groupId + ".");
              return Promise.resolve(destination);
            }, function(err) {
              console.error(err);
              return Promise.resolve(false);
            });
          }, function(err) {
            console.error(err);
            return Promise.resolve(false);
          });
        }, function(err) {
          console.error(err);
          return Promise.resolve(false);
        });
      }, function(err) {
        console.error(err);
        return Promise.resolve(false);
      });
  }

  /* Shamelessly ripped from:
   * https://code.google.com/p/chromium/codesearch#chromium/src/third_party/WebKit/LayoutTests/crypto/resources/common.js
   */
  var Base64URL = {
    stringify: function(a) {
      'use strict';
      var base64string = btoa(String.fromCharCode.apply(0, a));
      return base64string.replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
    },
    parse: function(s) {
      'use strict';
      s = s.replace(/-/g, "+").replace(/_/g, "/").replace(/\s/g, '');
      return new Uint8Array(Array.prototype.map.call(atob(s), function(c) {
        return c.charCodeAt(0)
      }));
    }
  };

  return {
    /**
     * 
     * @param {type} algo
     * @param {type} keyId
     * @param {type} data
     * @returns {unresolved}
     */
    encrypt: function encrypt(algo, keyId, data) {
      'use strict';
      var key,
              encryptionResult,
              keyId;
      return Promise.resolve(getKeyById(keyId, myUserName, docKeys)).then(function(theJsonKey) {
        //console.log("the json key:   "+JSON.stringify(theJsonKey));
        theJsonKey.k = fixKeyEncoding(theJsonKey.k);
        return (cryptoSubtle.importKey(KEY_FORMAT_JWK, theJsonKey, AES_GCM_JSON, true, ENC_DEC_UN_WRAP_KEY_USAGE)).then(function(result) {
          console.log("Key successfully imported.");
          key = result;
          return (cryptoSubtle.encrypt(algo, key, data)).then(function(result) {
            console.log("Encryption performed.");
            encryptionResult = Utils.arrayBufferToHexData(result);
//            console.log("Encryption result:  " + encryptionResult);
            return encryptionResult;
          }, function(err) {
            console.error(err);
          });
        }, function(err) {
          console.error(err);
        });
      }, function(err) {
        console.error(err);
      });
    },
    /**
     * 
     * @param {type} algo
     * @param {type} keyId
     * @param {type} data
     * @returns {unresolved}
     */
    decrypt: function decrypt(algo, keyId, data) {
      'use strict';
      var key,
              decryptionResult;
      return Promise.resolve(getKeyById(keyId, myUserName, docKeys)).then(function(theJsonKey) {
//        console.log("the json key:   "+JSON.stringify(theJsonKey));
        theJsonKey.k = fixKeyEncoding(theJsonKey.k);
        return (cryptoSubtle.importKey(KEY_FORMAT_JWK, theJsonKey, AES_GCM_JSON, true, ENC_DEC_UN_WRAP_KEY_USAGE).then(function(result) {
          console.log("Key successfully imported.");
          key = result;
          return cryptoSubtle.decrypt(algo, key, data).then(function(result) {
            console.log("Decryption performed.");
            decryptionResult = Utils.arrayBufferToHexData(result);
//            console.log("Decryption result:  " + decryptionResult);
            return decryptionResult;
          }, function(err) {
            console.error(err);
          });
        }, function(err) {
          console.error(err);
        }));
      });
    },
    /**
     * Gets all keys (for a user) from the KMS, tries to decrypt the requested
     * Document Part Key (DPK), and stores it in the local Look-Up Table for
     * future use.<br />
     * IMPORTANT:  The algorithm for decryption is currently hard-coded to
     * <i>AES-128-KW</i>!
     * 
     * @param {string} keyId - the DPK ID
     * @param {Array} encryptedKeys - the encrypted DPK as a 2-dimensional array
     * @returns {boolean} true  - user is allowed to use requested key,<br />
     *                    false - otherwise
     */
    importKey: function importKey(keyId, encryptedKeys) {
      // we need to have the groupId beforehand (implicitly done by user log on)
      // iterate over the encryptedKeys array and look for our groupID(s)
      'use strict';
      var i = 0,
              j = 0,
              idFound = false,
              decodedCiphertext,
              algo = {},
              decryptionKey,
              key,
              unwrappedKey,
              exportedKeyData,
              exportedKey;
      while (!idFound && (i < encryptedKeys.length)) {
        for (j = 0; j < myGroupIds.length; j = j + 1) {
          if (encryptedKeys[i][GROUP_ID_INDEX] === myGroupIds[j].toString()) {
            idFound = true;
            break;
          }
        }
        i = i + 1;
      }
      if (idFound) {
        // j holds the index to the groupId that was found first in the array
        // i needs to be decreased by 1 to point to the correct tuple
        i = i - 1;
        // now we need to parse the bas64 encoded encrypted key data
        decodedCiphertext = Base64URL.parse(encryptedKeys[i][ENCRYPTED_KEY_JSON]);
        // prepare the algo parameter (currently hard-coded)
        algo = AES_KEY_WRAP_JSON;
        // decrypt the document part key and save it in the local document part key cache
        return Promise.resolve(getKeyById(myGroupIds[j], myUserName, keys)).then(function(theJsonKey) {
          decryptionKey = theJsonKey;
          // make sure to change the alg property to be AES Key Wrap
          decryptionKey[JWK_ALG_PROP] = AES_KEY_WRAP;
//        console.log("the json key:   "+JSON.stringify(theJsonKey));
          decryptionKey.k = fixKeyEncoding(decryptionKey.k);
          return cryptoSubtle.importKey(KEY_FORMAT_JWK, decryptionKey, algo, EXTRACTABLE, UN_WRAP_KEY_USAGE).then(function(result) {
            console.log("Unwrapping Key successfully imported.");
            key = result;
            return cryptoSubtle.unwrapKey(KEY_FORMAT_RAW, decodedCiphertext, key, algo, AES_GCM_JSON, EXTRACTABLE, ENC_DEC_UN_WRAP_KEY_USAGE).then(function(result) {
              console.info("Unwrapping performed.");
              unwrappedKey = result;
//              console.log("Expected Key:   " + Utils.arrayBufferToHexData(data2Enc));
              return cryptoSubtle.exportKey(KEY_FORMAT_RAW, unwrappedKey).then(function(rawKey) {
                exportedKeyData = rawKey;
                exportedKey = new Uint8Array(exportedKeyData);
                docKeys[keyId] = [];
                docKeys[keyId] = Array.apply([], exportedKey);
//                console.log("Unwrapped Key:  " + Utils.arrayBufferToHexData(docKeys[keyId]));
                return true;
              }, function(err) {
                console.error(err);
                return Promise.resolve(false);
              });
            }, function(err) {
              console.error(err);
              return Promise.resolve(false);
            });
          }, function(err) {
            console.error(err);
            return Promise.resolve(false);
          });
        }, function(err) {
          console.error(err);
          return Promise.resolve(false);
        });
      } else {
        // user is either not allowed to use this key or something else went wrong
        return Promise.resolve(false);
      }

    },
    /**
     * 
     * @param {type} algo
     * @returns {unresolved}
     */
    generateKey: function generateKey(algo) {
      'use strict';
      var generatedKey,
              i,
              promises = [];
      switch (algo.length) {
        case 128:
          generatedKey = new Uint8Array(16);
          break;
        case 256:
          generatedKey = new Uint8Array(32);
          break;
        default:
          console.error("Key length not supported. Only 128 or 256 bit are available.");
          return null;
          break;
      }
      window.crypto.getRandomValues(generatedKey);
      algo = AES_KEY_WRAP_JSON;
      // DEBUG
      //generatedKey = Utils.hexDataToByteArray("00112233445566778899aabbccddeeff");
      console.warn("Key to be wrapped:  " + Utils.arrayBufferToHexData(generatedKey));
      // END
      for (i = 0; i < myGroupIds.length; i = i + 1) {
        promises[i] = encryptForGroup(algo, generatedKey, myGroupIds[i]);
      }
      return Promise.all(promises).then(function(result) {
        return Promise.resolve(result);
      });
    },
    cookieListener: function cookieListener(info) {
//      console.log("User Name before:    " + myUserName);
//      console.log("Entered the cookie listener!");
      var cookieDomain,
              cookieUserName;
      cookieDomain = info.cookie.domain;
//      console.log("Cause:  "+info.cause);
      if (KMS_ADDRESS.indexOf(cookieDomain) > -1) {
        // explicit(ly-set) or overwrite
        if ((info.cause === "overwrite")
                || (!info.removed && (info.cause === "explicit"))) {
          // add/update the user name
          cookieUserName = info.cookie.name;
//          console.log("The cookie user name:    " + cookieUserName);
          updateUserName(cookieUserName);
//          console.log("User Name after:     " + myUserName);
        } else {
          // cause is   NOT overwrite OR explicitly removed OR expired_overwrite
          // OR evicted OR expired -> reset keys and username
          console.info("The cookie's gone.");
          resetUserName();
        }
      }
//      console.log("Left the cookie listener!");
    },
    readUserNameFromCookie: function readUserName(cookieArray) {
      'use strict';
      var cookieUserName,
              cookie;
      // Cookies are sorted by path and creation time (longest, earliest is
      // first). Retrieving only the last cookie should give the freshest (path
      // should be the same for all cookies issued by KMS).
      cookie = cookieArray[cookieArray.length - 1];
      if (typeof (cookie) !== "undefined") {
        cookieUserName = cookie.name;
        console.info("Found a cookie. Nom nom nom...\n"
                + "The cookie's user name:    " + cookieUserName);
        updateUserName(cookieUserName);
      }
    },
    debugHex2ByteArray: function(s) {
      return Utils.hexDataToByteArray(s);
    },
    debugArray2String: function(a) {
      return Utils.arrayBufferToHexData(a);
    },
    updateUserName: function(a) {
      return updateUserName(a);
    }
  };
}());

var ivData = KMSConnector.debugHex2ByteArray("000102030405060708090A0B0C0D0E0F"),
        data2Enc = KMSConnector.debugHex2ByteArray("6bc1bee22e409f96e93d7e117393172a"),
        data2Dec = KMSConnector.debugHex2ByteArray("7649abac8119b246cee98e9b12e9197d8964e0b149c10b7b682e6e39aaeb731c"),
        aesParamsIv = {name: "AES-CBC", length: 128, iv: ivData};

function dummyGetKeyEncryptDecrypt() {
  var buf = new Uint8Array(8),
          aresult;
  KMSConnector.generateKey(aesParamsIv).then(function(result) {
    console.log(result);
  }, function(err) {
    console.error(err);
  });

  KMSConnector.encrypt(aesParamsIv, "2", data2Enc).then(function(ciphertext) {
    console.log("Ciphertext:         " + KMSConnector.debugArray2String(ciphertext));
  }, function(err) {
    console.error(err);
  });

  KMSConnector.importKey("1337", [["H6aLCoEStEeu80vY+1p7gp0+hiNx0s/l", "4"], ["H6aLCoEStEeu80vY+1p7gp0+hiNx0s/l", "3"], ["H6aLCoEStEeu80vY+1p7gp0+hiNx0s/l", "2"]]).then(function(allowed) {
    console.log("Could use the key:  " + allowed);
    KMSConnector.decrypt(aesParamsIv, 1337, data2Dec).then(function(plaintext) {
      console.log("Plaintext:          " + KMSConnector.debugArray2String(plaintext));
    });
  });

}

// The cookie functions are based on:
// http://src.chromium.org/viewvc/chrome/trunk/src/chrome/common/extensions/docs/examples/api/cookies/manager.js?revision=119883
function startCookieListener() {
//  console.log("starting the cookie listener");
  chrome.cookies.onChanged.addListener(KMSConnector.cookieListener);
}
function stopCookieListener() {
  chrome.cookies.onChanged.removeListener(KMSConnector.cookieListener);
}

//chrome.cookies.getAll({url: KMS_ADDRESS}, KMSConnector.readUserNameFromCookie);
//startCookieListener();

//setTimeout(dummyGetKeyEncryptDecrypt, 2500);
//setTimeout(dummyGetKeyEncryptDecrypt, 5020);



//var messagePort = chrome.runtime.connect();
//
//console.info("Registering the event listener.");
//window.addEventListener("message", function(event) {
//    console.error("Content script received: " + event.data.text);
//    messagePort.postMessage("The extension inspected " + event.data.text);
//    // check event.type and event.data
//}, false, true);
//console.info("Done!");
//
//function sendIt() {
//    console.log("Posting message...");
//    window.postMessage({ type: "message",
//                         text: "Hello from the console."}, "*");
//}

//setTimeout(sendIt, 10000);

//chrome.runtime.onMessageExternal.addListener(
//  function(request, sender, sendResponse) {
////    if (sender.url == blacklistedWebsite)
////      return;  // don't allow this web page access
////    if (request.openUrlInEditor)
//      cosole.error("The extension received external:   "+request);
//      sendResponse({success: true});
//  });
//
//chrome.runtime.onMessage.addListener(
//  function(request, sender, sendResponse) {
////    if (sender.url == blacklistedWebsite)
////      return;  // don't allow this web page access
////    if (request.openUrlInEditor)
//      cosole.error("The extension received:   "+request);
//      sendResponse({success: true});
//  });

//setTimeout(function () {
//    console.log('cs sending message');
//    window.postMessage({ type: 'content_script_type',
//                         text: 'Hello from content_script.js!'},
//                       '*' /* targetOrigin: any */ );
//}, 10000);

//KMSConnector.decrypt(aesParamsIv, 1337, data2Dec)
//KMSConnector.encrypt(aesParamsIv, "2", data2Enc)
//KMSConnector.generateKey(aesParamsIv)
//KMSConnector.importKey("1337", [["H6aLCoEStEeu80vY+1p7gp0+hiNx0s/l", "4"], ["H6aLCoEStEeu80vY+1p7gp0+hiNx0s/l", "3"], ["H6aLCoEStEeu80vY+1p7gp0+hiNx0s/l", "2"]])



// from background.js

function arrayify(toArray) {
  var i = 0,
      arrayed = [];
  while (typeof toArray[i] !== "undefined") {
    arrayed.push(toArray[i]);
    i++;
  }
  return arrayed;
}

  function connectListener(obj) {
    var aMessage = obj.data;
    var internalCommPort = top;
            console.info("Received message.");
            console.info(aMessage);
            var callFunction = aMessage.method;
            if (callFunction === "encrypt") {
              aMessage.algo.iv = new Uint8Array(arrayify(aMessage.algo.iv));
              aMessage.data = new Uint8Array(arrayify(aMessage.data));
              myKMSConnector.encrypt(aMessage.algo, aMessage.keyId, aMessage.data).then(function(preResult) {
                var result;
//                console.info(preResult);
                result = myKMSConnector.debugHex2ByteArray(preResult);
//                console.info(result);
                internalCommPort.postMessage({id: aMessage.id, method: "encrypt", result: result}, "*");
              }, function (err) {console.error(err);});
            } else if (callFunction === "decrypt") {
              aMessage.algo.iv = new Uint8Array(arrayify(aMessage.algo.iv));
              aMessage.data = new Uint8Array(arrayify(aMessage.data));
              myKMSConnector.decrypt(aMessage.algo, aMessage.keyId, aMessage.data).then(function(preResult) {
                var result;
//                console.info(preResult);
                result = myKMSConnector.debugHex2ByteArray(preResult);
//                console.info(result);
                internalCommPort.postMessage({id: aMessage.id, method: "decrypt", result: result}, "*");
              }, function (err) {console.error(err);});
            } else if (callFunction === "generateKey") {
              myKMSConnector.generateKey(aMessage.algo).then(function(result) {
                internalCommPort.postMessage({id: aMessage.id, method: "generateKey", result: result}, "*");
              });
            } else if (callFunction === "importKey") {
              myKMSConnector.importKey(aMessage.keyId, aMessage.encryptedKeys).then(function(result) {
                internalCommPort.postMessage({id: aMessage.id, method: "importKey", keyId: aMessage.keyId, result: result}, "*");
              });
            } else {
              internalCommPort.postMessage({result: Error("The requested method is unsupported.")}, "*");
            }
  }

function initializeMe() {
  myKMSConnector = window.KMSConnector;
  // chrome.cookies.getAll({url: window.KMS_ADDRESS}, myKMSConnector.readUserNameFromCookie);
  // startCookieListener();
  // chrome.runtime.onConnectExternal.addListener(connectListener);
  // chrome.runtime.onConnect.addListener(connectListener);
  myKMSConnector.updateUserName("john.doe");
  window.addEventListener("message", connectListener, false);
}

initializeMe();
