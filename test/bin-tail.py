#!/usr/bin/env python
import os
import sys
import binascii

INPUT = sys.argv[1]

with open(INPUT, 'ab') as f:
	s = binascii.a2b_hex('00' * 8)
	f.write(s)