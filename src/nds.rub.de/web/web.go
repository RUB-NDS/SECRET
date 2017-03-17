package main

import (
	"net/http"
	"log"
	"nds.rub.de/crypto"
	"fmt"
	"strings"
	"encoding/json"
	"nds.rub.de/extensionApi"
	"github.com/gorilla/sessions"
	"github.com/gorilla/securecookie"
	"strconv"
)

var(
	extApi *extensionApi.ExtensionApi
	store  *sessions.CookieStore
)

const(
	cContentTypeJwkSetJson string = "application/jwk-set+json"
	cContentTypeJwkJson string    = "application/jwk+json"
	cContentTypeJson string       = "application/json"

	cJsonSymmetricKey string   = "oct"

//	cListenAddress = "192.168.56.101"
	cListenAddress = ""
)

type getKeyStruct struct {
	Id    uint64  `json:"id"`
	User  string  `json:"user"`
}

type getKeyStringStruct struct {
	Id    string  `json:"id"`
	User  string  `json:"user"`
}

type getGroupIdsStruct struct {
	Current  []uint64  `json:"current"`
	User     string    `json:"user"`
}

type getGroupIdsRespStruct struct {
	GroupIds   []uint64  `json:"groupids"`
	User       string    `json:"user"`
}

type jsonWebKeySet struct {
	Keys   []symmetricJsonWebKey
}

type symmetricJsonWebKey struct {
	KeyType         string    `json:"kty"`
	KeyId           uint64    `json:"kid,omitempty"`
	KeyBytes        []byte    `json:"k"`
	Use             string    `json:"use,omitempty"`
	Algo            string    `json:"alg,omitempty"`
	KeyOps          []string  `json:"key_ops,omitempty"`
}

type respGetKeyStruct struct {
	DocumentKeyId    uint64
	DocumentKey      []byte
	DocumentKeyIv    []byte
	GroupKey         []byte
}

func init() {
	extApi = new(extensionApi.ExtensionApi)
	store = sessions.NewCookieStore([]byte("Test-auth-secret"), securecookie.GenerateRandomKey(32))
	store.Options = &sessions.Options{
		Path:     "/",
		MaxAge:   3600,	// 1h
		HttpOnly: false,
	}
}

func main() {

	// TODO change to handles and implement ServeHTTP
	http.HandleFunc("/kms", kmsHandler)
	http.HandleFunc("/admin", adminHandler)
	http.HandleFunc("/logon", logOnHandler)
	http.HandleFunc("/check", checkCred)
	http.HandleFunc("/performLogOut", logOut)
	http.HandleFunc("/logout", logOutHandler)
	http.HandleFunc("/img/", func(w http.ResponseWriter, r *http.Request) {
			http.ServeFile(w, r, r.URL.Path[1:])
		})
	http.HandleFunc("/scripts/", func(w http.ResponseWriter, r *http.Request) {
			http.ServeFile(w, r, r.URL.Path[1:])
		})

	go log.Fatal(http.ListenAndServeTLS(cListenAddress+":8080", "cert.pem", "key.pem", nil))
	//go log.Fatal(http.ListenAndServe(cListenAddress+":8080", nil))
	//log.Fatal(http.ListenAndServe(cListenAddress+":80", http.HandlerFunc(redir)))
}

func kmsHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Entered kmsHandler...")
	fmt.Println(r)
	fmt.Println("length:   ", r.ContentLength)
	//w.Header().Set("Access-Control-Allow-Origin", "http://localhost")
	//w.Header().Set("Access-Control-Allow-Credentials", "true")
	//w.Header().Set("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT")
	//w.Header().Set("Access-Control-Allow-Headers", "Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers")
	cntType := r.Header.Get("Content-Type")
	if !strings.EqualFold(cntType, cContentTypeJson) {
		w.Header().Set("Content-Type", "text/plain")
		w.Write([]byte("This is the kms handler!\n"))
	} else {
		fmt.Println("Type:            ", cntType)
		var rcvd []byte = make([]byte, r.ContentLength)
		r.Body.Read(rcvd)
		fmt.Println("Rcvd vals:       ", string(rcvd))
		var keyIdReq getKeyStruct
		var keyIdStringReq getKeyStringStruct
		var unmarshalError, fail error
		var noKeyReq bool
		unmarshalError = json.Unmarshal(rcvd, &keyIdReq)
		if (unmarshalError!=nil || keyIdReq.Id==0) {
			var err error
			fmt.Println("need extra parsing")
			unmarshalError = json.Unmarshal(rcvd, &keyIdStringReq)
			keyIdReq.Id, err = strconv.ParseUint(keyIdStringReq.Id, 10, 64)
			if err != nil {
				fmt.Println(err)
				noKeyReq = true
			}
		}
		fmt.Println(keyIdReq)
		// check session

		var sessionNew, sessionValid bool = true, false
		var session *sessions.Session
		var user, tempId interface{}
		var jsonified []byte
		var groupKeyJson symmetricJsonWebKey
		var getTheGroupIds getGroupIdsStruct
		var usersGroupIds []uint64
		var usersGroupIdsResp getGroupIdsRespStruct
		session, sessionNew, user, tempId = checkSession(r, keyIdReq.User)
		rcvdCookie, err := r.Cookie(keyIdReq.User)
		if err == nil {
			sessionValid = true
		}
		fmt.Println("the received cookie:    ", rcvdCookie)
		if sessionValid && !sessionNew {
			fmt.Println("The session's user:   ", user)
			fmt.Println("The session's tid:    ", tempId)
			session.Save(r, w)
			fmt.Println("session after:    ", session)
			if noKeyReq {
				// try the other thing (get group ids)
				json.Unmarshal(rcvd, &getTheGroupIds)
				usersGroupIds, err = extApi.UsersGroupIds(getTheGroupIds.User)
				if err != nil {
					panic("Could not get the user's Group IDs")
				}
				usersGroupIdsResp.GroupIds = usersGroupIds
				usersGroupIdsResp.User = getTheGroupIds.User
				jsonified, fail = json.MarshalIndent(usersGroupIdsResp, "", "  ")
				w.Header().Set("Content-Type  ", cContentTypeJson)
				// if another error: TBD how to handle such a case (which should not occur assuming untampered extension)
			} else {
				//			access, decGroupKey, encDocKey, docKeyIv, err := extApi.GetKeyById(keyIdReq.Id, keyIdReq.User)
				access, decGroupKey, err := extApi.GetKeyById(keyIdReq.Id, keyIdReq.User)
				if err != nil {
					panic("AAAaaaaaaaaaaaaaaaahh!!")
				}
				if access {
					//				response := respGetKeyStruct{DocumentKey: encDocKey, GroupKey: decGroupKey, DocumentKeyIv: docKeyIv}
					groupKeyJson = symmetricJsonWebKey{KeyType: cJsonSymmetricKey, KeyBytes: decGroupKey, KeyId: keyIdReq.Id}
				}
				//				response.DocumentKeyId = keyIdReq.Id
				fmt.Println("Access granted is   ", access)
				//				fmt.Println("Response:     ", response)
				fmt.Println("Response:     ", groupKeyJson)
				//				jsonified, fail := json.MarshalIndent(response, "", "  ")
				jsonified, fail = json.MarshalIndent(groupKeyJson, "", "  ")
				fmt.Println("Error is   ", fail)
				fmt.Println(string(jsonified))
				//				w.Header().Set("Content-Type  ", cContentTypeJson)
				w.Header().Set("Content-Type  ", cContentTypeJwkJson)
			}
			w.Write(jsonified)
		} else {
			redir(w, r)
		}
	}
	fmt.Println("...left kmsHandler.")
}

func adminHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Entered adminHandler...")
	//w.Header().Set("Access-Control-Allow-Origin", "http://localhost")
	//w.Header().Set("Access-Control-Allow-Credentials", "true")
	//w.Header().Set("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT")
	//w.Header().Set("Access-Control-Allow-Headers", "Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers")
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(
`<html>
  <title>SOAKMS - Administration</title>
  <body>
  <h2>Please use the action to perform.</h2>
    <form action="./usermgmt" method="post">
      <input type="submit" value=" User Management " />
    </form>
    <form action="./rolemgmt" method="post">
      <input type="submit" value=" Role Management " />
    </form>
    <form action="./groupgmt" method="post">
      <input type="submit" value=" Group Management " />
    </form>
    <form action="./docmgmt" method="post">
      <input type="submit" value=" Document Management " />
    </form>
    <br /><br />
    <form action="./performLogOut" method="post">
      <input type="submit" value=" Log out " />
    </form>
  </body>
</html>
`))
	fmt.Println("...left adminHandler.")
}

func checkCred(w http.ResponseWriter, r *http.Request) {
	var authenticated bool = false
	var err error = nil
	fmt.Println("Entered checkCred...")
	//w.Header().Set("Access-Control-Allow-Origin", "http://localhost")
	//w.Header().Set("Access-Control-Allow-Credentials", "true")
	//w.Header().Set("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT")
	//w.Header().Set("Access-Control-Allow-Headers", "Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers")
	err = r.ParseForm()
	if err == nil {
		credentials := crypto.LogonCredentials{r.Form.Get("username"), r.Form.Get("password")}
		authenticated, err = extApi.CheckCredentials(credentials)
		if err != nil {
			authenticated = false
			fmt.Println("Error reason:   ", err)
		}
		if authenticated {
			session, _ := store.Get(r, credentials.Username)
			session.ID = extApi.GenerateSessionId(16)
			fmt.Println("the session id:   ", session.ID)
			session.Values["user"] = credentials.Username
			session.Values["user-tid"] = 42
			session.Save(r, w)
			w.Header().Set("Content-Type", "text/html")
			w.Write([]byte(
`<html>
  <title>Authentication successful</title>
  <body>
    <div>Authentication successful!<br /><br />Please reload the editor page!</div>
    <script src="scripts/kmshandler.js"></script>
  </body>
</html>`))
		}
	}
	if !authenticated {
		w.Header().Set("Content-Type", "text/plain")
		w.Write([]byte("Authentication NOT successful!\n"))
	}
	fmt.Println("...left checkCred.")
}

func logOnHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Entered logOnHandler...")
	//w.Header().Set("Access-Control-Allow-Origin", "http://localhost")
	//w.Header().Set("Access-Control-Allow-Credentials", "true")
	//w.Header().Set("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT")
	//w.Header().Set("Access-Control-Allow-Headers", "Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers")
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(
`<html>
  <title>Authentication</title>
  <body>
    <div>Please use the following credentials:
    <ul>
      <li><i>Username: </i>john.doe</li>
      <li><i>Password: </i>12345</li>
    </ul>
    </div>
    <br/>
    <form action="./check" method="post">
      Username: <input type="text" name="username" autocomplete="on"><br />
      Password: <input type="password" name="password" autocomplete="on"><br />
      <input type="submit" value=" Log on " />
      <br/>
    </form>
    <script src="scripts/kmshandler.js"></script>
  </body>
</html>
`))
	fmt.Println("...left logOnHandler.")
}

func logOutHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Entered logOutHandler...")
	//w.Header().Set("Access-Control-Allow-Origin", "http://localhost")
	//w.Header().Set("Access-Control-Allow-Credentials", "true")
	//w.Header().Set("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT")
	//w.Header().Set("Access-Control-Allow-Headers", "Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers")
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(
`<html>
  <title>SOAKMS - Logout</title>
  <body>
    <form action="./performLogOut" method="post">
      <input type="submit" value=" Log out " />
    </form>
  </body>
</html>
`))
	fmt.Println("...left logOutHandler.")
}

func logOut(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Entered logOut...")
	//w.Header().Set("Access-Control-Allow-Origin", "http://localhost")
	//w.Header().Set("Access-Control-Allow-Credentials", "true")
	//w.Header().Set("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT")
	//w.Header().Set("Access-Control-Allow-Headers", "Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers")
	cookies := r.Cookies()
	var err error
	for _, value := range cookies {
		session, _ := store.Get(r, value.Name)
		session.Options.MaxAge = -1
		err = session.Save(r, w)
		fmt.Printf("Destroying session with ID %s for user %s\n", session.ID, value.Name)
	}
	if err != nil {
		panic(err)
	}
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(
`<html>
  <title>SOAKMS - Logout Confirmed!</title>
  <body>
    Logout successful!
  </body>
</html>
`))
	fmt.Println("...left logOut.")
}

func userManagement(w http.ResponseWriter, r *http.Request) {
	//checkSession(r, )
}

func checkSession(r *http.Request, forUser string) (session *sessions.Session, newSession bool, user, tempId interface {}) {
	session, _ = store.Get(r, forUser)
	fmt.Println("session before:   ", session)
	newSession = session.IsNew
	user = session.Values["user"]
	tempId = session.Values["user-tid"]
	return
}

func redir(w http.ResponseWriter, r *http.Request) {
	fmt.Println(r.RequestURI)
	http.Redirect(w, r, "https://"+cListenAddress+":8765/logon", http.StatusMovedPermanently)
}
