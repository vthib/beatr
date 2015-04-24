include_directories(.)
include_directories(../beatr)
include_directories(../3rdptylib)
set(INTERNAL_OBJECTS
    $<TARGET_OBJECTS:beatr>
	$<TARGET_OBJECTS:dfftw3>
	$<TARGET_OBJECTS:davcodec>
	$<TARGET_OBJECTS:davutil>
	$<TARGET_OBJECTS:davformat>
	$<TARGET_OBJECTS:davresample>
)

find_library(FFTW_LIB fftw3 PATHS win)
find_library(AVCODEC_LIB avcodec PATHS win)
find_library(AVUTIL_LIB avutil PATHS win)
find_library(AVFORMAT_LIB avformat PATHS win)
find_library(AVRESAMPLE_LIB avresample PATHS win)
find_library(GTKD_LIB gtkd-3 PATHS win)
find_library(ID3_LIB id3 PATHS win)

set(LIBRARIES ${FFTW_LIB} ${AVCODEC_LIB} ${AVUTIL_LIB} ${AVFORMAT_LIB} ${AVRESAMPLE_LIB})
set(GUILIBRARIES ${LIBRARIES} ${GTKD_LIB} ${ID3_LIB})

if (WIN32)
    set(CMAKE_D_LINK_LIBRARY_FILE_FLAG "-L+")
else()
    find_library(DL_LIB dl)
    include_directories(/usr/include/d/gtkd-3)
    set(GUILIBRARIES ${GUILIBRARIES} ${DL_LIB})
endif()

add_executable(beatr-cli cli.d ${INTERNAL_OBJECTS})
target_link_libraries(beatr-cli ${LIBRARIES})

add_executable(beatr-gui gui.d ${INTERNAL_OBJECTS} $<TARGET_OBJECTS:did3lib>)
target_link_libraries(beatr-gui ${GUILIBRARIES})
