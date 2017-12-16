#!/usr/bin/env python

# a python script to assemble riscv instructions
# based on Lequn Chen's Code
import os
import sys
import binascii

TOOLCHAIN = '/opt/riscv/bin/'
INPUT = sys.argv[1]
OUTPUT = sys.argv[2]

os.system('{}/riscv32-unknown-elf-as -o rom.o -march=rv32i {}'.format(TOOLCHAIN, INPUT))
os.system('{}/riscv32-unknown-elf-ld rom.o -o rom.om'.format(TOOLCHAIN))
os.system('{}/riscv32-unknown-elf-objcopy -O binary rom.om rom.bin'.format(TOOLCHAIN))
s = open('rom.bin', 'rb').read()
s = binascii.b2a_hex(s)
with open(OUTPUT, 'w') as f:
    for i in range(0, len(s), 8):
        f.write(s[i:i+8])
        f.write('\n')
os.system('rm -f rom.o rom.om rom.bin')