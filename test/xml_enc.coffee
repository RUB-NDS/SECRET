XMLEncryption = require '../src/client/xml_enc'
{DOMParser, XMLSerializer} = require 'xmldom'

util = require 'util'
p = util.debug
i = util.inspect

genUnitTests = () ->
  'IDs':
    'length of IDs': (test) ->
      numberOfTests = 20
      xenc = new XMLEncryption()
      checkLength = (id) ->
        test.strictEqual(id.length, 33)
      checkLength(xenc.getRandomID()) for num in [1..numberOfTests]
      test.expect(numberOfTests)
      test.done()
      
    'IDs must not start with a number': (test) ->
      numberOfTests = 20
      xenc = new XMLEncryption()
      checkFormat = (id) ->
        test.ok(/^[^0-9]$/.test(id[0]))
      checkFormat(xenc.getRandomID()) for num in [1..numberOfTests]
      test.expect(numberOfTests)
      test.done()
      
  'XML correctness':
    'EncryptedData': (test) ->
      xenc = new XMLEncryption()
      str = xenc.createEncryptedData(xenc.getRandomID(), xenc.getRandomID(), ['a','b','c'])
      errorCallback = (level, msg) ->
        test.ok(false, msg); # Should not be called
      parser = new DOMParser({locator:{}, errorHandler: { warning: errorCallback, error:errorCallback, fatalError:errorCallback}})
      test.doesNotThrow -> parser.parseFromString(str, 'text/xml')
      test.done()
    
    'EncryptedKey': (test) ->
      xenc = new XMLEncryption()
      str = xenc.createEncryptedKey(xenc.getRandomID(), xenc.getRandomID(), ['a','b','c'], xenc.getRandomID())
      errorCallback = (level, msg) ->
        test.ok(false, msg); # Should not be called
      parser = new DOMParser({locator:{}, errorHandler: { warning: errorCallback, error:errorCallback, fatalError:errorCallback}})
      test.doesNotThrow -> parser.parseFromString(str, 'text/xml')
      test.done()
      
    'Bad parameters throw errors': (test) ->
      xenc = new XMLEncryption()
      test.throws -> xenc.createEncryptedData('Bla &amp Blubb', xenc.getRandomID(), ['a','b','c'])
      test.throws -> xenc.createEncryptedData(xenc.getRandomID(), 'Bla " Blubb', ['a','b','c'])
      test.throws -> xenc.createEncryptedData(xenc.getRandomID(), xenc.getRandomID(), ['a','\'','c'])
      test.throws -> xenc.createEncryptedData(xenc.getRandomID(), xenc.getRandomID(), ['a','b','c'], 'xxx')
      test.done()
      
exports.unit = genUnitTests()