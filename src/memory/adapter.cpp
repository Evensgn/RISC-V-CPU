// This file is based on Zhanghao Wu's code

#include "adapter.h"
#include <iostream>
#include <iomanip>

void Adapter::sendData(std::uint32_t data) {
	std::vector<std::uint8_t> send_data;
	send_data.push_back(uint8_t((0b100 << (PACKET_SIZE - 3)) | (send_packet_id & 0b11111)));
	send_data.push_back(uint8_t((0b101 << (PACKET_SIZE - 3)) | 0));
	send_data.push_back(uint8_t((0b110 << (PACKET_SIZE - 3)) | 4));
	for (int i = 0; i < 5; ++i)
		send_data.push_back(uint8_t(0x7f & (data >> (i * 7))));
	send_data.push_back(uint8_t((0x111 << (PACKET_SIZE - 3)) | (send_packet_id & 0b11111)));
	std::clog << "Send data: ";
	for (auto x : send_data)
		std::clog << std::hex << std::setw(2) << std::setfill('0') << uint8_t(x) << ' ';
	std::clog << std::endl;
	env->UARTSend(send_data);
}

void Adapter::processData(std::vector<std::uint8_t> data) {
	if (data.size() == 5 && data[4] == 0) {
		uint32_t addr = data[0] | data[1] << 8 | data[2] << 16 | data[3] << 24;
		uint32_t word = env->ReadMemory(addr);
		std::clog << "GET READ REQUEST: ADDR: 0x"
			<< std::hex << std::setw(8) << std::setfill('0')
			<< addr << ", DATA: 0x" 
			<< std::hex << std::setw(8) << std::setfill('0') << word << std::endl;
		sendData(word);
	}
	else if (data.size() == 9) {
		uint32_t wdata = data[0] | data[1] << 8 | data[2] << 16 | data[3] << 24;
		uint32_t addr = data[4] | data[5] << 8 | data[6] << 16 | data[7] << 24;

		std::clog << "GET WRITE REQUEST: ADDR: 0x"
			<< std::hex << std::setw(8) << std::setfill('0')
			<< addr << ", DATA: 0x" << wdata;
		std::clog << ", MASK: " << std::bitset<4>(data[8]) << std::endl;
		if (addr == 0x104)
			std::cout << data[0] << std::endl;
		env->WriteMemory(addr, wdata, data[8]);
	}
}

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

	bitset<8> recv_data = data;

	switch (recv_state) {
	case STATUS_IDLE:
		if (recv_data >> (PACKET_SIZE - 3) == 0b100) {
			recv_packet_id = recv_data & 0b11111;
			recv_bit = 0;
			recv_length = 0;
			recv_status = STATUS_CHANNEL;
		}
		else std::cerr << "Error: Something went wrong to STAUTS_IDLE." << std::endl;
		break;
	case STATUS_CHANNEL:
		if (recv_data >> (PACKET_SIZE - 3) == 0b101)
			recv_status = STATUS_LENGTH;
		else {
			recv_status = STATUS_IDLE;
			std::cerr << "Error: Something is going wrong at STATUS_CHANNEL." << std::endl;
		}
		break;
	case STATUS_LENGTH:
		if (recv_data >> (PACKET_SIZE - 3) == 0b110) {
			recv_length = recv_data & 0b11111;
			recv_status = STATUS_DATA;
			std::clog << "Receive data length: " << recv_length << std::endl;
		}
		else {
			recv_status = STATUS_IDLE;
			std::cerr << "Error: Something is going wrong at STATUS_LENGTH." << std::endl;
		}
		break;
	case STATUS_DATA:
		if (recv_data >> (PACKET_SIZE - 1) == 0b0) {
			for (int i = 0; i < PACKET_SIZE - 1; ++i)
				read_buffer[recv_bit + i] = (recv_data >> i) & 1;
			recv_bit += PACKET_SIZE - 1;
			if (recv_bit >= (recv_length << 3))
				recv_status = STATUS_END;
		}
		else {
			recv_status = STAUTS_IDLE;
			std::cerr << "Error: Something is going wrong at STATUS_DATA." << std::endl;
		}
		break;
	case STATUS_END:
		std::vector<std::uint8_t> get_data; 
		if (recv_data >> (PACKET_SIZE - 3) == 0b111) {
			if (recv_packet_id == (recv_data & 0b11111)) {
				for (int i = 0; i < recv_length; ++i)
					get_data.push_back(0xff & read_buffer << (i * 8));
				processData(get_data);
			}
			else
				std::cerr << "Error: Packet id does not match." << std::endl;
		}
		else {
			recv_status = STATUS_IDLE;
			std::cerr << "Error: Something is going wrong at STATUS_END." << std::endl;
		}
		break;
	}
}