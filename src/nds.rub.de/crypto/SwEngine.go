package crypto

import (
	"crypto/cipher"
	"crypto/aes"
	"crypto/rand"
	"hash"
	"crypto/rsa"
//	"fmt"
	"nds.rub.de/dbDefinition"
	"crypto/sha256"
	"fmt"
	"errors"
)

type swEngine struct {}

var(
	database *dbDefinition.DbApi
)

func init() {
	database = new(dbDefinition.DbApi)
}

func (sw swEngine) encrypt(cipherAndMode CipherAndMode, key Key, plaintext Plaintext) (ciphertext Ciphertext, err error) {
	var blockCipher cipher.Block

	switch cipherAndMode.Algorithm {
	case "AES", "aes":
		switch cipherAndMode.Mode {
		case "GCM", "gcm":
			var authEncCipher cipher.AEAD
			// TODO error handling
			blockCipher, err = aes.NewCipher(key.Bytes)
//			fmt.Println("block:    ", err)
			authEncCipher, err = cipher.NewGCM(blockCipher)
//			fmt.Println("aead:     ", err)
			ciphertext.Iv, err = sw.getRandom(authEncCipher.NonceSize())
//			fmt.Println("random:   ", err)
			ciphertext.Bytes = authEncCipher.Seal(ciphertext.Bytes, ciphertext.Iv, plaintext.Bytes, nil)
//			fmt.Println("message:    ", plaintext.Bytes)
//			fmt.Println("key:        ", key.Bytes)
//			fmt.Println("ciphertext: ", ciphertext.Bytes)
//			fmt.Println("iv:         ", ciphertext.Iv)
//			fmt.Println("Done!")
		default:
			panic("Unsupported Mode!")
		}
	default:
		panic("Unsupported Algorithm!")
	}
	return
}

func (sw swEngine) decrypt(cipherAndMode CipherAndMode, key Key, ciphertext Ciphertext) (plaintext Plaintext, err error) {
	var blockCipher cipher.Block

	switch cipherAndMode.Algorithm {
	case "AES", "aes":
		switch cipherAndMode.Mode {
		case "GCM", "gcm":
			blockCipher, err = aes.NewCipher(key.Bytes)
			var authEncCipher cipher.AEAD
			authEncCipher, err = cipher.NewGCM(blockCipher)
			// TODO error handling
			plaintext.Bytes, err = authEncCipher.Open(plaintext.Bytes, ciphertext.Iv, ciphertext.Bytes, nil)
		default:
			panic("Unsupported Mode!")
		}
	default:
		panic("Unsupported Algorithm!")
	}
	return
}

func (sw swEngine) encryptRsa(hash hash.Hash, publicKey *rsa.PublicKey, message []byte, label []byte) (ciphertext []byte, err error) {
	ciphertext, err = rsa.EncryptOAEP(hash, rand.Reader, publicKey, message, label)
	if err != nil {
		panic(err)
	}
	return
}

func (sw swEngine) sign() {

}

func (sw swEngine) verify() {

}

func (sw swEngine) getRandom(numOfOctets int) (dst []byte, err error) {
	dst = make([]byte, numOfOctets)
	_, err = rand.Read(dst)
	if err != nil {
		panic(err)
	}
	return
}

func (sw swEngine) checkCredentials(credentials LogonCredentials) (result bool, err error) {
	// get the user (if exists)
	user, err := database.UserByUsername(credentials.Username)

	fmt.Println("User:   ", user)

	var differs bool = false
	// check active flag
	if user.Active {
		// hash the provided value for password
		hash := hashPassword(user.Salt, []byte(credentials.Password))

		// check for match
		differs = !(len(hash) == len(user.Pass))
		for i, val := range hash {
			differs = differs || !(val == user.Pass[i])
		}
	} else {
		err = errors.New("User account inactive")
		differs = true
	}
	result = !differs

	// return result and error
	return
}

func hashPassword(salt, password []byte) (hashed []byte) {
	hashEngine := sha256.New()
	toHash := make([]byte, 0, 0)
	toHash = append(toHash, salt...)
	toHash = append(toHash, password...)
	hashEngine.Reset()
	hashEngine.Write(toHash)
	hashed = hashEngine.Sum(toHash)[len(toHash):]
	fmt.Printf("Input to hash:   %X\n", toHash)
	fmt.Printf("Resulting hash:  %X\n", hashed)
	return
}
