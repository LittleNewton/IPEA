# TOOLCHAIN EXTENSION
IF(WIN32)
    SET(TOOLCHAIN_EXT ".exe")
ELSE()
    SET(TOOLCHAIN_EXT "")
ENDIF()

# EXECUTABLE EXTENSION
SET (CMAKE_EXECUTABLE_SUFFIX ".elf")

# IPEA WORK DIRECTORY
SET(IPEA_WORKDIR $ENV{IPEA_HOME})

IF (NOT IPEA_WORKDIR)
    MESSAGE(FATAL_ERROR "***Please set IPEA_HOME in environment vairables***")
ENDIF()

# ASAN FLAGS
SET(ASAN_FLAGS "-DUSE_ASAN=1 -fsanitize=kernel-address --param asan-globals=1 --param asan-stack=1 -fasan-shadow-offset=0x1c02a000")
SET(CMAKE_EXE_LINKER_FLAGS_DEBUG " \
    ${CMAKE_EXE_LINKER_FLAGS_DEBUG} \
    -Wl,--wrap=malloc \
    -Wl,--wrap=free \
    -Wl,--wrap=memcpy \
    -Wl,--wrap=memmove \
    -Wl,--wrap=memset \
    -Wl,--wrap=strcpy \
    -Wl,--wrap=strncpy \
    -Wl,--wrap=strcat \
    -Wl,--wrap=strncat \
    -Wl,--wrap=sprintf \
    -Wl,--wrap=snprintf \
")

SET(CMAKE_EXE_LINKER_FLAGS_RELEASE " \
    ${CMAKE_EXE_LINKER_FLAGS_RELEASE} \
    -Wl,--wrap=malloc \
    -Wl,--wrap=free \
    -Wl,--wrap=memcpy \
    -Wl,--wrap=memmove \
    -Wl,--wrap=memset \
    -Wl,--wrap=strcpy \
    -Wl,--wrap=strncpy \
    -Wl,--wrap=strcat \
    -Wl,--wrap=strncat \
    -Wl,--wrap=sprintf \
    -Wl,--wrap=snprintf \
")

# TOOLCHAIN_DIR AND NANO LIBRARY
SET(TOOLCHAIN_DIR $ENV{ARMGCC_DIR})
STRING(REGEX REPLACE "\\\\" "/" TOOLCHAIN_DIR "${TOOLCHAIN_DIR}")

IF(NOT TOOLCHAIN_DIR)
    MESSAGE(FATAL_ERROR "***Please set ARMGCC_DIR in envionment variables***")
ENDIF()

MESSAGE(STATUS "TOOLCHAIN_DIR: " ${TOOLCHAIN_DIR})

# TARGET_TRIPLET
SET(TARGET_TRIPLET "arm-none-eabi")

SET(TOOLCHAIN_BIN_DIR ${TOOLCHAIN_DIR}/bin)
SET(TOOLCHAIN_INC_DIR ${TOOLCHAIN_DIR}/${TARGET_TRIPLET}/include)
SET(TOOLCHAIN_LIB_DIR ${TOOLCHAIN_DIR}/${TARGET_TRIPLET}/lib)

SET(CMAKE_SYSTEM_NAME Generic)
SET(CMAKE_SYSTEM_PROCESSOR arm)

SET(CMAKE_C_COMPILER ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-gcc${TOOLCHAIN_EXT})
SET(CMAKE_CXX_COMPILER ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-g++${TOOLCHAIN_EXT})
SET(CMAKE_ASM_COMPILER ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-gcc${TOOLCHAIN_EXT})

set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

SET(CMAKE_OBJCOPY ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-objcopy CACHE INTERNAL "objcopy tool")
SET(CMAKE_OBJDUMP ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-objdump CACHE INTERNAL "objdump tool")

SET(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${ASAN_FLAGS} -O0 -g" CACHE INTERNAL "c compiler flags debug")
SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${ASAN_FLAGS} -O0 -g" CACHE INTERNAL "cxx compiler flags debug")
SET(CMAKE_ASM_FLAGS_DEBUG "${CMAKE_ASM_FLAGS_DEBUG} -g" CACHE INTERNAL "asm compiler flags debug")
SET(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG}" CACHE INTERNAL "linker flags debug")

SET(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${ASAN_FLAGS} -O3 " CACHE INTERNAL "c compiler flags release")
SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${ASAN_FLAGS} -O3 " CACHE INTERNAL "cxx compiler flags release")
SET(CMAKE_ASM_FLAGS_RELEASE "${CMAKE_ASM_FLAGS_RELEASE}" CACHE INTERNAL "asm compiler flags release")
SET(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}" CACHE INTERNAL "linker flags release")

include_directories(${IPEA_WORKDIR}/include)
include_directories(${IPEA_WORKDIR}/include/target)
include_directories(${IPEA_WORKDIR}/projects/MCU_ASAN)

link_directories(${IPEA_WORKDIR}/projects/MCU_ASAN)
link_directories(${IPEA_WORKDIR}/compiler-rt/build)

SET(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN_DIR}/${TARGET_TRIPLET} ${EXTRA_FIND_PATH})
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

MESSAGE(STATUS "BUILD_TYPE: " ${CMAKE_BUILD_TYPE})