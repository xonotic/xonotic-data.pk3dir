cmake_minimum_required(VERSION 2.8.11)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
project(xonotic-data LANGUAGES ASM)

include_directories(qcsrc)

add_definitions(-DXONOTIC=1)
add_definitions(-DNDEBUG=1)

find_package(Git REQUIRED)
execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --tags --dirty=~
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_DESC
        OUTPUT_STRIP_TRAILING_WHITESPACE
)
add_definitions(-DWATERMARK=\"${GIT_DESC}\")

set_source_files_properties(
        qcsrc/client/progs.inc
        qcsrc/server/progs.inc
        qcsrc/menu/progs.inc
        PROPERTIES
        LANGUAGE ASM
        HEADER_FILE_ONLY FALSE
)

add_executable(csprogs qcsrc/client/progs.inc)
target_compile_definitions(csprogs PRIVATE -DGAMEQC -DCSQC)
add_dependencies(csprogs gmqcc)

add_executable(progs qcsrc/server/progs.inc)
target_compile_definitions(progs PRIVATE -DGAMEQC -DSVQC)
add_dependencies(progs gmqcc)

add_executable(menu qcsrc/menu/progs.inc)
target_compile_definitions(menu PRIVATE -DMENUQC)
add_dependencies(menu gmqcc)

function(set_prelude target prelude)
    get_target_property(MY_PROJECT_SOURCES target SOURCES)
    foreach (source IN LISTS MY_PROJECT_SOURCES)
        set_property(
                SOURCE ${source}
                APPEND PROPERTY COMPILE_FLAGS
                "-include ${PROJECT_SOURCE_DIR}/${prelude}"
        )
    endforeach ()
endfunction()
# set_prelude(csprogs qcsrc/lib/_all.inc)

function(copy prog)
    add_custom_command(TARGET ${prog} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE_DIR:${prog}>/${prog}.dat" "${prog}.dat"
            COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE_DIR:${prog}>/${prog}.lno" "${prog}.lno"
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
            VERBATIM)
endfunction()
copy(csprogs)
copy(progs)
copy(menu)

function(pack prog)
    add_custom_target(${prog}.pk3
            DEPENDS ${prog}-${GIT_DESC}.pk3
            )
    add_custom_command(OUTPUT ${prog}-${GIT_DESC}.pk3
            DEPENDS ${prog}
            COMMAND ${CMAKE_COMMAND} -E echo "http://xonotic.org" > "${prog}-${GIT_DESC}.txt"
            COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE_DIR:${prog}>/${prog}.dat" "${prog}-${GIT_DESC}.dat"
            COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE_DIR:${prog}>/${prog}.lno" "${prog}-${GIT_DESC}.lno"
            COMMAND ${CMAKE_COMMAND} -E tar "cfv" "${prog}-${GIT_DESC}.pk3" --format=zip
            "${prog}-${GIT_DESC}.txt"
            "${prog}-${GIT_DESC}.dat"
            "${prog}-${GIT_DESC}.lno"
            VERBATIM
            )
endfunction()
pack(csprogs)
