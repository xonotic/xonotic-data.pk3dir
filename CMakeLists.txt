cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
project(xonotic-data ASM)

set(all qc-all)
add_custom_target(${all})

set(checks qc-checks)
add_custom_target(${checks})

if (gmqcc_BINARY_DIR)
    set(compilerinfo "${gmqcc_BINARY_DIR}/gmqcc.h")
    add_custom_command(
            OUTPUT "${compilerinfo}"
            DEPENDS "${gmqcc_BINARY_DIR}/gmqcc"
            VERBATIM
            COMMAND ${CMAKE_COMMAND} -E
                md5sum "${gmqcc_BINARY_DIR}/gmqcc" > "${compilerinfo}"
            )
    add_custom_target(qcc ALL
            DEPENDS "${compilerinfo}"
            )
endif ()

add_dependencies(${checks} data-check-cvars)
add_custom_target(data-check-cvars
        COMMENT "checking cvars"
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
        VERBATIM COMMAND ${CMAKE_COMMAND} -E
        env "CMAKE=1"
        "${PROJECT_SOURCE_DIR}/check-cvars.sh"
        )

add_dependencies(${checks} qc-genmod)
add_custom_target(qc-genmod
        COMMENT "genmod.sh"
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/qcsrc"
        VERBATIM COMMAND ./tools/genmod.sh
        )

add_dependencies(${checks} qc-headerstyle)
add_custom_target(qc-headerstyle
        COMMENT "headerstyle.sh"
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/qcsrc"
        VERBATIM COMMAND ${CMAKE_COMMAND} -E
        env "VERBOSE=0"
        ./tools/headerstyle.sh
        )

add_dependencies(${checks} qc-whitespace)
add_custom_target(qc-whitespace
        COMMENT "whitespace.sh"
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/qcsrc"
        VERBATIM COMMAND ./tools/whitespace.sh
        )

function(prog name dir)
    add_executable(${name} qcsrc/${dir}/progs.inc)
    add_dependencies(${all} ${name})
    add_dependencies(${name} ${checks})
    add_dependencies(${name} qcc)
    set_source_files_properties(qcsrc/${dir}/progs.inc PROPERTIES OBJECT_DEPENDS "${compilerinfo}")
endfunction()

function(set_prelude target prelude)
    get_target_property(MY_PROJECT_SOURCES ${target} SOURCES)
    foreach (source IN LISTS MY_PROJECT_SOURCES)
        set_property(
                SOURCE ${source}
                APPEND PROPERTY COMPILE_FLAGS
                "-include ${prelude}"
        )
    endforeach ()
endfunction()

include_directories(qcsrc)

add_definitions(-DXONOTIC=1)
add_definitions(-DNDEBUG=1)
add_definitions(-DENABLE_EFFECTINFO=0)
add_definitions(-DENABLE_DEBUGDRAW=0)
add_definitions(-DENABLE_DEBUGTRACE=0)

if (DEFINED ENV{VERSION})
    set(GIT_DESC "$ENV{VERSION}")
else ()
    find_package(Git REQUIRED)
    execute_process(
            COMMAND ${GIT_EXECUTABLE} describe --tags --dirty=~
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_DESC
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
endif ()
add_definitions(-DWATERMARK=\"${GIT_DESC}\")

set_source_files_properties(
        qcsrc/client/progs.inc
        qcsrc/server/progs.inc
        qcsrc/menu/progs.inc
        PROPERTIES
        LANGUAGE ASM
        HEADER_FILE_ONLY FALSE
)

prog(csprogs client)
target_compile_definitions(csprogs PRIVATE -DGAMEQC -DCSQC)
# set_prelude(csprogs "${PROJECT_SOURCE_DIR}/qcsrc/lib/_all.inc")

prog(progs server)
target_compile_definitions(progs PRIVATE -DGAMEQC -DSVQC)

prog(menu menu)
target_compile_definitions(menu PRIVATE -DMENUQC)

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
    add_custom_target(${prog}.pk3 ALL
            DEPENDS ${prog}-${GIT_DESC}.pk3
            )
    add_custom_command(OUTPUT ${prog}-${GIT_DESC}.pk3
            DEPENDS ${prog}
            COMMAND ${CMAKE_COMMAND} -E echo "https://xonotic.org" > "${prog}-${GIT_DESC}.txt"
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
