set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR RV64)

IF(WIN32)
    set(EXE_EXT ".exe")
    set(DEFAULT_BASENAME "riscv64-unknown-elf")
ELSE()
    set(DEFAULT_BASENAME "riscv64-unknown-elf")
ENDIF()

set(RISCV_ELF_GCC_PREFIX "/usr/local/research/projects/SystemDesign2/tools/riscv/riscv64-unknown-elf.rv64ima-lp64" CACHE PATH "install location for riscv-gcc toolchain")
set(RISCV_ELF_GCC_BASENAME ${DEFAULT_BASENAME} CACHE STRING "base name of the toolchain executables")

set(CMAKE_C_COMPILER ${RISCV_ELF_GCC_PREFIX}/bin/${RISCV_ELF_GCC_BASENAME}-gcc${EXE_EXT})
set(CMAKE_CXX_COMPILER ${RISCV_ELF_GCC_PREFIX}/bin/${RISCV_ELF_GCC_BASENAME}-g++${EXE_EXT})
set(CMAKE_OBJCOPY ${RISCV_ELF_GCC_PREFIX}/bin/${RISCV_ELF_GCC_BASENAME}-objcopy${EXE_EXT})

add_definitions(-D__riscv__)
add_definitions(-march=rv64imacv)
add_definitions(-mabi=lp64)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -march=rv64imac -mabi=lp64")
