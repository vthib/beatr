add_executable(test-mfiles test_mfiles.d)
add_executable(unittesting unittesting.d)
include_directories(.)
include_directories(../beatr)
include_directories(../3rdptylib)
set(LIBRARIES
    beatr
    dfftw3 davcodec davutil davformat davresample
     fftw3  avcodec  avutil  avformat  avresample
)
set(BEATR_TEST_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE INTERNAL "directory of the tests")
target_link_libraries(test-mfiles ${LIBRARIES})
target_link_libraries(unittesting ${LIBRARIES})
