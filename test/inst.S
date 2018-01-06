.org 0x0
 	.global _start
_start:
	ori x1, x0, 0x210 # x1 = 0210
	ori x2, x1, 0x021 # x2 = 0x231
	slli x3, x2, 1  # x3 = 0b010001100010 = 0x462
	andi x4, x3, 0x568 # x4 = 0b010001100000 = 0x460
	ori x5, x0, 0x68a # x5 = 0b011010001010 = 0x68a
	ori x7, x0, 22 # x7 = 22 = 0x16
	sll x5, x5, x7 # x5 = 0xa2800000
	ori x7, x0, 20 # x7 = 20 = 0x14
	sra x6, x5, x7 # x6 = 0xfffffa28
	ori x5, x0, 0x723 # x5 = 0b011100100011 = 0x723
	xor x5, x5, x4 # x5 = 0b001101000011 = 0x343
	add x6, x5, x4 # x6 = 0x7a3
	slti x7, x6, 0x7a4 # x7 = 1
	slti x8, x6, 0x7a3 # x8 = 0
	slt x8, x6, x5 # x8 = 0
	slt x8, x5, x6 # x8 = 1
	sub x9, x6, x5 # x9 = 0x460
	lui x10, 0x45b27 # x10 = 0x45b27000
	auipc x11, 0x21c43 # x11 = 0x21c43048
es_j1:
	bge x10, x11, es_j2 # jump to es_j2
	ori x12, x0, 0x456 # x12 = 0x456
	ori x13, x0, 0x2bc # x13 = 0x2bc
	nop
	nop
	nop
es_j2:
	ori x12, x0, 0x5ef # x12 = 0x5ef
	ori x13, x0, 0x123 # x13 = 0x123
	# j es_j1 # jump to es_j1, which makes an infinite loop
	sb x11, 2(x13) # store 0x48 to mem:0x125
	lb x14, 2(x13) # x14 = 0x48
	sb x12, 1(x13) # store 0xef to mem:0x124
	lh x14, 1(x13) # x14 = 0x48ef
	add x15, x14, x0 # x15 = 0x48ef
	sh x5, 3(x13) # store 0x0343 to mem:0x126
	lw x15, 1(x13) # x15 = 0x034348ef
	add x17, x7, x15 # x17 = 0x034348f0
	sw x11, 5(x13) # store 0x21c43048 to mem:0x128
	lw x16, 5(x13) # x16 = 0x21c43048