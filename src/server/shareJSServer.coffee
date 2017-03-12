class shareJSServer
  attachShareJS : (server) ->
    # import the ShareJS server
    ShareJS = require('sharejsxml').server   

    # create a settings object for our ShareJS server
    ShareJSOpts =
        browserChannel:     # set pluggable transport to BrowserChannel
            cors: "*"
        db: 
            type: "none"    # no persistence, uses in-memory redis-server
        # db:
            # type: "mysql"
            # host: "localhost"
            # user: "sharejs"
            # password: "secure"
            # schema: "sharejs"
            # create_tables_automatically: true
  
    # create a ShareJS server and bind to Connect server
    ShareJS.attach(server, ShareJSOpts);

module.exports = new shareJSServer()
