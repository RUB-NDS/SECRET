package dbDefinition

import (
	"encoding/json"
	"os"
	"fmt"
	"strings"
)

var (
	dbEng dbEngine
)

var (
	cHOST     = "127.0.0.1"
//	cHOST     = "192.168.56.102"
	cPORT     = "5432"
	cUSER     = "zaphod"
	cPASSWORD = "beeblebrox"
	cSSL      = "disable"
)

type DbApi struct {}

type Debug struct {
	DebugDbEng pgsqlEngine
}

type ConnectionInfo struct{
	Host      string
	Port      string
	User      string
	Password  string
	SSL       string
}

type configuration struct {
	DatabaseEngine    string
	Connection        ConnectionInfo
}

func init() {
	// read the config file to determine which cryptography engine to use
	file, _ := os.Open("./configuration.json")
	decoder := json.NewDecoder(file)
	config := configuration{}
	err := decoder.Decode(&config)
	if err != nil {
		panic(err)
	}

	switch config.DatabaseEngine {
	case "pgsql", "postgresql", "PGSQL", "postgres" :
		engine := pgsqlEngine{}
		dbEng = engine
	default:
		panic("Unsupported database engine!")
	}

	cHOST = config.Connection.Host
	cPORT = config.Connection.Port
	cSSL  = config.Connection.SSL
	if (!strings.EqualFold(cSSL, "disable")  &&  !strings.EqualFold(cSSL, "enable")) {
		fmt.Println("Could not read SSL mode. Not using SSL.")
		cSSL = "disable"
	}
	cUSER = config.Connection.User
	cPASSWORD = config.Connection.Password

	fmt.Println("Connecting to " + cHOST + ":" + cPORT + " as user '" + cUSER + "', SSL set to " + cSSL + ".")
	dbEng.Connect()
}

func (dbApi DbApi) UserByUsername(username string) (user User, err error) {
	user, err = dbEng.UserByUsername(username)
	return
}

func (dbApi DbApi) GetKeyForUser(keyId uint64, username string) (granted bool, groupKey GroupKey, err error) {
	user, err := dbApi.UserByUsername(username)
	granted, groupKey, err = dbEng.CheckRoleGroupKeyAccess(user.Role, keyId)
	return
}

func (dbApi DbApi) UserActive(user User) (active bool) {
	object, err := connection.UserByUsername(user.UserName)
//	object, err := connection.Fetch(user)
	panicIfError(err)
//	user, err = makeUser(object)
//	panicIfError(err)
	active = object.Active
	return
}

func (dbApi DbApi) UsersGroupIds(username string) (groupIds []uint64, err error) {
	var theUser User
	theUser, err = dbApi.UserByUsername(username)
	if err == nil {
		groupIds, err = dbEng.UsersGroupIdsLookup(theUser)
	}
	return
}

//func (dbApi DbApi) checkUserRight(user User, keyId uint64) (result bool, err error) {
//	return
//}
