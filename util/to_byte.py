import struct

def GetBits(bytesInput):
    return [[(byte >> i) & 1 for i in range(7, -1, -1)] for byte in bytesInput]

def str_to_bytes():
    while True:
        my_string = input()
        my_bytes = my_string.encode('utf-8')

        bits = GetBits(my_bytes)

        print(len(my_string), bits)
        
def uint_to_bytes():
    while True:
        my_int = eval(input())
        my_bytes = struct.pack('<Q', my_int)
        bits = GetBits(my_bytes)
        bits_str = [[str(v) for v in l] for l in bits]
        print(len(my_bytes), str(bits_str).replace('\'', '\"'))

print(struct.pack('<Q', 20000).hex())

# my_bytes = bytes.fromhex("662ad25db00e7bb38bc04831ae48b4b446d12698")
# bits = GetBits(my_bytes)
# bits_str = [[str(v) for v in l] for l in bits]
# print(len(my_bytes), str(bits_str).replace('\'', '\"'))