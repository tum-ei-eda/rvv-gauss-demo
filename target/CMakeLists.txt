cmake_minimum_required(VERSION 3.5 FATAL_ERROR)
SET(CMAKE_TOOLCHAIN_FILE
    "cmake/rv64_tumeda/toolchain.cmake"
)
project(onetiss_examples)
include(cmake/RV64Target.cmake)

ADD_EXECUTABLE_(rvv64_example 
	main.c 
	gauss.s
)
