> 我们要做什么？
> 
> 写一个 CPU ！

由于体系结构课程的 CPU 大作业规定使用 RISC-V 指令集，因此要用到 RISC-V 的 GNU 工具链来进行汇编，最近班上的一些同学就在下载安装，还有同学问我应该如何使用这个工具链。经过上个周末的折腾，我大概可以整理一个非常非官方的 "Manual" 给还没有装好工具链的同学简要介绍一下这个工具链的安装和使用（仅仅是面向此次 CPU 大作业的使用）。

## 安装

首先我们要从 git 仓库将工具链的源码 clone 下来，请注意不要漏掉 `--rescursive` 的选项，否则不会完整地获取所需的子模块代码。
```
$ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
```
整个项目的源码大小有若干个 G ，因此在网络状况不是很好的地方 clone 可能需要耗费数小时的时间（另外交大的校园网似乎不能正常访问其中某个仓库的地址，我是在腾讯云 VPS 上 clone 的）。大家如果是在本机安装可以选择直接下载 WZH 在交大云盘上传的压缩包，在校园网内下载的速度应该很可观。如果下载了 .tar.gz 压缩包，使用下面的命令解压。
```
$ tar -xzvf riscv-gnu-toolchain.tar.gz
```
clone 完成后或解压完下载的压缩包之后，我们需要编译得到的源码。如果是 Windows 用户，建议开一台 Linux 的虚拟机，或者使用 Windows 10 自带的 bash。我们首先要安装 make 这个项目所依赖的一些标准库：

对于 Ubuntu 用户：
```
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev
```
对于 Fedora/CentOS/RHEL 用户：
```
$ sudo yum install autoconf automake libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel
```
对于 MacOS 用户：
```
$ brew install gawk gnu-sed gmp mpfr libmpc isl zlib
```
上面的程序都安装好之后，进入 `riscv-gnu-toolchain` 这个目录，使用下面的命令 make。（如果之前曾经进行过失败的 make ，请先使用 `make clean` 命令清理目标目录）第一行命令配置了 make 的目标路径以及选择了 32 位指令的版本，第二行的 `make` 命令将会 `make newlib` 目标，也就是大作业中需要使用的版本。请注意在 make 命令前加上 `sudo`，否则可能会在 make 了很久很久之后 ，突然提示没有权限在路径中写入文件的错误，这就比较令人伤心了。
```
$ ./configure --prefix=/opt/riscv --with-arch=rv32gc --with-abi=ilp32d
$ sudo make
```
make 这一过程也会消耗较长的时间，可以在 `make` 命令后加 `-j [n]` 来指定使用 n 个核来 make。在这一过程不报错地结束后，工具链的安装应该就成功完成了。可执行文件的目录在 `/opt/riscv/bin` ，在命令行中输入
```
$ /opt/riscv/bin/riscv
```
此时按一下 Tab 键，如果马上跳出了下面的前缀
```
$ /opt/riscv/bin/riscv32-unknown-elf-
```
那么就可以确认已经安装成功了，也可以用下面的命令将这个路径添加到 `PATH` 中，之后调用时就不需要再加目录前缀了。
```
$ PATH=$PATH:/opt/riscv/bin/
```
 
## 使用

安装好工具链之后，我们可以使用包括但不限于下面的程序了。

* `riscv32-unknown-elf-as`
* `riscv32-unknown-elf-ld`
* `riscv32-unknown-elf-objcopy`
现在假设我们有一段汇编代码 `sample.S` 如下，希望得到其对应的二进制指令码：
```
.org 0x0
 	.global _start
_start:
	ori x1, x0, 0x210 # x1 = h210
	ori x2, x1, 0x021 # x2 = h231
	slli x3, x2, 1  # x3 = h462
	andi x4, x3, 0x568 # x4 = h460
	ori x5, x0, 0x68a # x5 = h68a
```
我们首先使用汇编器 `as` 将其汇编成 `.o` 文件，最后一个参数选择使用 RISC-V 32I 指令集。
```
$ riscv32-unknown-elf-as sample.S -o sample.o -march=rv32i
```
然后使用链接器 `ld` 将其链接为 `.om` 可执行文件。
```
$ riscv32-unknown-elf-ld sample.o -o sample.om
```
最后使用 `objcopy` 将 `.om` 文件转换为二进制文件 `.bin`。
```
$ riscv32-unknown-elf-objcopy -O binary sample.om sample.bin
```
用文本编辑器打开二进制文件 `sample.bin` ，以十六进制显示的内容如下，这正是 `sample.S` 文件中的 5 条指令汇编后的机器码：
```
9360 0021 13e1 1002 9311 1100 13f2 8156
9362 a068
```
在实现助教要求的 C++ 模拟内存之前，为了 verilog 模拟时的方便，我们可以在 `initial` 代码块中使用 verilog 中的 `$readmemh` 读取以十六进制数字形式保存的 `ASCII`文件，将其内容初始化到模块中。因此我们可以写一个小脚本来将二进制文件 `.bin` 转换为十六进制数字的 `ASCII` 文件。下面附上一段可以完成这个任务的 Python 脚本 `bin2ascii.py` ，这是我基于乐乐哥的一段代码改的 ;-)
```
#!/usr/bin/env python
# based on Lequn Chen's Code
import os
import sys
import binascii

INPUT = sys.argv[1]
OUTPUT = sys.argv[2]

s = open(INPUT, 'rb').read()
s = binascii.b2a_hex(s)
with open(OUTPUT, 'w') as f:
    for i in range(0, len(s), 8):
        f.write(s[i:i+8])
        f.write('\n')
```
试一试效果吧。
```
$ python bin2ascii.py sample.bin sample.data
```
得到的 `sample.data` 文件就是我们想要的 	`ASCII` 文件了，内容如下：
```
93600021
13e11002
93111100
13f28156
9362a068
```

## 自动化

至此，我们已经可以顺利地将一个汇编程序转换成二进制机器码了。但是这个过程有多个步骤，每次都手动操作效率不高。不妨用功能强大的 `make` 将这个过程自动化。

新建一个目录，在目录里创建一个叫做 `Makefile` 的文件，我写的 Makefile 是这样子的：
```
TOOL_CHAIN = /opt/riscv/bin
CROSS_COMPILE = $(TOOL_CHAIN)/riscv32-unknown-elf-

%.o: %.S
	$(CROSS_COMPILE)as $< -o $@ -march=rv32i
%.om: %.o
	$(CROSS_COMPILE)ld $< -o $@
%.bin: %.om
	$(CROSS_COMPILE)objcopy -O binary $<  $@
%.data: %.bin
	python bin2ascii.py $< $@
	rm -f *.bin *.om *.o
clean:
	rm -f *.o *.om *.bin *.data
```
将 `bin2ascii.py` 和 `sample.S` 文件拷贝到这个目录里，输入 `make sample.data` 试一试：
```
evensgn@ubuntu:~/cpu_testroom$ make sample.data
/opt/riscv/bin/riscv32-unknown-elf-as sample.S -o sample.o -march=rv32i
/opt/riscv/bin/riscv32-unknown-elf-ld sample.o -o sample.om
/opt/riscv/bin/riscv32-unknown-elf-objcopy -O binary sample.om  sample.bin
python bin2ascii.py sample.bin sample.data
rm -f *.bin *.om *.o
```
这样就直接得到我们需要的 `.data` 文件了，如果需要的是中间的其他文件，例如 `sample.bin` ，使用 `make sample.bin` 就可以了。

本文参考了以下来源的内容：

* [https://github.com/riscv/riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain)
* 雷思磊. 自己动手写 CPU. 电子工业出版社, 2014.
* [Make 命令教程](http://www.ruanyifeng.com/blog/2015/02/make.html)，阮一峰的网络日志.