include_directories(.)
include_directories(../beatr)
include_directories(../3rdptylib)
set(LIBRARIES
    beatr
    dfftw3 davcodec davutil davformat davresample
     fftw3  avcodec  avutil  avformat  avresample
)

add_executable(beatr-cli cli.d)
target_link_libraries(beatr-cli ${LIBRARIES})

include_directories(/usr/include/d/gtkd-3)
add_executable(beatr-gui gui.d)
target_link_libraries(beatr-gui ${LIBRARIES} gtkd-3 dl)
