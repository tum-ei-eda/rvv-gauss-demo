CMAKE_MINIMUM_REQUIRED(VERSION 3.5 FATAL_ERROR)
SET(CMAKE_TOOLCHAIN_FILE
    "cmake/rv64_tumeda/toolchain.cmake"
)
PROJECT(onetiss_examples)
INCLUDE(cmake/RV64Target.cmake)

SET(MCE_DIM "6960119" CACHE STRING "McEliece matrix dimensions. Supported: '6960119' (default), '8192128', '6688128'")
ADD_DEFINITIONS(-DMCELIECE_${MCE_DIM})
MESSAGE ("McEliece matrix dimensions set to ${MCE_DIM}")

ADD_EXECUTABLE_(rvv64_example 
	main.c
)
