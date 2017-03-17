package crypto

import (
	"encoding/json"
	"os"
	"encoding/hex"
	"fmt"
)

var (
	crypEng cryptoEngine
	encryptionKey Key
)

type CryptoApi struct {}

type configuration struct {
	CryptoEngine    string
	EncryptionKey   string
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

	switch config.CryptoEngine {
	case "sw", "SW":
		engine := swEngine{}
		crypEng = engine
		encryptionKey.Bytes, err = hex.DecodeString(config.EncryptionKey)
		if 32 != len(encryptionKey.Bytes) || err != nil {
			panic("Error occured during initialization! Key must consist of 32 octets.")
		} else {
			// TODO remove
			fmt.Printf("Using key:    %X\n", encryptionKey.Bytes)
			config.EncryptionKey = ""
		}
	default:
		panic("Unsupported cryptography engine!")
	}
}

func (cryp CryptoApi) Encrypt(key Key, plaintext Plaintext) (ciphertext Ciphertext, err error) {
	ciphertext, err = crypEng.encrypt(CipherAndMode{"aes", "gcm"}, key, plaintext)
	return
}

func (cryp CryptoApi) Decrypt(key Key, ciphertext Ciphertext) (plaintext Plaintext, err error) {
	plaintext, err = crypEng.decrypt(CipherAndMode{"aes", "gcm"}, key, ciphertext)
	return
}

func (cryp CryptoApi) GetRandom(numOfOctets int) (dst []byte) {
	dst, err := crypEng.getRandom(numOfOctets)
	if err != nil {
		panic(err)
	}
	return
}

func (cryp CryptoApi) CheckCredentials(credentials LogonCredentials) (result bool, err error) {
	result, err = crypEng.checkCredentials(credentials)
	return
}

func (cryp CryptoApi) EncryptKeyForUser(groupKey Ciphertext) (decGroupKey Plaintext) {
	var err error
//	var tempPlaintext Plaintext
	decGroupKey, err = cryp.Decrypt(encryptionKey, groupKey)
	if err != nil {
		panic("Decryption failed")
	}
//	tempPlaintext, err = cryp.Decrypt(encryptionKey, docKey)
//	encDocKey, err = cryp.Encrypt(Key{Bytes: decGroupKey.Bytes}, tempPlaintext)
	return
}

func (cryp CryptoApi) EncryptForDb(plaintext Plaintext) (ciphertext Ciphertext) {
	ciphertext, err := cryp.Encrypt(encryptionKey, plaintext)
	if err != nil {
		panic("Encryption failed.")
	}
	return
}
