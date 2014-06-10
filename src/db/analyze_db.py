#!/usr/bin/python

import sys
from subprocess import check_output
import locale
import getopt

encoding = locale.getdefaultlocale()[1]

# C -> B major : 0 -> 11
# C -> B minor : 12 -> 23
k2i={
    "Cmaj": 0, "Cmin": 12,
    "C#maj": 1, "C#min": 13, "Dbmaj": 1, "Dbmin": 13,
    "Dmaj": 2, "Dmin": 14,
    "D#maj": 3, "D#min": 15, "Ebmaj": 3, "Ebmin": 15,
    "Emaj": 4, "Emin": 16,
    "Fmaj": 5, "Fmin": 17,
    "F#maj": 6, "F#min": 18, "Gbmaj": 6, "Gbmin": 18,
    "Gmaj": 7, "Gmin": 19,
    "G#maj": 8, "G#min": 20, "Abmaj": 8, "Abmin": 20,
    "Amaj": 9, "Amin": 21,
    "A#maj": 10, "A#min": 22, "Bbmaj": 10, "Bbmin": 22,
    "Bmaj": 11, "Bmin": 23,
}

def print_help(name):
    print('usage:\n\t{} -i dbfile [options] [beatr arguments...]'.format(name))
    print('\n\tOptions:')
    print('\t\t-h: print this help message')
    print('\t\t-i dbfile: get the database from \'dbfile\', default is stdin')
    print('\t\t-o output: write results to file \'output\', default is stdout')
    print('\t\t-v: verbose: write detection mismatch')
    print('\t\t-q: quiet: only write final score')

fin = sys.stdin
fout = sys.stdout
verbose=False
quiet=False
try:
    opts, args = getopt.getopt(sys.argv[1:], 'hi:o:vq')
except getopt.GetOptError:
    print_help(sys.argv[0])
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print_help(sys.argv[0])
        sys.exit(0)
    elif opt == '-i':
        fin = open(arg, 'r') # may throw exception
    elif opt == '-o':
        fout = open(arg, 'w') # may throw exception
    elif opt == '-v':
        verbose=True
        quiet=False
    elif opt == '-q':
        verbose=False
        quiet=True

total=0 # number of files tested
match=0 # number of exact matches
dominant=0 # number of dominant or sub-dominant found instead
relative=0 # number of relative major/minor found instead
parallel=0 # number of parallel major/minor found instead 

# Score is computed like this (from MIREX)
#  Perfect match : 1.0
#  Dom/Sub-Dom   : 0.5
#  Relative      : 0.3
#  Parallel      : 0.2
score=0.0

for line in fin:
    # database is filled with "filename\tkey"
    fld = line.rstrip().split("\t")
    key = fld[1].split(',')[0]

    # get the computed key, passing leftover arguments
    try:
        output = check_output(["../cli/beatr"] + args + [fld[0]])
    except:
        break # on error (or signal), stop

    foundkey = output.decode(encoding).split('\t')[1]
    total += 1

    diff = abs(k2i[key] - k2i[foundkey]);
    same = (k2i[key] < 12 and k2i[foundkey] < 12) or (k2i[key] >= 12 and k2i[foundkey] >= 12)

    if diff == 0: # perfect match
        match += 1
        score += 1.0
        if not quiet:
            print("fnd {} -> {}".format(fld[0], key), file=fout)
    elif (diff == 5 or diff == 7) and same: # dominant or sub-dominant
        dominant += 1
        score += 0.5
        if not quiet:
            print("dom {} -> {}/{}".format(fld[0], key, foundkey), file=fout)
    elif diff == 12: # parallel
        parallel += 1
        score += 0.2
        if not quiet:
            print("par {} -> {}/{}".format(fld[0], key, foundkey), file=fout)
    else:
        diff = diff % 12
        if (diff == 3 or diff == 9) and (not same): # relative
            relative += 1
            score += 0.3
            if not quiet:
                print("rel {} -> {}/{}".format(fld[0], key, foundkey), file=fout)
        elif verbose:
            print("err {} -> {} found, not {}".format(fld[0], foundkey, key), file=fout)

print("{}/{}:".format(match + dominant + relative + parallel, total)
      + " {} match, {} dom, {} rel, {} par".format(match, dominant, relative, parallel),
      file=fout)
score /= total
print("score: {}".format(score), file=fout)

if fin != sys.stdin:
    fin.close()
if fout != sys.stdout:
    fout.close()
