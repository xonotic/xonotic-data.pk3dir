cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
project(xonotic-data ASM)

set(all qc-all)
add_custom_target(${all})

set(checks qc-checks)
add_custom_target(${checks})

# depend on qcc
if (TARGET gmqcc)
    add_dependencies(${checks} gmqcc)
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

add_executable(csprogs qcsrc/client/progs.inc)
add_dependencies(${all} csprogs)
add_dependencies(csprogs ${checks})
target_compile_definitions(csprogs PRIVATE -DGAMEQC -DCSQC)

add_executable(progs qcsrc/server/progs.inc)
add_dependencies(${all} progs)
add_dependencies(progs ${checks})
target_compile_definitions(progs PRIVATE -DGAMEQC -DSVQC)

add_executable(menu qcsrc/menu/progs.inc)
add_dependencies(${all} menu)
add_dependencies(menu ${checks})
target_compile_definitions(menu PRIVATE -DMENUQC)

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
