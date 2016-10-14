# SECRET
A Secure, Efﬁcient, and Collaborative Real-Time Web Editor

## How to install
The installation steps have been tested with Ubuntu:

1. Install Node.js and npm:

       `# apt-get install npm`
1. Ubuntu calls node's binary `nodejs`, but `node` is more common:

       `# ln -s /usr/bin/nodejs /usr/bin/node`
1. Install Coffeescript: 

       `# npm install -g coffee-script`
1. Compile package info: 

       `$ cake package`
1. Install [ShareJSXML](https://github.com/RUB-NDS/ShareJSXML): 

       `$ npm install /path/to/ShareJSXML`
1. Install remaining libs: 

       `$ npm install`

       `$ npm update`
1. Compile code: 

       `$ cake build`
1. Link client libs:

       `$ ln -s ../../node_modules/browserchannel/dist/bcsocket.js ./static/javascripts`
       
       `$ ln -s ../../node_modules/ShareJSXML/webclient/ ./static/javascripts`
       
1. Start server (hint: in a `screen` with reduced permissions):
   - For development: `$ DEBUG=SECRET npm start`
   - For production:  `$ NODE_ENV=production npm start`
