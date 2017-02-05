# Package.json file in CoffeeScript
# Nicer to write and you can have comments
# Compile with "cake package"

module.exports =
  name: "SECRET"

  version: "0.1.0"
  description: "A Secure, Efﬁcient, and Collaborative Real-Time Web Editor"
  private: true
  
  scripts:
    build: "cake build"
    test:  "cake test"
    start: "node ./bin/www"
  
  dependencies:
    "body-parser": "~1.0.0"
    "browserchannel": "~1.2.0"
    "coffee-script": "~1"
    "connect": "~2.15.0"
    "cookie-parser": "~1.0.1"
    "debug": "~0.7.4"
    "ejs": "~0.8.5"
    "express": "~4.0.0"
    "morgan": "~1.0.0"
    "mysql": "~2.1.1"
    "serve-favicon": "*"
    "ShareJSXML": ">0.9.16"
    
  devDependencies:
    "uglify-js": "~2.7"
    nodeunit: "*"
    xmldom: "0.1.19"
