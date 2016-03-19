cmake_minimum_required(VERSION 2.8.11)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
project(xonotic-data LANGUAGES ASM)

add_definitions(-DWATERMARK=\"12345\")
add_definitions(-DNDEBUG=1)
include_directories(qcsrc)

set_source_files_properties(
        qcsrc/client/progs.inc
        qcsrc/server/progs.inc
        qcsrc/menu/progs.inc
        PROPERTIES
        LANGUAGE ASM
        HEADER_FILE_ONLY FALSE
)

add_executable(csprogs qcsrc/client/progs.inc)
target_compile_definitions(csprogs PRIVATE -DCSQC)

add_executable(progs qcsrc/server/progs.inc)
target_compile_definitions(progs PRIVATE -DSVQC)

add_executable(menu qcsrc/menu/progs.inc)
target_compile_definitions(menu PRIVATE -DMENUQC)
