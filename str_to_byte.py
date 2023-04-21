while True:
    my_string = input()
    my_bytes = my_string.encode('utf-8')

    bits = [[(byte >> i) & 1 for i in range(7, -1, -1)] for byte in my_bytes]

    print(len(my_string), bits)