#ifndef CPU_JUDGE_ENVIRONMENT_H
#define CPU_JUDGE_ENVIRONMENT_H

#include "env_iface.h"
#include "adapter.h"
#include <chrono>
#include <iostream>
#include <sstream>
#include <iomanip>

class Environment : public IEnvironment
{
public:
	virtual data_t ReadMemory(addr_t addr) override;
	virtual void WriteMemory(addr_t addr, data_t data, int mask) override;

	virtual void UARTSend(const std::vector<std::uint8_t> &data) override { serPort.write(data); }
	virtual void UARTSend(const std::string &data) override { serPort.write(data); }

public:
	Environment(const std::string &port, size_t memSize, bool verbose);

	int Run(const std::string &memFilePath, std::istream &in, std::ostream &out, double &time, bool simulate);

public:
	class AddressUnalignedException : public std::exception
	{
	public:
		AddressUnalignedException(addr_t addr, bool isWrite)
		{
			std::stringstream ss;
			ss << "Trying to " << (isWrite ? "Write" : "Read") << " an unaligned memory address: " << addr;
			description = ss.str();
		}

		const char * what() const noexcept override
		{
			return description.c_str();
		}

		std::string description;
	};

	class AddressOutofRangeException : public std::exception
	{
	public:
		AddressOutofRangeException(addr_t addr, bool isWrite)
		{
			std::stringstream ss;
			ss << "Trying to " << (isWrite ? "Write" : "Read") << " an invalid address: " << addr;
			description = ss.str();
		}

		const char * what() const noexcept override
		{
			return description.c_str();
		}

		std::string description;
	};

protected:
	template<typename T, typename ...Tother>
	void log_impl(T &&arg, Tother &&...other)
	{
		std::cerr << std::forward<T>(arg);
		log_impl(std::forward<Tother>(other)...);
	}
	void log_impl() {}

	template<typename ...T>
	void log(T &&...args)
	{
		if (is_timing)
		{
			std::chrono::duration<double> duration =
				std::chrono::duration_cast<std::chrono::duration<double>>(
					std::chrono::high_resolution_clock::now() - startTime);
			std::cerr << "[" << std::setiosflags(std::ios::fixed) << std::setprecision(3) << duration.count() << "] ";
		}
		else
			std::cerr << "[---] ";
		log_impl(std::forward<T>(args)...);
		std::cerr << std::endl;
	}

	template<typename ...T>
	void logError(T &&...args)
	{
		log("[ERROR] ", std::forward<T>(args)...);
	}

	template<typename ...T>
	void logWarn(T &&...args)
	{
		log("[WARN] ", std::forward<T>(args)...);
	}

	template<typename ...T>
	void logInfo(T &&...args)
	{
		log("[INFO] ", std::forward<T>(args)...);
	}

	template<typename ...T>
	void logDebug(T &&...args)
	{
		if (verbose)
		{
			log("[DEBUG] ", std::forward<T>(args)...);
		}
	}

protected:
	Adapter adapter;
	serial::Serial serPort;
	std::vector<std::uint8_t> memory;
	std::chrono::high_resolution_clock::time_point startTime;
	bool is_running, is_timing;
	bool verbose;

	std::istream *ioIn;
	std::ostream *ioOut;

protected:
	static const addr_t addrInput = 0x100;
	static const addr_t addrOutput = 0x104;
	static const addr_t addrFinish = 0x108;
	static const addr_t addrHighMem = 0x1000;
};

#endif