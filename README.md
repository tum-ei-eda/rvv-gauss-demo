# Vector Extension Simulation Environment

`<dir>` refers to the absolute location of this README's directory.

## Dependencies

- CMake v>=3.13
- Boost v>=1.52
- RISC-V GNU Toolchain v:= rvv0.9

### Install RISC-V Vector GNU Toolchain

1. Clone repository:   

	```
	git clone https://github.com/riscv/riscv-gnu-toolchain.git --branch rvv-0.9.x \
		--single-branch --depth 1 riscv-gnu-toolchain_rvv-0.9.x
	cd riscv-gnu-toolchain_rvv-0.9.x
	git submodule update --init --recursive --depth 1 riscv-binutils riscv-gcc \
		riscv-glibc riscv-dejagnu riscv-newlib riscv-gdb
	```

2. Configure Toolchain

	```
	mkdir build && cd build
	../configure --prefix=`pwd`/installed --enable-multilib
	```

3. Build

	```
	make
	```

In the following steps, `<rvv-gnu-toolchain>` refers to the toolchain's install location. Good practice would be to add a custom environment variable (also required by ETISS for later Target Debug):

```
export RISCVV=`pwd`/installed
```

## Dir

- `<dir>/README.md` this file
- `<dir>/sw/` Target software (RV64IMACV)
- `<dir>/etiss` Simulation ETISS 

## Setup

### Build simulation ETISS

1. `cd <dir>/etiss`
2. `mkdir build && cd build`
3. ```cmake -DCMAKE_INSTALL_PREFIX:PATH=`pwd`/installed -DCMAKE_BUILD_TYPE=Release ..```
4. `make install`

### Build RVV processor (VM)

1. `cd <dir>/vm`
2. `mkdir build && cd build`
3. ```cmake -DETISS_PREFIX=`pwd`/../../etiss/build/installed -DCMAKE_BUILD_TYPE=Release ..```
4. `make`

### Build the target software

Choose the McEliece matrix dimensions (<6688128,8192128,6960119>) with the cmake configuration or leave the variable out for default (6960x119).

1. `cd <dir>/target`
2. `mkdir build && cd build`
3. `cmake -DRISCV_ELF_GCC_PREFIX=<rvv-gnu-toolchain> [-DCMAKE_BUILD_TYPE=Debug] [-DMCE_DIMi=<6688128,8192128,6960119>] ..`
4. `make`

## Simulate

### Out of box

Change into VM directory:

```
cd <dir>/vm
```

The variable `<run-proc>` refers to the processor helper script:

```
<run-proc>:=./run_helper.sh
```

- Simple: 

	`<run-proc> <dir>/target/build/rvv64_example`	

- Verbose: (includes architectural prints on CPU exceptions)

	`<run-proc> <dir>/target/build/rvv64_example v`

- Target Debug: (launches processor with gdb server)

	1. Launch simulation:

		`<run-proc> <dir>/target/build/rvv64_example [v] tgdb`

	2. Launch second remote GDB in second terminal:

		`<rvv-gnu-toolchain>/bin/riscv64-unknown-elf-gdb -ex "tar rem :2222" <dir>/target/build/rvv64_example`


### Develop

`<rvv-gnu-toolchain>` supports assembly only for RVV instructions. The `<dir>/target` project is configured by its CMake build configuration to handle assembly automatically. The following easy software dev are suggested:

- Easy - Modify existing files 
	1. `<dir>/target/main.c`
	2. Build target software:
		`make -C <dir>/target/build`

- Advanced - Add new files
	1. Add custom assembly or C files to `<dir>/target` directory
	2. Modify `<dir>/target/CMakeLists.txt`'s. Append  ADD\_EXECUTABLE(..) body with addional C and Assembly files
	3. Reconfigure build
		```
		cd <dir>/target/build
		cmake -DRISCV_ELF_GCC_PREFIX=<rvv-gnu-toolchain> [-DCMAKE_BUILD_TYPE=Debug] [-DMCE_DIM=<6688128,8192128,6960119>] ..
		make 
		```

