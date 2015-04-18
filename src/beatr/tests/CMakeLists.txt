set(INTERNAL_OBJECTS
    $<TARGET_OBJECTS:beatr>
	$<TARGET_OBJECTS:dfftw3>
	$<TARGET_OBJECTS:davcodec>
	$<TARGET_OBJECTS:davutil>
	$<TARGET_OBJECTS:davformat>
	$<TARGET_OBJECTS:davresample>
)

include_directories(.)
include_directories(../beatr)
include_directories(../3rdptylib)
add_executable(test-mfiles test_mfiles.d ${INTERNAL_OBJECTS})
add_executable(unittesting unittesting.d ${INTERNAL_OBJECTS})

set(BEATR_TEST_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE INTERNAL "directory of the tests")
