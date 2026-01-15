cmake_minimum_required(VERSION 3.25)

project(PrestoFramework
    VERSION 0.2.0
    DESCRIPTION "A high-performance, extensible Sonic-style game framework in C23"
    HOMEPAGE_URL "https://github.com/Dubnium32x/Presto-Framework"
    LANGUAGES C
)

#generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(raylib REQUIRED)
find_package(PkgConfig REQUIRED) #used to find libmikmod
pkg_check_modules(mikmod REQUIRED libmikmod)

set(CMAKE_C_STANDARD 23)

set(PRESTO_BUILD_NAME "presto-framework")

if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    set(PRESTO_BUILD_NAME "presto-framework-debug")
endif()

file(GLOB_RECURSE PRESTO_SOURCE_FILES "${CMAKE_CURRENT_LIST_DIR}/src/*/*.c")

add_executable(${PRESTO_BUILD_NAME}
    "${CMAKE_CURRENT_LIST_DIR}/src/main.c"
    ${PRESTO_SOURCE_FILES}
)

target_include_directories(${PRESTO_BUILD_NAME} PUBLIC
    "${CMAKE_CURRENT_LIST_DIR}"
    "${CMAKE_CURRENT_LIST_DIR}/src"
    "${mikmod_INCLUDE_DIRS}"
)

target_link_libraries(${PRESTO_BUILD_NAME}
    c #glibc
    m #libm
    raylib
    ${mikmod_LIBRARIES}
)
