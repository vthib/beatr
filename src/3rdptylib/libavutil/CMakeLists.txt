include_directories(..)
add_library(davutil OBJECT
    attributes.d avconfig.d avutil.d buffer.d channel_layout.d
    common.d cpu.d dict.d error.d frame.d log.d macros.d mem.d
    opt.d pixfmt.d rational.d samplefmt.d version_.d
)
