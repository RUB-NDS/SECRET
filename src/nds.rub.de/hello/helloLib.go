package main

import (
	"fmt"
	"nds.rub.de/dbDefinition"
	"database/sql"
	"nds.rub.de/crypto"
	"encoding/hex"
)

var (
	db = new (sql.DB)
	err error = nil
	dbApi *dbDefinition.DbApi
	debug *dbDefinition.Debug
	crypi *crypto.CryptoApi
)

func main() {
	var testObject dbDefinition.DataObject
	var testUser, testUserin dbDefinition.User
	var testRole, testRolein dbDefinition.Role
//	var testPubKey dbDefinition.UserKey
	testRole.Id = 1
	testRolein.Id = 2
//	testPubKey.Id = 0

	testUser.Role = testRole
	testUser.FirstName = "John"
	testUser.LastName  = "Doe"
	testUser.Email     = "john.doe@mail.com"
	testUser.UserName  = "john.doe"
	testUser.Pass, _   = hex.DecodeString("F72DDBBF840EE834BC6D3CBCE1DE0A951E00E2FFF083F15A4AF45649C387E5D7")
	testUser.Salt      = []byte{00, 01, 02, 03, 04}
	testUser.Active    = true

	testUserin.Role = testRolein
	testUserin.FirstName = "Jane"
	testUserin.LastName  = "Doe"
	testUserin.Email     = "jane.doe@mail.com"
	testUserin.UserName  = "jane.doe"
	testUserin.Pass, _   = hex.DecodeString("F72DDBBF840EE834BC6D3CBCE1DE0A951E00E2FFF083F15A4AF45649C387E5D7")
	testUserin.Salt      = []byte{00, 01, 02, 03, 04}
	testUserin.Active    = true

	debug = new(dbDefinition.Debug)
	dbApi = new(dbDefinition.DbApi)
	crypi = new(crypto.CryptoApi)
	//inst := connection.Instance()
	db, err = debug.DebugDbEng.Connect()
	if err != nil {
		fmt.Print("FAIL!! Reason: ")
		fmt.Println(err)
	} else {
		//var tempUser dbDefinition.User
		fmt.Println("Success!")
		// Put some dummy data in the database
		aRole := dbDefinition.Role{Name: "Test Role 1"}
		anyRole := dbDefinition.Role{Name: "Test Role 2"}
		aRole.Id, err = aRole.Persist(db)
		anyRole.Id, err = anyRole.Persist(db)

		testObject = testUser
		testUser.Role = aRole
		testUser.Id, err = testObject.Persist(db)
		//testUser.Id = 1

		testUserin.Id, err = testUserin.Persist(db)

		aDocument := dbDefinition.Document{Owner: testUser}
		aDocument.Id, err = aDocument.Persist(db)
//		aDocument.Id = 1

		aKeyType := dbDefinition.KeyType{Name: "Test keytype"}
		aKeyType.Id, err = aKeyType.Persist(db)
//		aKeyType.Id = 1

//		dummyKeyData, err := hex.DecodeString("00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF")
//		encryptedKey := crypi.EncryptForDb(crypto.Plaintext{Bytes: dummyKeyData})
//		aDocKey := dbDefinition.DocumentKey{KeyType: aKeyType, KeyData: encryptedKey.Bytes, KeyIv: encryptedKey.Iv}
//		aDocKey.Id, err = aDocKey.Persist(db)

		dummyKeyData, err  := hex.DecodeString("FFEEDDCCBBAA99887766554433221100FFEEDDCCBBAA99887766554433221100")
		encryptedKey  := crypi.EncryptForDb(crypto.Plaintext{Bytes: dummyKeyData})
		aGroupKey := dbDefinition.GroupKey{KeyType: aKeyType, Document: aDocument, KeyData: encryptedKey.Bytes, KeyIv: encryptedKey.Iv}
		aGroupKey.Id, err = aGroupKey.Persist(db)

		dummyKeyData, err  = hex.DecodeString("2b7e151628aed2a6abf7158809cf4f3c")
		encryptedKey  = crypi.EncryptForDb(crypto.Plaintext{Bytes: dummyKeyData})
		bGroupKey := dbDefinition.GroupKey{KeyType: aKeyType, Document: aDocument, KeyData: encryptedKey.Bytes, KeyIv: encryptedKey.Iv}
		bGroupKey.Id, err = bGroupKey.Persist(db)


		dummyKeyData, err  = hex.DecodeString("000102030405060708090A0B0C0D0E0F")
		encryptedKey  = crypi.EncryptForDb(crypto.Plaintext{Bytes: dummyKeyData})
		anyGroupKey := dbDefinition.GroupKey{KeyType: aKeyType, Document: aDocument, KeyData: encryptedKey.Bytes, KeyIv: encryptedKey.Iv}
		anyGroupKey.Id, err = anyGroupKey.Persist(db)

		aRight := dbDefinition.Right{Name: "Test right"}
		aRight.Id, err = aRight.Persist(db)

		if err != nil {
			fmt.Println("Username already in use?   ", err)
			fmt.Println("foo... ", testObject)
			//panic(err)
		}
		fmt.Println("The persisted user:     ", testUser)
		//result, err := connection.Fetch(tempUser)
		users := dbDefinition.AllUsers(db)
		roles := dbDefinition.AllRoles(db)
		rights := dbDefinition.AllRights(db)
//		pubKeys := dbConnector.AllUserPublicKeys(db)
		docs := dbDefinition.AllDocs(db)
		keyTypes := dbDefinition.AllKeyTypes(db)
		docKeys := dbDefinition.AllDocKeys(db)
		groupKeys := dbDefinition.AllGroupKeys(db)
//		if err != nil {
//			fmt.Println("Failed to fetch:  ", err)
//		} else {
//			fmt.Println(result)
//		}
		fmt.Println(users)
		fmt.Println(roles)
		fmt.Println(rights)
//		fmt.Println(pubKeys)
		fmt.Println(docs)
		fmt.Println(keyTypes)
		fmt.Println(docKeys)
		fmt.Println(groupKeys)
//		cryp := crypto.CryptoApi{}
		keyBytes := crypi.GetRandom(32)
		key := crypto.Key{keyBytes}
		message := crypto.Plaintext{crypi.GetRandom(32)}
		msg, errorrr := crypi.Encrypt(key, message)
		cmp, erroorr := crypi.Decrypt(key, msg)
		fmt.Println("message:     ", message)
		fmt.Println("encrypted:   ", msg, errorrr)
		fmt.Println("decrypted:   ", cmp, erroorr)
		output, _ := dbApi.UserByUsername("john.doe")
		fmt.Println("a single user: ", output)
	}
}
