#ifndef CPU_JUDGE_ENV_IFACE_H
#define CPU_JUDGE_ENV_IFACE_H

#include <cstdint>
#include <string>
#include <vector>
#include <serial/serial.h>

#define interface struct

typedef std::uint32_t addr_t;
typedef std::uint32_t data_t;

interface IEnvironment
{
	virtual data_t ReadMemory(addr_t addr) = 0;
	virtual void WriteMemory(addr_t addr, data_t data, int mask) = 0;

	virtual void UARTSend(const std::vector<std::uint8_t> &data) = 0;
	virtual void UARTSend(const std::string &data) = 0;
};

#endif