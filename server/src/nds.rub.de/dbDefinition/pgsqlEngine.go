package dbDefinition

import (
    "database/sql"
    _ "github.com/bmizerany/pq"
    "fmt"
    "errors"
    "strconv"
    "encoding/hex"
)

const (
    cUserTable string        = "tbl_user"
    //	cUserKeyTable string     = "tbl_userpublickey"
    cDocumentTable string    = "tbl_doc"
    cDocumentKeyTable string = "tbl_dockey"
    cGroupKeyTable string    = "tbl_groupkey"
    cRightTable string       = "tbl_right"
    cRoleTable string        = "tbl_role"
    cKeyTypeTable string     = "tbl_keytype"
    cRoleGroupTable string   = "tbl_rolegroup"
    cGroupDocKeyTable string = "tbl_groupdockey"

    cBeginInsertQuery string = "INSERT INTO "
    cEndInsertQuery string   = ") RETURNING id;"
    cOpenPar string          = " ("
    cValuesPars string       = ") VALUES ("

    cRoleIdCol string     = cRoleTable + "_id"
    cFirstNameCol string  = "firstname"
    cLastNameCol string   = "lastname"
    cEmailCol string      = "email"
    cActiveCol string     = "active"
    cUserNameCol string   = "username"
    cPasswordCol string   = "pass"
    cSaltCol string       = "salt"

    cUserIdCol string    = cUserTable + "_id"
    cKeyTypeIdCol string = cKeyTypeTable + "_id"
    //	cPubKeyCol string    = "publickey"
    cKeyIvCol string     = "keyiv"

    cKeyDataCol string   = "keydata"

    cDocIdCol string   = "tbl_doc_id"

    cNameCol string   = "name"

    cGroupKeyIdCol string   = cGroupKeyTable + "_id"
)

//const (
//    cHOST     = "127.0.0.1"
////	cHOST     = "192.168.56.102"
//    cPORT     = "5432"
//    cUSER     = "zaphod"
//    cPASSWORD = "beeblebrox"
//    cSSL      = "disable"
//)

type pgsqlEngine struct {
    db *sql.DB
    err error
}

var (
    connection pgsqlEngine
)
// var db, err = sql.Open("","")
//func Instance() dbConnector {
//	return *new(dbConnector)
//}

func init() {
    connection.db, connection.err = connection.Connect()
}

func (self pgsqlEngine) Connect() (*sql.DB, error) {
//	self.resultSetUsers = make([]User, 0, 0)
    connection.db, connection.err = sql.Open("postgres", "user=" + cUSER + " password=" + cPASSWORD +" host=" + cHOST + " port=" + cPORT + " sslmode=" + cSSL)
    if connection.err != nil {
        fmt.Println(connection.err)
    }
    connection.err = connection.db.Ping()
    if connection.err != nil {
        // do nothing
    }
    return connection.db, connection.err
}

func (self pgsqlEngine) Close() {
    self.db.Close()
    return
}
func CloseConnection(conn *sql.DB) error {
    return conn.Close()
}

func (self pgsqlEngine) Fetch(object DataObject) (result DataObject, err error) {
    query := prepareFetchQuery(object)

    fmt.Println("The Query:     ", query)
    prepared, err := connection.db.Prepare(query)
    panicIfError(err)

    result, err = fillObjectFromDbQueryDynamic(prepared, object)

    return
}

func fillRequestColsDynamic(object DataObject) (columns string) {
	switch object.(type) {
	case User:
		columns = insertValuesFetch(columns, cId, cRoleIdCol, cFirstNameCol, cLastNameCol, cEmailCol, cActiveCol, cUserNameCol, cPasswordCol, cSaltCol)
		// User
	case Right:
		columns = insertValuesFetch(columns, cId, cNameCol)
		// Right
	case Role:
		columns = insertValuesFetch(columns, cId, cNameCol)
		// Role
	case Document:
		columns = insertValuesFetch(columns, cId, cUserIdCol)
		// Doc
	case GroupKey:
		columns = insertValuesFetch(columns, cId, cKeyTypeIdCol, cDocIdCol, cKeyDataCol, cKeyIvCol)
		// GroupKey
	case DocumentKey:
		columns = insertValuesFetch(columns, cId, cKeyTypeIdCol, cKeyDataCol, cKeyIvCol)
		// DocKey
	case KeyType:
		columns = insertValuesFetch(columns, cId, cNameCol)
		// keyType
	default:
		panic("Object is not of any supported type.")
	}
	return
}

func fillObjectFromDbQueryDynamic(query *sql.Stmt, object DataObject) (result DataObject, err error) {
	fmt.Println(object)
	switch t := (object).(type) {
	case User:
		user := User{}
		query.QueryRow().Scan(&user.Id, &user.Role.Id, &user.FirstName, &user.LastName, &user.Email, &user.Active, &user.UserName, &user.Pass, &user.Salt)
		user.Role, err = makeRole(user.Role)
		result = user
	case Right:
		right := Right{}
		query.QueryRow().Scan(&right.Id, &right.Name)
		result = right
	case Role:
		role := Role{}
		query.QueryRow().Scan(&role.Id, &role.Name)
		result = role
	case Document:
		document := Document{}
		query.QueryRow().Scan(&document.Id, &document.Owner.Id)
		document.Owner, err = makeUser(document.Owner)
		result = document
	case GroupKey:
		groupKey := GroupKey{}
		query.QueryRow().Scan(&groupKey.Id, &groupKey.KeyType.Id, &groupKey.Document.Id, &groupKey.KeyData, &groupKey.KeyIv)
		groupKey.KeyType, err = makeKeyType(groupKey.KeyType)
		groupKey.Document, err = makeDocument(groupKey.Document)
		result = groupKey
	case DocumentKey:
		documentKey := DocumentKey{}
		query.QueryRow().Scan(&documentKey.Id, &documentKey.KeyType.Id, &documentKey.KeyData, &documentKey.KeyIv)
		documentKey.KeyType, err = makeKeyType(documentKey.KeyType)
		result = documentKey
	case KeyType:
		keyType := KeyType{}
		query.QueryRow().Scan(&keyType.Id, &keyType.Name)
		result = keyType
	default:
		fmt.Printf("The object has type:    %T\n", t)
		panic("Object is not of any supported type.")
	}
	return
}

func prepareFetchQuery(object DataObject) (query string) {
	query = cSelect
	query += fillRequestColsDynamic(object)
	query += cFrom + object.TableName()
	query += cWhere + cId + "=" + object.IdToString(10) + cEndQuery
	return
}

func makeRole(object DataObject) (role Role, err error) {
	query := prepareFetchQuery(object)

	prepared, err := connection.db.Prepare(query)
	panicIfError(err)

	prepared.QueryRow().Scan(&role)

	return
}

func makeUser(object DataObject) (user User, err error) {
	query := prepareFetchQuery(object)

	prepared, err := connection.db.Prepare(query)

	prepared.QueryRow().Scan(&user)

	return
}

func makeKeyType(object DataObject) (keyType KeyType, err error) {
	query := prepareFetchQuery(object)

	prepared, err := connection.db.Prepare(query)
	panicIfError(err)

	prepared.QueryRow().Scan(&keyType)

	return
}

func makeDocument(object DataObject) (document Document, err error) {
	query := prepareFetchQuery(object)

	prepared, err := connection.db.Prepare(query)
	panicIfError(err)

	prepared.QueryRow().Scan(&document)

	return
}

/*func (self pgsqlEngine) FetchData(conn *sql.DB) []User {
    rows, err := conn.Query("SELECT * FROM tbl_user;")
    if err != nil {
        fmt.Print("Could not retrieve data: \t")
        fmt.Println(err)
    }

    row := new(User)
    dummy := new([]byte)
    defer rows.Close()

    for rows.Next() {
        // TODO Update database and code to new schema
        err := rows.Scan(&row.Id, &row.Role.Id, &row.FirstName, &row.LastName, &row.Email, &dummy, &row.Active)
        if err != nil {
            fmt.Print("Parsing generated error:   ")
            fmt.Println(err)
        }
        self.resultSetUsers = append(self.resultSetUsers, *row)
        fmt.Println(row.Id, row.FirstName, row.LastName, row.Active)
    }
    err = rows.Err()
    if err != nil {
        fmt.Print("Last error:   ")
        fmt.Println(err)
    }
    return self.resultSetUsers
}*/

func (user User) Persist(conn *sql.DB) (id uint64, err error) {
    var activeVal string = ""
    roleIdVal     := strconv.FormatUint(user.Role.Id, 10)
    firstNameVal  := "'" + user.FirstName + "'"
    lastNameVal   := "'" + user.LastName + "'"
    emailVal      := "'" + user.Email + "'"
    activeVal      = string(strconv.AppendBool([]byte(activeVal), user.Active))
    userNameVal   := "'" + user.UserName + "'"
    passwordVal   := "'\\x" + hex.EncodeToString(user.Pass) + "'"
    saltVal       := "'\\x" + hex.EncodeToString(user.Salt) + "'"

    //var tempId *uint64 = 0
    query := prepareQuery(user.TableName(), cRoleIdCol, cFirstNameCol, cLastNameCol, cEmailCol, cActiveCol, cUserNameCol, cPasswordCol, cSaltCol)
    query  = insertValues(query, roleIdVal, firstNameVal, lastNameVal, emailVal, activeVal, userNameVal, passwordVal, saltVal)
    id, err = executeQueryReturnId(conn, query)
    user.Id = id
    return
}

// TODO test
func (user User) Update(conn *sql.DB) (err error) {
    var activeVal string = ""
    roleIdVal     := strconv.FormatUint(user.Role.Id, 10)
    firstNameVal  := "'" + user.FirstName + "'"
    lastNameVal   := "'" + user.LastName + "'"
    emailVal      := "'" + user.Email + "'"
    activeVal      = string(strconv.AppendBool([]byte(activeVal), user.Active))
    userNameVal   := "'" + user.UserName + "'"
    passwordVal   := "'\\x" + hex.EncodeToString(user.Pass) + "'"
    saltVal       := "'\\x" + hex.EncodeToString(user.Salt) + "'"
    query := prepareUpdateQuery(user.TableName(), cRoleIdCol, cFirstNameCol, cLastNameCol, cEmailCol, cActiveCol, cUserNameCol, cPasswordCol, cSaltCol)
    query  = finalizeUpdateQuery(query, user.Id, roleIdVal, firstNameVal, lastNameVal, emailVal, activeVal, userNameVal, passwordVal, saltVal)
    _, err = executeQueryReturnId(conn, query)
    return
}

// TODO change create script to have automatic removal of dependent data in delete case
func (user User) Delete(conn *sql.DB) (err error) {
    err = errors.New("Not yet implemented!")
    return
}

func (user User) TableName() (tableName string) {
    return cUserTable
}

func (user User) IdToString(radix int) (id string) {
	id = strconv.FormatUint(user.Id, radix)
	return
}

/*func (userKey UserKey) Persist(conn *sql.DB) (id uint64, err error) {
    userIdVal    := strconv.FormatUint(userKey.Id, 10)
    keyTypeIdVal := strconv.FormatUint(userKey.KeyType.Id, 10)
    pubKeyVal    := "'\\x" + hex.EncodeToString(userKey.KeyData) + "'"
    keyIvVal     := "'\\x" + hex.EncodeToString(userKey.KeyIv) + "'"
    query := prepareQuery(userKey.TableName(), cUserIdCol, cKeyTypeIdCol, cPubKeyCol, cKeyIvCol)
    query  = insertValues(query, userIdVal, keyTypeIdVal, pubKeyVal, keyIvVal)
    id, err = executeQueryReturnId(conn, query)
    userKey.Id = id
    return
}

func (userKey UserKey) Update(conn *sql.DB) (err error) {
    userIdVal    := strconv.FormatUint(userKey.Id, 10)
    keyTypeIdVal := strconv.FormatUint(userKey.KeyType.Id, 10)
    pubKeyVal    := "'\\x" + hex.EncodeToString(userKey.KeyData) + "'"
    keyIvVal     := "'\\x" + hex.EncodeToString(userKey.KeyIv) + "'"
    query := prepareUpdateQuery(userKey.TableName(), cUserIdCol, cKeyTypeIdCol, cPubKeyCol, cKeyIvCol)
    query  = finalizeUpdateQuery(query, userKey.Id, userIdVal, keyTypeIdVal, pubKeyVal, keyIvVal)
    _, err = executeQueryReturnId(conn, query)
    return
}

func (userKey UserKey) Delete(conn *sql.DB) (err error) {
    err = errors.New("Not yet implemented!")
    return
}

func (userKey UserKey) TableName() (tableName string) {
    return cUserKeyTable
}*/


func (document Document) Persist(conn *sql.DB) (id uint64, err error) {
    userIdVal    := strconv.FormatUint(document.Owner.Id, 10)
    query := prepareQuery(document.TableName(), cUserIdCol)
    query  = insertValues(query, userIdVal)
    id, err = executeQueryReturnId(conn, query)
    document.Id = id
    return
}

func (document Document) Update(conn *sql.DB) (err error) {
    userIdVal    := strconv.FormatUint(document.Owner.Id, 10)
    query := prepareUpdateQuery(document.TableName(), cUserIdCol)
    query  = finalizeUpdateQuery(query, document.Id, userIdVal)
    _, err = executeQueryReturnId(conn, query)
    return
}

func (document Document) Delete(conn *sql.DB) (err error) {
    err = errors.New("Not yet implemented!")
    return
}

func (document Document) TableName() (tableName string) {
    return cDocumentTable
}

func (document Document) IdToString (radix int) (id string) {
	id = strconv.FormatUint(document.Id, radix)
	return
}


func (documentKey DocumentKey) Persist(conn *sql.DB) (id uint64, err error) {
    keyDataVal :=  "'\\x" + hex.EncodeToString(documentKey.KeyData) + "'"
    keyIvVal   := "'\\x" + hex.EncodeToString(documentKey.KeyIv) + "'"
    query := prepareQuery(documentKey.TableName(), cKeyDataCol, cKeyIvCol)
    query  = insertValues(query, keyDataVal, keyIvVal)
    id, err = executeQueryReturnId(conn, query)
    documentKey.Id = id
    return
}

func (documentKey DocumentKey) Update(conn *sql.DB) (err error) {
    keyDataVal :=  "'\\x" + hex.EncodeToString(documentKey.KeyData) + "'"
    keyIvVal   := "'\\x" + hex.EncodeToString(documentKey.KeyIv) + "'"
    query := prepareUpdateQuery(documentKey.TableName(), cKeyDataCol, cKeyIvCol)
    query  = finalizeUpdateQuery(query, documentKey.Id, keyDataVal, keyIvVal)
    _, err = executeQueryReturnId(conn, query)
    return
}

func (documentKey DocumentKey) Delete(conn *sql.DB) (err error) {
    err = errors.New("Not yet implemented!")
    return
}

func (documentKey DocumentKey) TableName() (tableName string) {
    return cDocumentKeyTable
}

func (documentKey DocumentKey) IdToString (radix int) (id string) {
	id = strconv.FormatUint(documentKey.Id, radix)
	return
}


func (groupKey GroupKey) Persist(conn *sql.DB) (id uint64, err error) {
    keyTypeIdVal  := strconv.FormatUint(groupKey.KeyType.Id, 10)
    docIdVal      := strconv.FormatUint(groupKey.Document.Id, 10)
    keyDataVal    := "'\\x" + hex.EncodeToString(groupKey.KeyData) + "'"
    keyIvVal      := "'\\x" + hex.EncodeToString(groupKey.KeyIv) + "'"
    query  := prepareQuery(groupKey.TableName(), cKeyTypeIdCol, cDocIdCol, cKeyDataCol, cKeyIvCol)
    query   = insertValues(query, keyTypeIdVal, docIdVal, keyDataVal, keyIvVal)
    id, err = executeQueryReturnId(conn, query)
    groupKey.Id = id
    return
}

func (groupKey GroupKey) Update(conn *sql.DB) (err error) {
    keyTypeIdVal  := strconv.FormatUint(groupKey.KeyType.Id, 10)
    docIdVal      := strconv.FormatUint(groupKey.Document.Id, 10)
    keyDataVal    := "'\\x" + hex.EncodeToString(groupKey.KeyData) + "'"
    keyIvVal      := "'\\x" + hex.EncodeToString(groupKey.KeyIv) + "'"
    query  := prepareUpdateQuery(groupKey.TableName(), cKeyTypeIdCol, cDocIdCol, cKeyDataCol, cKeyIvCol)
    query   = finalizeUpdateQuery(query, groupKey.Id, keyTypeIdVal, docIdVal, keyDataVal, keyIvVal)
    _, err = executeQueryReturnId(conn, query)
    return
}

func (groupKey GroupKey) Delete(conn *sql.DB) (err error) {
    err = errors.New("Not yet implemented!")
    return
}

func (groupKey GroupKey) TableName() (tableName string) {
    return cGroupKeyTable
}

func (groupKey GroupKey) IdToString (radix int) (id string) {
	id = strconv.FormatUint(groupKey.Id, radix)
	return
}


func (keyType KeyType) Persist(conn *sql.DB) (id uint64, err error) {
    nameVal := "'" + keyType.Name + "'"
    query  := prepareQuery(keyType.TableName(), cNameCol)
    query   = insertValues(query, nameVal)
    id, err = executeQueryReturnId(conn, query)
    keyType.Id = id
    return
}

func (keyType KeyType) Update(conn *sql.DB) (err error) {
    nameVal := "'" + keyType.Name + "'"
    query  := prepareUpdateQuery(keyType.TableName(), cNameCol)
    query   = finalizeUpdateQuery(query, keyType.Id, nameVal)
    _, err = executeQueryReturnId(conn, query)
    return
}

func (keyType KeyType) Delete(conn *sql.DB) (err error) {
    err = errors.New("Not yet implemented!")
    return
}

func (keyType KeyType) TableName() (tableName string) {
    return cKeyTypeTable
}

func (keyType KeyType) IdToString (radix int) (id string) {
	id = strconv.FormatUint(keyType.Id, radix)
	return
}


func (right Right) Persist(conn *sql.DB) (id uint64, err error) {
    nameVal := "'" + right.Name + "'"
    query  := prepareQuery(right.TableName(), cNameCol)
    query   = insertValues(query, nameVal)
    id, err = executeQueryReturnId(conn, query)
    right.Id = id
    return
}

func (right Right) Update(conn *sql.DB) (err error) {
    nameVal := "'" + right.Name + "'"
    query  := prepareUpdateQuery(right.TableName(), cNameCol)
    query   = finalizeUpdateQuery(query, right.Id, nameVal)
    _, err = executeQueryReturnId(conn, query)
    return
}

func (right Right) Delete(conn *sql.DB) (err error) {
    err = errors.New("Not yet implemented!")
    return
}

func (right Right) TableName() (tableName string) {
    return cRightTable
}

func (right Right) IdToString (radix int) (id string) {
	id = strconv.FormatUint(right.Id, radix)
	return
}


func (role Role) Persist(conn *sql.DB) (id uint64, err error) {
    nameVal := "'" + role.Name + "'"
    query  := prepareQuery(role.TableName(), cNameCol)
    query   = insertValues(query, nameVal)
    id, err = executeQueryReturnId(conn, query)
    role.Id = id
    return
}

func (role Role) Update(conn *sql.DB) (err error) {
    nameVal := "'" + role.Name + "'"
    query  := prepareUpdateQuery(role.TableName(), cNameCol)
    query   = finalizeUpdateQuery(query, role.Id, nameVal)
    _, err = executeQueryReturnId(conn, query)
    return
}

func (role Role) Delete(conn *sql.DB) (err error) {
    err = errors.New("Not yet implemented!")
    return
}

func (role Role) TableName() (tableName string) {
    return cRoleTable
}

func (role Role) IdToString (radix int) (id string) {
	id = strconv.FormatUint(role.Id, radix)
	return
}


func prepareQuery(tableName string, columns ...string) (query string) {
    query  = cBeginInsertQuery + tableName + cOpenPar
    query += putStrings(columns)
    query += cValuesPars
    return
}

func insertValues(query string, values ...string) (preparedQuery string) {
    preparedQuery  = query
    preparedQuery += putStrings(values)
    preparedQuery += cEndInsertQuery
    return
}

func insertValuesFetch(query string, values ...string) (preparedQuery string) {
	preparedQuery  = query
	preparedQuery += putStrings(values)
	return
}

func putStrings(values []string) (result string) {
    result = ""
    for i, value := range values {
        result += value
        if (i+1) < len(values) {
            result += ", "
        }
    }
    return
}

func executeQueryReturnId(conn *sql.DB, query string) (id uint64, err error) {
    fmt.Println("the query: ", query)
    prepared, err := conn.Prepare(query)
    panicIfError(err)

    err = prepared.QueryRow().Scan(&id)
    panicIfError(err)

    fmt.Println("the id:   ", id)
    return
}

func prepareUpdateQuery(tableName string, columns ...string) (query string) {
    query = "UPDATE "+tableName+" SET ("
    query += putStrings(columns)
    query += ") = ("
    return
}

func finalizeUpdateQuery(query string, id uint64, values ...string) (preparedQuery string) {
    preparedQuery  = query
    preparedQuery += putStrings(values)
    preparedQuery += ") WHERE id = " + strconv.FormatUint(id, 10)
    preparedQuery += "RETURNING id;"
    return
}
