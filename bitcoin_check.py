import base58
import hashlib

def checkBitcoinAddressConsistency(bitcoinAddress, scriptPubKeyHash):
    decodedAddress = base58.b58decode(bitcoinAddress)
    print(type(decodedAddress))
    print(decodedAddress.hex())
    print(len(decodedAddress.hex()))
    # Check that the address starts with "1" or "3"
    if len(decodedAddress) != 25:
        raise ValueError("Invalid Bitcoin address length")
    if decodedAddress[0] != 0x1 and decodedAddress[0] != 0x3:
        raise ValueError("Invalid Bitcoin address format")
    
    # Remove the prefix and checksum
    addressHash = hashlib.sha256(hashlib.sha256(decodedAddress[1:21]).digest()).digest()[:4]
    
    # Check that the decoded hash matches the script public key hash
    return addressHash == scriptPubKeyHash

bitcoinAddress = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
checkBitcoinAddressConsistency(bitcoinAddress, "")