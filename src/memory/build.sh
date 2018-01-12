#! /bin/sh
export LD_LIBRARY_PATH=/tmp/usr/local/lib
g++ *.cpp -c -std=c++14 -I /tmp/usr/local/include/
g++ *.o -o cpu-judge -L /tmp/usr/local/lib/ -lboost_program_options -lserial