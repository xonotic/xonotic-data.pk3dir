set(CMAKE_BUILD_TYPE "Debug")

set(ENGINE_EXE_NAME "xonotic" CACHE STRING "What do you want to name the engine executable? If unsure, leave this default. Default = horsepower")

set(ENGINE_VERSION "${HP_REV}" CACHE STRING "Set engine version string. If unsure, leave this blank. Default = SHA of HEAD")

set(ENGINE_WINRC "" CACHE STRING "Location of Windows resource file. If unsure, leave this blank. Default = <blank>")

option(ENGINE_CONFIG_MENU "Compile the engine with legacy menu support. Required for Quake and any mods that use the legacy menu. If unsure or you're gonna play Quake or mods built for Quake, turn this on. Default = ON" ON)

option(ENGINE_CONFIG_CD "Compile the engine with CD audio support. Required if you intend to have in-game music at all, even if you don't use CDs. Default = ON" ON)

option(ENGINE_NO_BUILD_TIMESTAMPS "Disable build timestamps in the version string. Default = OFF" OFF)
