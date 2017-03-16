package dbDefinition

import (
	"database/sql"
)

type dbEngine interface {
	//Instance() Connector
	Connect() (*sql.DB, error)
	Fetch(object DataObject) (retrievedObject DataObject, err error)
	Close()
//	AllUsers(conn *sql.DB) (users []DataObject)
//	AllRoles(conn *sql.DB) (roles []DataObject)
//	AllRights(conn *sql.DB) (rights []DataObject)
//	AllDocs(conn *sql.DB) (docs []DataObject)
//	AllKeyTypes(conn *sql.DB) (keyTypes []DataObject)
//	AllGroupKeys(conn *sql.DB) (groupKeys []DataObject)
//	AllDocKeys(conn *sql.DB) (docKeys []DataObject)
	UserByUsername(username string) (user User, err error)
	CheckRoleGroupKeyAccess(role Role, keyId uint64) (granted bool, groupKey GroupKey, err error)
	UsersGroupIdsLookup(theUser User) (groupIds []uint64, err error)
}
