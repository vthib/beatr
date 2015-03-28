include_directories(. ../3rdptylib)
add_library(beatr
    analysis/analyzer.d analysis/scores.d

    audio/audiofile.d audio/audiostream.d audio/fft.d audio/fftutils.d
    audio/lpfilter.d audio/resampler.d

    chroma/chromabands.d chroma/chromaprofile.d

    exc/libavexception.d

    util/beatr.d util/note.d util/weighting.d util/window.d
)
