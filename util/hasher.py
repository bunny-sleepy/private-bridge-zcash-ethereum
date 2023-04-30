import hashlib

def GetBits(bytesInput):
    return [[(byte >> i) & 1 for i in range(7, -1, -1)] for byte in bytesInput]

def HashBlake2b256(input: str):
    hasher = hashlib.blake2b(digest_size=32)
    hasher.update(input.encode('utf-8'))
    bits = GetBits(hasher.digest())
    bits_str = [[str(v) for v in l] for l in bits]
    print(str(bits_str).replace('\'', '\"'))

def HashSha256d(input: str):
    hasher1 = hashlib.sha256()
    hasher1.update(input.encode('utf-8'))
    output1 = hasher1.digest()
    hasher2 = hashlib.sha256()
    hasher2.update(output1)
    bits = GetBits(hasher2.digest())
    bits_str = [[str(v) for v in l] for l in bits]
    print(str(bits_str).replace('\'', '\"'))

while True:
    a = eval(input())
    if a == 0:
        exit(0)
    elif a == 1:
        b = input()
        HashBlake2b256(b)
    elif a == 2:
        b = input()
        HashSha256d(b)


# tx hash computation