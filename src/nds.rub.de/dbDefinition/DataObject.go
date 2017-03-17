package dbDefinition
import (
	"database/sql"
)

/**
  * This file holds all database entities
 **/

type DataObject interface {
	Persist(*sql.DB)  (id uint64, err error)
	Update(*sql.DB)   (err error)
	Delete(*sql.DB)   (err error)
	TableName()       (tableName string)
	IdToString(int)   (id string)
}

type User struct {
	Id         uint64
	Role       Role
	FirstName  string
	LastName   string
	Email      string
	//	PubKey     UserKey
	UserName   string
	Pass       []byte
	Salt       []byte
	Active     bool
}

//type UserKey struct {
//	Id         uint64
//	KeyType    KeyType
//	KeyData    []byte
//	KeyIv      []byte
//}

type Document struct {
	Id     uint64
	Owner  User
}

type DocumentKey struct {
	Id      uint64
	KeyType KeyType
	KeyData []byte
	KeyIv   []byte
}

type GroupKey struct {
	Id         uint64
	KeyType    KeyType
	Document   Document
	KeyData    []byte
	KeyIv      []byte
}

type KeyType struct {
	Id   uint64
	Name string
}

type Right struct {
	Id   uint64
	Name string
}

type Role struct {
	Id   uint64
	Name string
}
