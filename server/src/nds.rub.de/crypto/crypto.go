package crypto

import (
	"encoding/asn1"
	"hash"
	"crypto/rsa"
)


type cryptoEngine interface {
	encrypt(cipher CipherAndMode, key Key, plaintext Plaintext) (ciphertext Ciphertext, err error)
	decrypt(cipher CipherAndMode, key Key, ciphertext Ciphertext) (plaintext Plaintext, err error)
	encryptRsa(hash hash.Hash, pubKey *rsa.PublicKey, message []byte, label []byte) (ciphertext []byte, err error)
	sign()
	verify()
	getRandom(numOfOctets int) (dst []byte, err error)
	checkCredentials(credentials LogonCredentials) (result bool, err error)
}

type LogonCredentials struct {
	Username  string
	Password  string
}

type Key struct {
	Bytes []byte
}

type CipherAndMode struct {
	Algorithm string
	Mode      string
}

type Plaintext struct {
	Bytes []byte
}

type Ciphertext struct {
	Bytes []byte
	Iv    []byte
}

type RsaPublicKeyDer struct {
	OidSeq           RsaPublicKeyDerOid
	PubKeyBitString  asn1.BitString
}

type RsaPublicKeyDerOid struct {
	RsaOid  asn1.ObjectIdentifier
}
