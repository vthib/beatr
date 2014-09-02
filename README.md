beatr
=====

/beatr/ is a musical key analyzer, returning the most plausible key of an audio track.

Simply execute `beatr audiofile` to get the key of the track as well as an indication of the confidence in the result.
Executing `beatr directory` will analyze every file in the directory.

Many options are available and are described in the help: `beatr -h`.

Execution examples
------------------

`beatr audiofile`: return best key

`beatr -d -c audiofile`: return debugging messages and spectogram of the track

`beatr --seconds 180 --scales 2:8 audiofile`: analyze only the first three minutes of the song between C2 and B7.

Compilation
-----------

/beatr/ requires a D2 compiler (tested with dmd 2.065), /libAV/ version >= 10.0, and /FFTW/ version >= 3.3.
A simple `make full` in directory src/cli will produce the executable `beatr`.

Compilation works in Windows, although the makefiles needs updating.