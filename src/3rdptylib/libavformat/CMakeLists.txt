include_directories(..)
add_library(davformat OBJECT
    avformat.d avio.d version_.d
)
