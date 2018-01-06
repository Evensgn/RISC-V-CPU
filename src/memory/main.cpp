#include "environment.h"
#include <fstream>
#include <boost/program_options.hpp>

int main(int argc, char *argv[])
{
	using namespace boost::program_options;
	options_description options("Options:");
	options.add_options()
		("help,h", "Display this information")
		("memory", value<std::string>()->value_name("file"), "[in] Initial Memory File")
		("memory-size", value<int>()->value_name("size"), "Memory Size")
		("io-input", value<std::string>()->value_name("file"), "[in] I/O Input File")
		("io-output", value<std::string>()->value_name("file"), "[out] I/O Output File")
		("time-file", value<std::string>()->value_name("file"), "[out] The running time")
		("com-port", value<std::string>()->value_name("port"), "The serial port connected to the fpga")
		("verbose", "Display Verbose Information");

	variables_map vm;
	try
	{
		store(command_line_parser(argc, argv).options(options).run(), vm);
		notify(vm);
	}
	catch (std::exception &e)
	{
		std::cerr << e.what() << std::endl;
		return -1;
	}

	bool sim = false;

	if (vm.count("help"))
	{
		std::cout << options;
		return 0;
	}

	if (!vm.count("com-port"))
	{
		std::cerr << "COM Port not specified" << std::endl;
		std::cerr << "Use simulation mode" << std::endl;
		sim = true;
	}
	if (!vm.count("memory"))
	{
		std::cerr << "Initial memory file not specified" << std::endl;
		return -1;
	}

	size_t memSize = 0x10000000;
	if (vm.count("memory-size"))
		memSize = vm["memory-size"].as<int>();
	Environment env(sim ? "" : vm["com-port"].as<std::string>(), memSize, vm.count("verbose"));

	std::stringstream ss1, ss2;
	std::ifstream fioIn;
	std::ofstream fioOut;

	std::istream *ioIn = nullptr;
	std::ostream *ioOut = nullptr;

	if (vm.count("io-input"))
	{
		fioIn.open(vm["io-input"].as<std::string>(), std::ios::binary | std::ios::in);
		ioIn = &fioIn;
	}
	else
		ioIn = &ss1;
	if (vm.count("io-output"))
	{
		fioOut.open(vm["io-output"].as<std::string>(), std::ios::binary | std::ios::out);
		ioOut = &fioOut;
	}
	else
		ioOut = &ss2;

	double runTime = 0.;
	int ret = env.Run(vm["memory"].as<std::string>(), *ioIn, *ioOut, runTime, sim);

	if (vm.count("time-file"))
	{
		std::ofstream ftime(vm["time-file"].as<std::string>());
		ftime << runTime << std::endl;
	}
	
	return ret;
}