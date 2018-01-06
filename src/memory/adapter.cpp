#include "adapter.h"

void Adapter::onRecv(std::uint8_t data)
{
	// TODO: Do something when you receive a byte from your CPU
	//
	// You can access the memory like this:
	//    env->ReadMemory(address)
	//    env->WriteMemory(address, data, mask)
	// where
	//   <address>: the address you want to read from / write to, must be aligned to 4 bytes
	//   <data>:    the data you want to write to the <address>
	//   <mask>:    (in range [0x0-0xf]) the bit <i> indicates that you want to write byte <i> of <data> to address <address>+i
	//              for example, if you want to write 0x2017 to address 0x1002, you can write
	//              env.WriteMemory(0x1000, 0x20170000, 0b1100)
	// NOTICE that the memory is little-endian
	//
	// You can also send data to your CPU by using:
	//    env->UARTSend(data)
	// where <data> can be a string or vector of bytes (uint8_t)
}