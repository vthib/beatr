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

set(STATIC_LIB "TRUE" CACHE BOOLEAN "Use static libraries") 
if (STATIC_LIB)
    find_library(FFTW_LIB fftw3 PATHS static NO_DEFAULT_PATH)

    find_library(AVRESAMPLE_LIB avresample PATHS static NO_DEFAULT_PATH)
    find_library(AVFORMAT_LIB avformat PATHS static NO_DEFAULT_PATH)
    find_library(AVCODEC_LIB avcodec PATHS static NO_DEFAULT_PATH)
    find_library(AVUTIL_LIB avutil PATHS static NO_DEFAULT_PATH)
    if (!WIN32)
        find_library(BZ2_LIB bz2)
        set (LIBRARIES ${LIBRARIES} ${BZ2_LIB})
    endif()
    find_library(GTKD_LIB gtkd-3 PATHS static NO_DEFAULT_PATH)
else()
    find_library(FFTW_LIB fftw3 PATHS static)

    find_library(AVRESAMPLE_LIB avresample PATHS static)
    find_library(AVFORMAT_LIB avformat PATHS static)
    find_library(AVCODEC_LIB avcodec PATHS static)
    find_library(AVUTIL_LIB avutil PATHS static)

    find_library(GTKD_LIB gtkd-3 PATHS static)
endif()

find_library(ID3_LIB id3 PATHS static)

set (LIBRARIES ${LIBRARIES} ${FFTW_LIB} ${AVRESAMPLE_LIB} ${AVFORMAT_LIB} ${AVCODEC_LIB} ${AVUTIL_LIB})
set(GUILIBRARIES ${LIBRARIES} ${GTKD_LIB} ${ID3_LIB})

if (WIN32)
    set(CMAKE_D_LINK_LIBRARY_FILE_FLAG "-L+")
else()
    find_library(DL_LIB dl PATHS static)
    include_directories(/usr/include/d/gtkd-3)
    set(GUILIBRARIES ${GUILIBRARIES} ${DL_LIB})
endif()

add_executable(beatr-cli cli.d ${INTERNAL_OBJECTS} ${STATIC_FILES})
target_link_libraries(beatr-cli ${LIBRARIES})

add_executable(beatr-gui gui.d ${INTERNAL_OBJECTS} $<TARGET_OBJECTS:did3lib> ${STATIC_FILES})
target_link_libraries(beatr-gui ${GUILIBRARIES})
