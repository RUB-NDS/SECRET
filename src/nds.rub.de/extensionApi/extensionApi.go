package extensionApi

import (
	"nds.rub.de/crypto"
	"nds.rub.de/dbDefinition"
	"fmt"
	"encoding/hex"
)

type ExtensionApi struct {}

var(
	crypApi   *crypto.CryptoApi
	dbApi     *dbDefinition.DbApi
)

func init() {
	crypApi = new(crypto.CryptoApi)
	dbApi   = new(dbDefinition.DbApi)
}

func (eApi ExtensionApi) GetKeyById(id uint64, username string) (granted bool, kek []byte, err error) {
	// check if user has right to key and get the document and corresponding group key (encrypted)
	fmt.Println(id)
	var groupKey dbDefinition.GroupKey
//	var docKey dbDefinition.DocumentKey
	user := dbDefinition.User{}
	user.UserName = username
	if dbApi.UserActive(user) {
		// get the encrypted keys from the DB
		//granted, _, _, _ = dbApi.GetKeyForUser(id, username)
		granted, groupKey, err = dbApi.GetKeyForUser(id, username)
		if err != nil {
			panic(err)
		}
		if granted {
			fmt.Println("Access granted :-)")
			groupKeyCiphertext := crypto.Ciphertext{Bytes: groupKey.KeyData, Iv: groupKey.KeyIv}
//			docKeyCiphertext := crypto.Ciphertext{Bytes: docKey.KeyData, Iv: docKey.KeyIv}
			// use the crypto engine to decrypt and encrypt the key material
			decGroupKey := crypApi.EncryptKeyForUser(groupKeyCiphertext)
			// return the keys
			kek = decGroupKey.Bytes
//			key = encDocKey.Bytes
//			keyIv = encDocKey.Iv
		}
	} else {

	}
	// and return
	return
}

func (eApi ExtensionApi) CheckCredentials(credentials crypto.LogonCredentials) (authenticated bool, err error) {
	authenticated, err = crypApi.CheckCredentials(credentials)
	return
}

func (eApi ExtensionApi) GenerateSessionId(numOfOctets int) (sessionId string) {
	var idBytes = crypApi.GetRandom(numOfOctets)
	sessionId = hex.EncodeToString(idBytes)
	fmt.Println("the encoded session id:   ", sessionId)
	return
}

func (eApi ExtensionApi) UsersGroupIds(username string) (groupIds []uint64, err error) {
	groupIds, err = dbApi.UsersGroupIds(username)
	return
}
