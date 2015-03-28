cmake_minimum_required(VERSION 2.6)
project(Beatr D)

set(Beatr_VERSION_MAJOR 0)
set(Beatr_VERSION_MINOR 1)

add_subdirectory(src/3rdptylib)
add_subdirectory(src/beatr)
add_subdirectory(src/cli)

