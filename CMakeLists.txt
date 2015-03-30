cmake_minimum_required(VERSION 2.6)
project(Beatr D)

set(Beatr_VERSION_MAJOR 0)
set(Beatr_VERSION_MINOR 1)

set(CMAKE_D_FLAGS_UNITTEST "-unittest -cov -gc -debug")
mark_as_advanced(CMAKE_D_FLAGS_UNITTEST)

add_subdirectory(src/3rdptylib)
add_subdirectory(src/beatr)
add_subdirectory(src/ui)

enable_testing()
add_test(NAME Tests COMMAND test-mfiles ${BEATR_TEST_DIR})
add_test(NAME Unittests COMMAND unittesting CONFIGURATIONS UNITTEST)
