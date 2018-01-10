#ifndef CPU_JUDGE_ADAPTER_H
#define CPU_JUDGE_ADAPTER_H

#include "env_iface.h"
#include <bitset>

class Adapter
{
private:
	enum Status {STATUS_IDLE, STATUS_CHANNEL, STATUS_LENGTH, STATUS_DATA, STATUS_END};
	static const size_t PACKET_SIZE = 8, MESSAGE_BIT = 256;

	Status recv_status = STATUS_IDLE;
	size_t recv_bit = 0, recv_packet_id = 0, recv_length = 0, send_packet_id = 1;

	std::bitset<MESSAGE_BIT> read_buffer;

	void sendData(std::uint32_t data);
	void processData(std::vector<std::uint8_t> data);

public:
	Adapter() : env(nullptr) {}

	void setEnvironment(IEnvironment *env) { this->env = env; }

	void onRecv(std::uint8_t data);

	//TODO: You may the following settings according to the UART implementation in your CPU
	std::uint32_t getBaudrate() { return 2304000; }
	serial::bytesize_t getBytesize() { return serial::eightbits; }
	serial::parity_t getParity() { return serial::parity_even; }
	serial::stopbits_t getStopBits() { return serial::stopbits_one; }

protected:
	IEnvironment *env;
};

#endif