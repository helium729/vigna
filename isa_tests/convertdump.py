import os 
import sys

#read data from objdump file
def read_objdump(file_name):
    data = []
    with open(file_name, 'r') as f:
        for line in f:
            if line.startswith('  '):
                data.append(line.split()[1])
    return data



#main function
def main():
    #check the number of arguments
    if len(sys.argv) != 2:
        print("Usage: ./convert.py <objdump file>")
        sys.exit(1)
    #read objdump file
    data = read_objdump(sys.argv[1])
    #get number from data
    number = []
    for i in data:
        number.append(int(i, 16))
    rb = []
    #conver int to 4 bytes
    for i in range(len(number)):
        t = number[i].to_bytes(4, byteorder='little')
        for j in t:
            #print j in hex with out 0x in 2 digits
            rb.append(hex(j)[2:].zfill(2))
    for i in rb:
        print(i)



main()