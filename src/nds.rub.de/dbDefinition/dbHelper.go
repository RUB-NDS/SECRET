package dbDefinition

import (
	"database/sql"
	"fmt"
	"strings"
	"errors"
	"strconv"
)

const (
	cSelect string   = "SELECT "
	cFrom string     = " FROM "
	cWhere string    = " WHERE "
	cEndQuery string = ";"
	cId string       = "id"
	cInJoin string   = " INNER JOIN "
	cOn string       = " ON "
)

func AllUsers(conn *sql.DB) (users []User) {
	query := selectQuery(cUserTable, cId, cRoleIdCol, cFirstNameCol, cLastNameCol, cEmailCol, cActiveCol, cUserNameCol, cPasswordCol, cSaltCol)
	fmt.Println("the query: ", query)
	prepared, err := conn.Prepare(query)
	panicIfError(err)

	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	users = make([]User, 0, 0)
	for rows.Next() {
		var id, roleId uint64
		var firstName, lastName, email, username string
		var active bool
		var pass, salt []byte
		err = rows.Scan(&id, &roleId, &firstName, &lastName, &email, &active, &username, &pass, &salt)
		panicIfError(err)

		var user = new (User)
		user.Id = id
		user.Role.Id = roleId
		user.FirstName = firstName
		user.LastName = lastName
		user.Email = email
		user.UserName = username
		user.Active = active
		user.Pass = pass
		user.Salt = salt
		users = append(users, *user)
		fmt.Println("A user:    ", user)
	}
	err = rows.Err()
	panicIfError(err)

	return
}

func AllRoles(conn *sql.DB) (roles []Role) {
	query := selectQuery(cRoleTable, cId, cNameCol)
	fmt.Println("the query: ", query)
	prepared, err := conn.Prepare(query)
	panicIfError(err)

	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	roles = make([]Role, 0, 0)
	for rows.Next() {
		var id uint64
		var name string
		err = rows.Scan(&id, &name)
		panicIfError(err)

		var role = new (Role)
		role.Id = id
		role.Name = name
		roles = append(roles, *role)
		fmt.Println("A role:    ", role)
	}
	err = rows.Err()
	panicIfError(err)

	return
}

func AllRights(conn *sql.DB) (rights []Right) {
	query := selectQuery(cRightTable, cId, cNameCol)
	fmt.Println("the query: ", query)
	prepared, err := conn.Prepare(query)
	panicIfError(err)

	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	rights = make([]Right, 0, 0)
	for rows.Next() {
		var id uint64
		var name string
		err = rows.Scan(&id, &name)
		panicIfError(err)

		var right = new (Right)
		right.Id = id
		right.Name = name
		rights = append(rights, *right)
		fmt.Println("A right:    ", right)
	}
	err = rows.Err()
	panicIfError(err)
	return
}

/*func AllUserPublicKeys(conn *sql.DB) (pubKeys []UserKey) {
	query := selectQuery(cUserKeyTable, cUserIdCol, cKeyTypeIdCol, cPubKeyCol, cKeyIvCol)
	fmt.Println("the query: ", query)
	prepared, err := conn.Prepare(query)
	panicIfError(err)

	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	pubKeys = make([]UserKey, 0, 0)
	for rows.Next() {
		var id, keyTypeId uint64
		var pubKey, keyIv []byte
		err = rows.Scan(&id, &keyTypeId, &pubKey, &keyIv)
		panicIfError(err)

		var userKey = new (UserKey)
		userKey.Id = id
		userKey.KeyType.Id = keyTypeId
		userKey.KeyData = pubKey
		userKey.KeyIv = keyIv
		pubKeys = append(pubKeys, *userKey)
		fmt.Println("A key:    ", userKey)
	}
	err = rows.Err()
	panicIfError(err)
	return
}*/

func AllDocs(conn *sql.DB) (docs []Document) {
	query := selectQuery(cDocumentTable, cId, cUserIdCol)
	fmt.Println("the query: ", query)
	prepared, err := conn.Prepare(query)
	panicIfError(err)

	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	docs = make([]Document, 0, 0)
	for rows.Next() {
		var id, userId uint64
		err = rows.Scan(&id, &userId)
		panicIfError(err)

		var doc = new (Document)
		doc.Id = id
		doc.Owner.Id = userId
		docs = append(docs, *doc)
		fmt.Println("A doc:    ", doc)
	}
	err = rows.Err()
	panicIfError(err)
	return
}

func AllKeyTypes(conn *sql.DB) (keyTypes []KeyType) {
	query := selectQuery(cKeyTypeTable, cId, cNameCol)
	fmt.Println("the query: ", query)
	prepared, err := conn.Prepare(query)
	panicIfError(err)

	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	keyTypes = make([]KeyType, 0, 0)
	for rows.Next() {
		var id uint64
		var name string
		err = rows.Scan(&id, &name)
		panicIfError(err)

		var keyType = new (KeyType)
		keyType.Id = id
		keyType.Name = name
		keyTypes = append(keyTypes, *keyType)
		fmt.Println("A keytype:    ", keyType)
	}
	err = rows.Err()
	panicIfError(err)
	return
}

func AllGroupKeys(conn *sql.DB) (groupKeys []GroupKey) {
	query := selectQuery(cGroupKeyTable, cId, cKeyTypeIdCol, cDocIdCol, cKeyDataCol, cKeyIvCol)
	fmt.Println("the query: ", query)
	prepared, err := conn.Prepare(query)
	panicIfError(err)

	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	groupKeys = make([]GroupKey, 0, 0)
	for rows.Next() {
		var id, keyTypeId, docId uint64
		var keyData, keyIv []byte
		err = rows.Scan(&id, &keyTypeId, &docId, &keyData, &keyIv)
		panicIfError(err)

		var groupKey = new (GroupKey)
		groupKey.Id = id
		groupKey.KeyType.Id = keyTypeId
		groupKey.Document.Id = docId
		groupKey.KeyData = keyData
		groupKey.KeyIv = keyIv
		groupKeys = append(groupKeys, *groupKey)
		fmt.Println("A groupkey:    ", groupKey)
	}
	err = rows.Err()
	panicIfError(err)
	return
}

func AllDocKeys(conn *sql.DB) (docKeys []DocumentKey) {
	query := selectQuery(cDocumentKeyTable, cId, cKeyTypeIdCol, cKeyDataCol, cKeyIvCol)
	fmt.Println("the query: ", query)
	prepared, err := conn.Prepare(query)
	panicIfError(err)

	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	docKeys = make([]DocumentKey, 0, 0)
	for rows.Next() {
		var id, keyTypeId uint64
		var keyData, keyIv []byte
		err = rows.Scan(&id, &keyTypeId, &keyData, &keyIv)
		panicIfError(err)

		var docKey = new (DocumentKey)
		docKey.Id = id
		docKey.KeyType.Id = keyTypeId
		docKey.KeyData = keyData
		docKey.KeyIv = keyIv
		docKeys = append(docKeys, *docKey)
		fmt.Println("A dockey:    ", docKey)
	}
	err = rows.Err()
	panicIfError(err)
	return
}

func selectQuery(tableName string, columns ...string) (query string) {
	query = cSelect
	query += putStrings(columns)
	query += cFrom + tableName + cEndQuery
	return
}

func panicIfError(err error) {
	if err != nil {
		panic(err)
	}
}

func (db pgsqlEngine) UserByUsername(username string) (user User, err error) {
	// make the username case-insensitive
	username = strings.ToLower(username)
	query := usernameSelectQuery(cUserTable, cUserNameCol, username, cId, cRoleIdCol, cActiveCol, cUserNameCol, cPasswordCol, cSaltCol)
	fmt.Println("the query: ", query)
	prepared, err := connection.db.Prepare(query)
	panicIfError(err)

	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	for rows.Next() {
		var id, roleId uint64
		var username string
		var active bool
		var pass, salt []byte
		err = rows.Scan(&id, &roleId, &active, &username, &pass, &salt)
		panicIfError(err)

		user.Id = id
		user.Role.Id = roleId
		user.UserName = username
		user.Active = active
		user.Pass = pass
		user.Salt = salt
		fmt.Println("A user:    ", user)
	}
	err = rows.Err()
	panicIfError(err)

	return
}

func usernameSelectQuery(tableName, cmpCol, cmpValWith string, columns ...string) (query string) {
	query = cSelect
	query += putStrings(columns)
	cmpVal := "='" + cmpValWith + "'"
	query += cFrom + tableName + cWhere + cmpCol + cmpVal + cEndQuery
	return
}

func (db pgsqlEngine) CheckRoleGroupKeyAccess(role Role, keyId uint64) (granted bool, groupKey GroupKey, err error) {
	fmt.Println("dbhelper:    ", keyId)
	query := roleGroupKeyJoinQuery(role, keyId)
	fmt.Println("the query:    ", query)
	prepared, err := connection.db.Prepare(query)
	panicIfError(err)
	rows, err := prepared.Query()
	panicIfError(err)

	defer rows.Close()

	var resultSetSize uint64 = 0
	for rows.Next() {
//		var docKeyId, groupKeyId uint64
//		var docKeyData, docKeyIv, groupKeyData, groupKeyIv []byte
		var groupKeyId uint64
		var groupKeyData, groupKeyIv []byte
//		err = rows.Scan(&docKeyId, &docKeyData, &docKeyIv, &groupKeyId, &groupKeyData, &groupKeyIv)
		err = rows.Scan(&groupKeyId, &groupKeyData, &groupKeyIv)
		panicIfError(err)

//		docKey.Id = docKeyId
//		docKey.KeyData = docKeyData
//		docKey.KeyIv = docKeyIv

		groupKey.Id = groupKeyId
		groupKey.KeyData = groupKeyData
		groupKey.KeyIv = groupKeyIv

		fmt.Println("A group key:      ", groupKey)
//		fmt.Println("A document key:   ", docKey)
		resultSetSize++
	}
	err = rows.Err()
	panicIfError(err)

	if resultSetSize == 0 {
//		docKey = DocumentKey{}
		groupKey = GroupKey{}
		granted = false
		err = errors.New("Access denied!")
	} else {
		granted = true
		err = nil
	}

	return
}

func roleGroupKeyJoinQuery(role Role, keyId uint64) (query string) {
	query = cSelect
//	query += cDocumentKeyTable + "." + cId + ", " + cDocumentKeyTable + "." + cKeyDataCol + ", " + cDocumentKeyTable + "." + cKeyIvCol + ", "
	query += cGroupKeyTable + "." + cId + ", " + cGroupKeyTable + "." + cKeyDataCol + ", " + cGroupKeyTable + "." + cKeyIvCol
//	query += cFrom + cDocumentKeyTable
	query += cFrom + cGroupKeyTable
	query += cInJoin + cRoleGroupTable + cOn + cRoleIdCol + "=" + strconv.FormatUint(role.Id, 10)
//	query += cInJoin + cGroupKeyTable + cOn + cRoleGroupTable + "." + cGroupKeyIdCol + "=" + cGroupKeyTable + "." + cId
//	query += cInJoin + cGroupDocKeyTable + cOn + cGroupDocKeyTable + "." + cGroupKeyIdCol + "=" + cGroupKeyTable + "." + cId
	query += cWhere + cGroupKeyTable + "." + cId + "=" + strconv.FormatUint(keyId, 10)
	query += cEndQuery
	return
}

func (db pgsqlEngine) UsersGroupIdsLookup(theUser User) (groupIds []uint64, err error) {
	var query string
	query  = cSelect
	query += cRoleGroupTable + "." + cGroupKeyIdCol
	query += cFrom + cRoleGroupTable
	query += cWhere + cRoleGroupTable + "." + cRoleIdCol + "=" + strconv.FormatUint(theUser.Role.Id, 10)
	fmt.Println("The query:   ", query)

	prepared, err := connection.db.Prepare(query)
	panicIfError(err)
	rows, err := prepared.Query()
	panicIfError(err)

	groupIds = make([]uint64, 0, 0)
	defer rows.Close()

	for rows.Next() {
		var groupKeyId uint64
		err = rows.Scan(&groupKeyId)
		panicIfError(err)

		fmt.Println("A group key id:      ", groupKeyId)
		groupIds = append(groupIds, groupKeyId)
	}
	err = rows.Err()
	panicIfError(err)

	return
}
