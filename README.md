# IPEA

Facilitating Non-Intrusive In-Vivo Firmware Testing with Stateless Instrumentation

## Introduction
Although numerous dynamic testing techniques have been developed, they can hardly be directly applied to firmware of deeply embedded (e.g., microcontroller-based) devices due to the tremendously different runtime environment and restricted resources on these devices. This work tackles these challenges by leveraging the unique position of microcontroller devices during firmware development. That is, firmware de- velopers have to rely on a powerful engineering workstation that connects to the target device to program and debug code. Therefore, we develop a decoupled firmware testing framework named IPEA, which shifts the overhead of resource-intensive analysis tasks from the microcontroller to the workstation. Only lightweight “needle probes” are left in the firmware to collect internal execution information without processing it. We also instantiated this framework with a sanitizer based on pointer capability (IPEA-San) and a feedback-guided fuzzer (IPEA-Fuzz). By comparing IPEA-San with a port of AddressSanitizer for microcontrollers, we show that IPEA-San reduces the memory overhead by 73.11% in real-world firmware with better detection accuracy. Running IPEA-Fuzz with IPEA-San, we found five new bugs in real IoT libraries and peripheral driver code.

For **NDSS'24 AE**, please refer to this [documentation](docs/AE.md).

## Directories
- ``AFL``: Source code of IPEA-Fuzz (based on AFL-2.5b)
- ``core``: Source code of IPEA-Core and IPEA-San
- ``compiler-plugins``: Compiler plugins
    - ``IPEA-San``: LLVM pass of IPEA-San instrumentation
- ``compiler-rt``: IPEA runtime library (for target MCU)
- ``docs``: Documentations
- ``fw_samples``: Source code of sample projects used in the evaluation
- ``include``: Header files
- ``projects``: Ported projects
    - ``MCU_ASAN``: Ported ASan for microcontrollers
    - ``MCU_Juliet_Testsuite``: Ported Juliet Test Suite for microcontrollers
    - ``BEEBS``: BEEBS benchmark
- ``scripts``: Scripts that facilitate environment setup, unit test, fuzzing, experiments, etc.
- ``unitttest``: Unit test program for IPEA framework
- ``build.sh``: Script of building IPEA framework
- ``clean.sh``: Script of cleaning IPEA framework

## Environment

#### Hardware

- Debugger
    - SEGGER J-Link (Pro/Edu/Edu Mini/Onboard) or J-Trace

- Development boards (used in the artifact evaluation)
    - NXP FRDM-K64F 
    - STM32 Nucleo-F446RE
    - STM32H7B3I-EVAL

#### Host OS

- Ubuntu 22.04 x86/64 LTS (recommended)

#### Software and libraries

- J-Link Software and Documentation pack
- J-Link Runtime Library
- Arm GNU Toolchain
- LLVM 13
- Python 3.x

## Getting Started

#### Install dependencies

1. Install J-Link Software and Documentation pack.
    - Download from https://www.segger.com/downloads/jlink/JLink_Linux_V758e_x86_64.deb and install:
        ```bash
        $ sudo dpkg -i JLink_Linux_V758e_x86_64.deb
        ```

2. Install J-Link Runtime Library
    - Download from https://www.segger.com/downloads/jlink/JLink_Linux_V758e_x86_64.tgz
    - Extract and copy ``libjlinkarm.so.7.58.5`` to ``/usr/lib`` directory:
        ````bash
        $ sudo cp /path/to/JLink_Linux_V758e_x86_64/libjlinkarm.so.7.58.5 /usr/lib
        $ sudo ldconfig
        $ sudo ln -s /usr/lib/jlinkarm.so.7 /usr/lib/jlinkarm.so
        ````

4. Install Arm GNU toolchain

    - Download the latest version of Arm GNU toolchain
package from the official [website](https://developer.arm.com/downloads/-/gnu-rm) and unpack it.

    - Add the unpacked toolchain path to the following enviroment variables:
        ```bash
        export ARMGCC_DIR=/path/to/arm-toolchain
        export PATH=${ARMGCC_DIR}/bin:$PATH
        ```
   

5. Install `spdlog`
    ```bashrc
    $ git clone https://github.com/gabime/spdlog.git
    $ mkdir -p spdlog/build
    $ cd spdlog/build && cmake ..
    $ make && sudo make install
    ```

6. Install LLVM-13 and other dependencies

    ```bash
    $ sudo apt install cmake python3-pip clang-13 llvm-13-dev libjsoncpp-dev libconfig-dev libelf-dev
    $ pip install pyelftools cmsis-svd 
    ```

#### Build IPEA framework

1. Clone source code of IPEA framework to your work directory and add the path to `IPEA_HOME` environment variable:
    ```bash
    export IPEA_HOME=/path/to/IPEA  # IPEA work directory
    ```
2. Build IPEA framework simply by:
    ```bash
    $ cd ${IPEA_HOME}
    $ ./build.sh
    ```

3. Lastly, add the following paths to `PATH` environment variable:
    ```bash
    export PATH=${IPEA_HOME}/build/AFL:${IPEA_HOME}/build/unittest:${IPEA_HOME}/scripts:$PATH
    ```

By the above steps, the following components will be built:

- `ipea-san.so`: **IPEA-San** compiler plugin.
- `libipea-rt.a`: the runtime library of **IPEA-San**. 
- `ipea-unittest`: a unit testing program of **IPEA-San**. It is responsible for verifying the capability of capturing memory-related errors in the target firmware. This program will download the instrumented firmware to the target MCU and run it. An error will be returned if any memory error detected.

- `ipea-fuzz`: the main program of **IPEA-Fuzz**, an AFL-based, coverage-guided fuzzer. Like fuzzing x86_64 applications on a PC, it generates test cases and feeds to the target MCU and receives code coverage feedbacks via the debug dongle (i.e., a J-Link Probe). 
<!-- #### Run the target with IPEA-San

Once the firmware has been compiled with IPEA-San, the firmware can be executed with ``ipea-unittest`` program. It is responsible for:
- Downloading the firmware to the target MCU
- Boostrapping the MCU
- Receiving and analyzing the runtime trace of the firmware

Command line usage:

```Bash
$ run_unittest.py -b /path/to/firmware.elf -c /path/to/jlink.conf [-t <timeout>]
```

Arguments:

- `-b`: specify the path of firmware (ELF formant)
- `-c`: specify the configuration file path of J-Link and target MCU
- `-t`: specify the timeout in milliseconds (default is 1000 ms) -->


## Usage

#### Taming the firmware source code

This step needs the full knowledge of the firmware behavior. Here, we illustrate the generic procedure of taming the target source code.

1. Define the following global variables in the source code
    ```C
    /* used for receiving testcase */
    unsigned char DeviceTestCaseBuffer[2000] __attribute__((section(".noinit"))); 
    unsigned int TestCaseLen __attribute__((section(".noinit")));
    ```

2. Insert the following code in the fuzz start point
    ```C
    #include "fuzz.h"
    ...
    FuzzStart();
    ```
3. Insert the following code in the fuzz stop point
    ```C
    #include "fuzz.h"
    ...
    FuzzFinish();
    ```
4. Insert the following code in ``HardFault_Handler``
    ```C
    #include "fuzz.h"
    ...
    FuzzAbort();
    ```
5. Find the place in which receiving the input and add the following code. IPEA-Fuzz will inject test cases to `DeviceTestCaseBuffer`.
    ```C
    extern unsigned char DeviceTestCaseBuffer[];
    extern unsigned int TestCaseLen;
    ...
    // replace input_buf with the name of which used in the source code
    memcpy(input_buf, DeviceTestCaseBuffer, TestCaseLen);
    ```
6. Annotate functions that no need to be sanitized, such as system initialization (e.g., ``SystemInit()``) that invoked by the reset handler with ``__attribute__((annotate("no_instrument")))``.
7. Annotate interrupt handlers with `__attribute__((annotate("interruptHandler")))`.

#### Compile the firmware with IPEA-San

- Add following flags to ``Makefile`` and compile the firmware:
    ```lang-makefile
    CC = clang
    LD = arm-none-eabi-gcc
    ...
    CFLAGS += --target=arm-none-eabi
    CFLAGS += --sysroot=$(ARMGCC_DIR)/arm-none-eabi
    CFLAGS += -flegacy-pass-manager -Xclang -load -Xclang $(IPEA_HOME)/build/compiler-plugins/IPEA-San/ipea-san.so
    CFLAGS += -I$(IPEA_HOME)/include/target
    ...
    LDFLAGS += -L$(IPEA_HOME)/compiler-rt/build -lipea-rt
    ...
    ```

#### Hardware wiring

- For NXP FRDM-K64F, connect J-Link or J-Trace to Pin J9 with 10-pin cable.
- For STM32 Nucleo-F446RE, only onboard J-Link is avaliable since no debug port is present. To make ST-LINK compatible with J-Link onboard, please refer to this [link](https://www.segger.com/products/debug-probes/j-link/models/other-j-links/st-link-on-board/).
- For STM32H7B3I-EVAL, connect J-Link or J-Trace to Pin CN15 with 20-pin cable.

#### Start fuzzing

IPEA-Fuzz needs to collect target information from the ELF-format file and pass them to the fuzzer. Please use ``run_afl.py`` to run `ipea-fuzz`. 

```bash
$ run_afl.py -b /path/to/firmware.elf -c /path/to/jlink.conf -i /path/to/input -t <timeout>
```

Arguments:

- `-b`: specify the ELF-format firmware
- `-c`: specify the configuration file path of J-Link and target MCU
- `-i`: specify the path of inputs
- `-t`: specify the timeout in milliseconds

The fuzzing result will be saved in `output` directory.

#### Test a usecase

Please use `ipea-unittest` to run the firmware with a specific input. Command line usage:
```bash
$ cat output/crashes/<use_case_name> | run_unittest.py -b /path/to/firmware.elf -c /path/to/jlink.conf -t <timeout>
```

Arguments:

- `-b`: specify the path of firmware (ELF formant)
- `-c`: specify the configuration file path of J-Link and target MCU
- `-t`: specify the timeout in milliseconds (default is 1000 ms)

The runtime log would be saved as `tracelog_0.txt`. If a crash dected, the call stack information would be saved as `callstack.txt`.


## Artifact Evaluation

We claim "**Avaliable**" and "**Functional**" badges in NDSS'24 AE. If the required hardware (e.g., J-Link Probe and evaluation board) is unavailable, please login to our AE server in which all software and hardware dependencies are in place for the evaluation.

### IPEA-San Evaluation

`Toy` program accepts arbitrary strings. The input starting with the specific character will trigger different memory bugs:

- '`a`': Stack buffer overflow
- '`e`': Heap buffer overflow
- '`i`': Global buffer overflow
- '`o`': Use after free
- '`u`': Double free
- '`x`': Null pointer dereference
- '`y`': Peripheral-based buffer overflow
- '`z`': Sub-object buffer overflow

First off, build `Toy` program:

```bash
cd ${IPEA_HOME}/fw_samples/Toy
make ipea
```

Then, run `Toy` with a string input (e.g., '`axxxx`' which will trigger stack buffer overflow):

```bash
$ echo 'axxxx' | run_unittest.py -b toy -t 1000
```

**NOTE**: When running `ipea-unittest` (and `ipea-fuzz`), a pop-up window would appear to indicate the progress of firmware downloading.
If using a J-Link Edu/Edu mini/OB, you will be asked to agree the agreement of usage. 

Arguments:

- `-b`: the path of firmware
- `-t`: timeout in milliseconds

The output would look like:

```bash
global variable - name: of_global, addr: 0x1fff02b8, size: 16
global variable - name: DeviceTestCaseBuffer, addr: 0x1fff0098, size: 512
global variable - name: TestCaseLen, addr: 0x1fff0298, size: 4
global variable - name: s_uartHandle, addr: 0x1fff02c8, size: 24
global variable - name: s_uartIsr, addr: 0x1fff02e0, size: 4
taskset 0x1 ipea-unittest toy -c jlink.conf -t 1000
test case buffer length: 512
Target crashed
```

The detailed execution log can be found from `tracelog_0.txt`:

```bash
$ cat tracelog_0.txt

[2023-07-15 02:41:04.555] [init] [info] Assigned tag for global variable 'of_global': 0xabcd,  address: 0x1fff02b8, length: 16
[2023-07-15 02:41:04.555] [init] [info] Assigned tag for global variable 'DeviceTestCaseBuffer': 0xabce,  address: 0x1fff0098, length: 512
[2023-07-15 02:41:04.555] [init] [info] Assigned tag for global variable 'TestCaseLen': 0xabcf,  address: 0x1fff0298, length: 4
[2023-07-15 02:41:04.555] [init] [info] Assigned tag for global variable 's_uartHandle': 0xabd0,  address: 0x1fff02c8, length: 24
[2023-07-15 02:41:04.555] [init] [info] Assigned tag for global variable 's_uartIsr': 0xabd1,  address: 0x1fff02e0, length: 4
[2023-07-15 02:41:04.555] [init] [info] Assigned tag for global variable 'heap_end': 0xabd2,  address: 0x1fff02e4, length: 4
[2023-07-15 02:41:04.555] [AFL_RunTarget] [info] RTT initialized
[2023-07-15 02:41:04.557] [AFL_RunTarget] [info] Reach fuzz start point
[2023-07-15 02:41:04.558] [AFL_RunTarget] [info] Written testcase: 5 bytes
[2023-07-15 02:41:04.559] [AFL_RunTarget] [info] Target is running
[2023-07-15 02:41:04.560] [AFL_RunTarget] [info] Terminated. Execution time: 2 ms
[2023-07-15 02:41:04.562] [RTT_Decode] [debug] Total trace size: 69 bytes
[2023-07-15 02:41:04.562] [Subroutine] [debug] Assigned tag 0x55e99 for local variable 'of_stack' @ 0x2002ffe8
[2023-07-15 02:41:04.562] [Subroutine] [debug] Assigned tag 0x55ea1 for local variable 'of_heap' @ 0x2002ffe4
[2023-07-15 02:41:04.562] [Subroutine] [debug] Assigned tag 0x55ea9 for local variable 'flag' @ 0x2002ffe3
[2023-07-15 02:41:04.562] [handleFuncEntryStack] [debug] Enter function main, id = 0x6e9, stack_base = 0x2002fff8, stack_top = 0x2002ff88
[2023-07-15 02:41:04.562] [handleProp] [debug] Pointer propagation: from 0x0 to 0x2002ffe4 (tag = 0x0)
[2023-07-15 02:41:04.562] [handleRandom] [debug] Basic block random number: -16234 ( 0xc096 )
[2023-07-15 02:41:04.562] [handleMalloc] [debug] Allocated a heap object (size = 16) @ 0x20000008
[2023-07-15 02:41:04.562] [handleProp] [debug] Pointer propagation: from 0xffffffff to 0x2002ffe4 (tag = 0x55eb2)
[2023-07-15 02:41:04.562] [handleRandom] [debug] Basic block random number: 6249 ( 0x1869 )
[2023-07-15 02:41:04.562] [handleRandom] [debug] Basic block random number: 26920 ( 0x6928 )
[2023-07-15 02:41:04.562] [handleCheck] [info] Checking pointer dereference: pointer_id = 0x6002ffe8, address = 0x2002ffe8, length = 17
[2023-07-15 02:41:04.562] [handleCheck] [info] Stack buffer overflow detected @ 0x2002fff8, expected tag: 0x55e99, real tag: 0x0
[2023-07-15 02:41:04.562] [AFL_RunTarget] [info] Trace analysis result: 1
```


### IPEA-Fuzz Evaluation

By fuzz-testing `Toy` firmware, all the memory errors listed aboved should be captured (i.e., eight unique crashes). To start the fuzzing, run `ipea-fuzz` by:

```bash
$ run_afl.py -b toy -i ./fuzz_input -t 1000
```

Arguments:

- `-b`: the path of firmware
- `-i`: the path of initial seeds
- `-t`: timeout in milliseconds

Then, an AFL UI will appear on the terminal, press `Ctrl`+`C` to exit. The fuzzing results will be saved to `output` directory, please test a usecase with `ipea-unittest` by:

```bash
$ cat output/crashes/<use_case_name> | run_unittest.py -b toy -t 1000
```
The execution log can be found from `tracelog_0.txt`. If a crash detected, the call stack information will be saved to `callstack.txt`.

### Correctness Evaluation

Juliet C/C++ Testsuite is used for evaluating the correctness of sanitizers. 

- Enter the directory of Juliet project
    ```bash
    $ cd ${IPEA_HOME}/projects/MCU_Juliet_Testsuite
    ```
- Evaluate the correctness of IPEA-San
  
  **NOTE**: This experiment may take a long time. `--max-run=10` makes the script run only 10 programs.

    ```bash
    $ run_julite.py -p . -c mk64f.conf --max-run=10   # Test the correctness of IPEA-San
    ```

- Evaluate the correctness of ASan

  **NOTE**: This experiment may take a long time. `--max-run=10` makes the script run only 10 programs. 

    ```bash
    $ run_juliet.py -p . -c mk64f.conf --max-run=10 --uss-asan    # Test the correctness of ASan
    ```
The result (i.e., number of FPs and FNs in each CWE) will be saved as `report_ipea.json` and `report_asan.json` for IPEA-San and ASan respectively.

### Performance Evaluation

[BEEBS](https://github.com/mageec/beebs) is a set of benchmarks for measuring the performance of embedded systems.

- Enter the directory of BEEBS project
  ```bash
  $ cd ${IPEA_HOME}/projects/BEEBS
  ```

- Run BEEBS without sanitizers (baseline):
  
  ```bash
  $ run_beebs.py -p . -c mk64f.conf
  ```
  
- Run BEEBS with IPEA-San:

  ```bash
  $ run_beebs.py -p . -c mk64f.conf -s ipea
  ```
- Run BEEBS with ASan:
  
  ```bash
  $ run_beebs.py -p . -c mk64f.conf -s asan  
  ```

The result (the time-consumption of each program) will be saved as `report_none.json`, `report_ipea.json` and `report_asan.json` for baseline, IPEA-San and ASan respectively. Performance overhead of each sanitizer can be obtained by comparing the corresponding time-consumption with baseline.

### Fuzz-testing FRDM-K64F USB-Host Driver

This experiment needs to take over 24 hours.

```bash
$ cd ${IPEA_HOME}/fw_samples/USB-Host
$ make ipea
$ run_afl.py -b usb_host -i ./fuzz_input -t 3000
```
A use-after-free bug would be found. The fuzzing result can be found from `output` directory, please test a crash usecase with `ipea-unittest` tool as described in [IPEA-Fuzz Evaluation](#IPEA-Fuzz-Evaluation).