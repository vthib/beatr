add_executable(beatr-cli cli.d)
include_directories(.)
include_directories(../beatr)
include_directories(../3rdptylib)
target_link_libraries(beatr-cli
    beatr
    dfftw3 davcodec davutil davformat davresample
     fftw3  avcodec  avutil  avformat  avresample
)
