#ifndef CPU_JUDGE_SIMULATOR_H
#define CPU_JUDGE_SIMULATOR_H

#include "env_iface.h"

enum Funct3 : std::uint32_t;

class Simulator
{
public:
	class CPUException : public std::exception
	{
	public:
		std::string description;
		CPUException(std::string str) : description(std::move(str)) {}

		const char *what() const noexcept
		{
			return description.c_str();
		}
	};
public:
	Simulator() : env(nullptr), PC(0) {}

	void RunInsn();
	void setEnvironment(IEnvironment *env) { this->env = env; }

protected:
	std::uint32_t & getReg(std::uint32_t id);
	bool branchCond(Funct3 funct3, std::uint32_t regRS1, std::uint32_t regRS2);
	std::uint32_t load(Funct3 funct3, std::uint32_t addr);
	void store(Funct3 funct3, std::uint32_t addr, std::uint32_t data);
	std::uint32_t alu(Funct3 funct3, std::uint32_t op1, std::uint32_t op2, std::uint32_t funct7);

protected:
	IEnvironment *env;

	std::uint32_t reg[32];
	std::uint32_t PC;
};

#endif