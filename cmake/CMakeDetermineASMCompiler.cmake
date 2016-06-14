set(CMAKE_ASM_COMPILER ${PROJECT_SOURCE_DIR}/cmake/qcc.sh)

configure_file(cmake/CMakeASMCompiler.cmake.in
        ${CMAKE_PLATFORM_INFO_DIR}/CMakeASMCompiler.cmake @ONLY)
set(CMAKE_ASM_COMPILER_ENV_VAR "QCC")
