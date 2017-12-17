.org 0x0
 	.global _start
_start:
	ori x1, x0, 0x210 # x1 = h210
	ori x2, x1, 0x021 # x2 = h231
	slli x3, x2, 1  # x3 = b010001100010 = h462
	andi x4, x3, 0x568 # x4 = b010001100000 = h460
	ori x5, x0, 0x68a # x5 = b011010001010 = h68a
	ori x7, x0, 22 # x7 = o22
	sll x5, x5, x7 # x5 = ha2800000
	ori x7, x0, 20 # x7 = o20
	sra x6, x5, x7 # x6 = hfffffa28
	ori x5, x0, 0x723 # x5 = b011100100011 = h723
	xor x5, x5, x4 # x5 = b001101000011 = h343

