cmake_minimum_required(VERSION 3.25)
project(sccache-demo VERSION 1.0.0)

find_program(SCCACHE sccache REQUIRED)
set(CMAKE_C_COMPILER_LAUNCHER ${SCCACHE})
set(CMAKE_CXX_COMPILER_LAUNCHER ${SCCACHE})
set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT Embedded)
cmake_policy(SET CMP0141 NEW)

add_executable(sccache-demo
    main.cpp
    a.cpp
    b.cpp
    c.cpp
)
