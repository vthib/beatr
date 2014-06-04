#!/usr/bin/python

import sys
from subprocess import check_output
import locale

encoding = locale.getdefaultlocale()[1]


if len(sys.argv) < 2:
    print("need the database as first argument")
    sys.exit(1)

total=0
match=0
dominant=0

keys={}

score={
    "Cmaj": 0, "Cmin": 0,
    "C#maj": 1, "C#min": 1, "Dbmaj": 1, "Dbmin": 1,
    "Dmaj": 2, "Dmin": 2,
    "D#maj": 3, "D#min": 3, "Ebmaj": 3, "Ebmin": 3,
    "Emaj": 4, "Emin": 4,
    "Fmaj": 5, "Fmin": 5,
    "F#maj": 6, "F#min": 6, "Gbmaj": 6, "Gbmin": 6,
    "Gmaj": 7, "Gmin": 7,
    "G#maj": 8, "G#min": 8, "Abmaj": 8, "Abmin": 8,
    "Amaj": 9, "Amin": 9,
    "A#maj": 10, "A#min": 10, "Bbmaj": 10, "Bbmin": 10,
    "Bmaj": 11, "Bmin": 11,
}

with open(sys.argv[1]) as f:
    for line in f:
        fld = line.rstrip().split("\t")
        key = fld[1].split(',')[0]
        output = check_output(["../cli/main", "/media/music2mix/{}".format(fld[0])])
        foundkey = output.decode(encoding).split('\t')[1]
        print("{}: real: {}, found: {}".format(fld[0], key, foundkey))
        total += 1
        if foundkey == key:
            match += 1
            print("found {} -> {}".format(fld[0], key))
            continue
        diff = (score[key] + score[foundkey]) % 12
        if diff == 3 or diff == 9:
            dominant += 1
            print("dom {} -> {}/{}".format(fld[0], key, foundkey))

print("{}/{} found, {} true, {} dominant".format(match + dominant, total,
                                                 match, dominant))


