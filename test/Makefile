TOOL_CHAIN = /opt/riscv/bin
CROSS_COMPILE = $(TOOL_CHAIN)/riscv32-unknown-elf-

%.o: %.S
	$(CROSS_COMPILE)as $< -o $@ -march=rv32i
%.om: %.o
	$(CROSS_COMPILE)ld -T memory.ld $< -o $@
%.bin: %.om
	$(CROSS_COMPILE)objcopy -O binary $<  $@
%.data: %.bin
	python bin2ascii.py $< $@
	rm -f *.bin *.om *.o
clean:
	rm -f *.o *.om *.bin *.data