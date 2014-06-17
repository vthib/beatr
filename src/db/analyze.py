#!/usr/bin/python

import sys
import os
import subprocess
from subprocess import check_output
import locale
import getopt

encoding = locale.getdefaultlocale()[1]

# C -> B major : 0 -> 11
# C -> B minor : 12 -> 23
k2i={
    "Cmaj": 0, "C": 0,
    "C#maj": 1, "C#": 1, "Dbmaj": 1, "Db": 1,
    "Dmaj": 2, "D": 2,
    "D#maj": 3, "D#": 3, "Ebmaj": 3, "Eb": 3,
    "Emaj": 4, "E": 4,
    "Fmaj": 5, "F": 5,
    "F#maj": 6, "F#": 6, "Gbmaj": 6, "Gb": 6,
    "Gmaj": 7, "G": 7,
    "G#maj": 8, "G#": 8, "Abmaj": 8, "Ab": 8,
    "Amaj": 9, "A": 9,
    "A#maj": 10, "A#": 10, "Bbmaj": 10, "Bb": 10,
    "Bmaj": 11, "B": 11,
    "Cmin": 12, "Cm": 12,
    "C#min": 13, "C#m": 13, "Dbmin": 13, "Dbm": 13,
    "Dmin": 14, "Dm": 14,
    "D#min": 15, "D#m": 15, "Ebmin": 15, "Ebm": 15,
    "Emin": 16, "Em": 16,
    "Fmin": 17, "Fm": 17,
    "F#min": 18, "F#m": 18, "Gbmin": 18, "Gbm": 18,
    "Gmin": 19, "Gm": 19,
    "G#min": 20, "G#m": 20, "Abmin": 20, "Abm": 20,
    "Amin": 21, "Am": 21,
    "A#min": 22, "A#m": 22, "Bbmin": 22, "Bbm": 22,
    "Bmin": 23, "Bm": 23
}

def print_help(name):
    print('usage:\n\t{} -d dbfile -i files [beatr arguments...]'.format(name))
    print('\n\tOptions:')
    print('\t\t-h: print this help message')
    print('\t\t-d dbfile: get the database from \'dbfile\', default is stdin')
    print('\t\t-i files: analyze the files given')
    print('\t\t-o output: write results to file \'output\', default is stdout')
    print('\t\t-v: verbose: write detection mismatch')
    print('\t\t-q: quiet: only write final score')

class Stats:
    def __init__(self):
        # Score is computed like this (from MIREX)
        #  Perfect match : 1.0
        #  Dom/Sub-Dom   : 0.5
        #  Relative      : 0.3
        #  Parallel      : 0.2
        self.score = 0.0

        self.total = 0 # number of files tested
        self.match = 0 # number of exact matches
        self.dominant = 0 # number of dominant or sub-dominant found instead
        self.relative = 0 # number of relative major/minor found instead
        self.parallel = 0 # number of parallel major/minor found instead 

        self.fout = sys.stdout
        self.quiet = False
        self.verbose = False

    def updateStats(self, f, dbkey, foundkey):
        diff = abs(k2i[dbkey] - k2i[foundkey]);
        same = (k2i[dbkey] < 12 and k2i[foundkey] < 12) or (k2i[dbkey] >= 12 and k2i[foundkey] >= 12)

        self.total += 1

        if diff == 0: # perfect match
            self.match += 1
            self.score += 1.0
            if not self.quiet:
                print("fnd {} -> {}".format(f, dbkey), file=self.fout)
        elif (diff == 5 or diff == 7) and same: # dominant or sub-dominant
            self.dominant += 1
            self.score += 0.5
            if not self.quiet:
                print("dom {} -> {}/{}".format(f, dbkey, foundkey), file=self.fout)
        elif diff == 12: # parallel
            self.parallel += 1
            self.score += 0.2
            if not self.quiet:
                print("par {} -> {}/{}".format(f, dbkey, foundkey), file=self.fout)
        else:
            diff = diff % 12
            if (diff == 3 or diff == 9) and (not same): # relative
                self.relative += 1
                self.score += 0.3
                if not self.quiet:
                    print("rel {} -> {}/{}".format(f, dbkey, foundkey), file=self.fout)
            elif self.verbose:
                print("err {} -> {} expected, found {}".format(f, dbkey, foundkey), file=self.fout)

    def printStats(self):
        print("{}/{}:".format(self.match + self.dominant + self.relative + self.parallel, self.total)
              + " {} match, {} dom, {} rel, {} par".format(self.match, self.dominant, self.relative, self.parallel),
              file=self.fout)
        if self.total != 0:
            self.score /= self.total
        print("score: {}".format(self.score), file=self.fout)

def db2dict(file):
    map = {}
    for line in file:
        # database is filled with "filename\tkey"
        fld = line.rstrip().split("\t")
        key = fld[1].split(',')[0]

        map[os.path.splitext(fld[0])[0].rstrip().lower()] = key

    return map

def getBeatrKey(file, args):
    try:
        output = check_output(["../cli/beatr"] + args + [file])
        return output.decode(encoding).split('\t')[1]
    except subprocess.CalledProcessError as err:
        print("error: {}".format(err))
        sys.exit(5)

def analyzeFile(file, prefix, map, stats):
    if os.path.isdir(prefix + "/" + file):
        for f in os.listdir(prefix + "/" + file):
            if file == "":
                analyzeFile(f, prefix, map, stats)
            else:
                analyzeFile(file + "/" + f, prefix, map, stats)
    else:
        fnorm = os.path.splitext(file)[0].strip().lower()

        if fnorm not in map:
            print("{} not in database".format(fnorm))
            return
            #sys.exit(4)

        key = map[fnorm]

        # get the computed key, passing leftover arguments
        foundkey = getBeatrKey(prefix + "/" + file, args)

        stats.updateStats(fnorm, key, foundkey)

fin = sys.stdin
files=False
stats = Stats()

try:
    opts, args = getopt.getopt(sys.argv[1:], 'hi:o:d:vq')
except getopt.GetOptError:
    print_help(sys.argv[0])
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print_help(sys.argv[0])
        sys.exit(0)
    elif opt == '-d':
        fin = open(arg, 'r') # may throw exception
    elif opt == '-o':
        stats.fout = open(arg, 'w') # may throw exception
    elif opt == '-i':
        files = arg
    elif opt == '-v':
        stats.verbose=True
        stats.quiet=False
    elif opt == '-q':
        stats.verbose=False
        stats.quiet=True

if not files:
    print_help(sys.argv[0])
    sys.exit(3)

map = db2dict(fin)

try:
    analyzeFile("", files, map, stats)
except KeyboardInterrupt:
    pass

stats.printStats()

if fin != sys.stdin:
    fin.close()
if stats.fout != sys.stdout:
    stats.fout.close()
