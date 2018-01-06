#include "environment.h"
#include "simulator.h"
#include <fstream>
#include <boost/format.hpp>

using boost::format;

Environment::Environment(const std::string &port, size_t memSize, bool verbose) 
	: memory(memSize), is_running(false), is_timing(false), verbose(verbose)
{
	serPort.setPort(port);
	serPort.setBaudrate(adapter.getBaudrate());
	serPort.setBytesize(adapter.getBytesize());
	serPort.setParity(adapter.getParity());
	serPort.setStopbits(adapter.getStopBits());
}

int Environment::Run(const std::string &memFilePath, std::istream &in, std::ostream &out, double &time, bool simulate)
{
	std::ifstream fin(memFilePath, std::ios::binary | std::ios::in);
	if (!fin.is_open())
	{
		logError("Cannot open memory file.");
		return -1;
	}

	for (std::uint8_t &byte : memory)
		byte = 0x0;
	
	size_t pos = 0;
	while (fin)
	{
		if (pos >= memory.size())
		{
			logError("Memory size limit exceeded.");
			return -2;
		}
		char c;
		fin.read(&c, 1);
		memory.at(pos) = std::uint8_t(c);
		pos++;
	}

	fin.close();

	logInfo("Memory initialized. Loaded ", pos, " bytes.");

	ioIn = &in;
	ioOut = &out;

	if (!simulate)
	{
		try
		{
			serPort.open();
		}
		catch (std::exception &e)
		{
			logError("An Exception occurred when opening serial port.");
			logError(e.what());
			return -3;
		}

		adapter.setEnvironment(this);

		is_running = true;
		is_timing = false;

		try
		{
			while (is_running)
			{
				std::uint8_t data;
				serPort.read(&data, 1);
				adapter.onRecv(data);
			}
		}
		catch (std::exception &e)
		{
			logError("An exception occurred when running.");
			logError(e.what());
			return -4;
		}

		is_timing = false;

	}
	else
	{
		Simulator sim;
		sim.setEnvironment(this);

		is_running = true;
		is_timing = false;

		try
		{
			while (is_running)
				sim.RunInsn();
		}
		catch (std::exception &e)
		{
			logError("An exception occurred when running.");
			logError(e.what());
			return -4;
		}

		is_timing = false;
	}

	std::chrono::duration<double> duration = std::chrono::duration_cast<std::chrono::duration<double>>(
		std::chrono::high_resolution_clock::now() - startTime);

	time = duration.count();

	if(!simulate)
		serPort.close();

	logInfo(std::string(simulate ? "Simulation " : "") + "Finished. Running for ", time, " secs");

	return 0;
}

data_t Environment::ReadMemory(addr_t addr)
{
	if (!is_timing)
	{
		startTime = std::chrono::high_resolution_clock::now();
		is_timing = true;
	}
	if (addr & 0x3)
		throw AddressUnalignedException(addr, false);
	if (addr >= memory.size())
		throw AddressOutofRangeException(addr, false);

	data_t data = memory.at(addr) |
		(memory.at(addr + 1) << 8) |
		(memory.at(addr + 2) << 16) |
		(memory.at(addr + 3) << 24);

	if (addr == addrInput)
	{
		if (!(*ioIn))
		{
			logWarn("Input EOF reached");
			data = 0xffffffff;
		}
		else
		{
			char rbuf;
			ioIn->read(&rbuf, 1);
			data = std::uint8_t(rbuf);
		}
	}
	else if (addr == addrOutput)
		logWarn("Trying to read the output port");

	logDebug(format("Read Memory\t0x%08x: %08x") % addr % data);

	return data;
}

void Environment::WriteMemory(addr_t addr, data_t data, int mask)
{
	if(addr & 0x3)
		throw AddressUnalignedException(addr, true);
	if (addr >= memory.size())
		throw AddressOutofRangeException(addr, true);

	logDebug(format("Write Memory\t0x%08x: %08x, mask=%x") % addr % data % mask);

	if (addr == addrInput)
	{
		logWarn("Trying to write input port");
		return;
	}
	else if (addr == addrOutput)
	{
		if (mask & 0x1)
		{
			char wbuf = char(data & 0xff);
			ioOut->write(&wbuf, 1);
		}
		else
			logWarn("Trying to write output port but the mask doesn't include the lowest bit");
		return;
	}
	else if (addr == addrFinish)
	{
		if ((mask & 0x1) && (data & 0xff) == 0xff)
		{
			is_running = false;
		}
		return;
	}
	else if (addr < addrHighMem)
	{
		logWarn("Trying to write low memory");
		return;
	}

	if (mask & 0x1)
		memory.at(addr) = data & 0xff;
	if (mask & 0x2)
		memory.at(addr + 1) = (data >> 8) & 0xff;
	if (mask & 0x4)
		memory.at(addr + 2) = (data >> 16) & 0xff;
	if (mask & 0x8)
		memory.at(addr + 3) = (data >> 24) & 0xff;
}
