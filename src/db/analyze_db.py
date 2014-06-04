#!/usr/bin/python

import sys
from subprocess import check_output
import locale

encoding = locale.getdefaultlocale()[1]


if len(sys.argv) < 2:
    print("need the database as first argument")
    sys.exit(1)

score={
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

total=0
match=0
dominant=0
rel=0

with open(sys.argv[1]) as f:
    for line in f:
        fld = line.rstrip().split("\t")
        key = fld[1].split(',')[0]
        try:
            output = check_output(["../cli/main", fld[0]])
        except:
            break
        foundkey = output.decode(encoding).split('\t')[1]
        print("{}: real: {}, found: {}".format(fld[0], key, foundkey))
        total += 1
        if score[foundkey] == score[key]:
            match += 1
            print("\tfound {} -> {}".format(fld[0], key))
            continue
        diff = abs(score[key] - score[foundkey]);
        same = (score[key] < 12 and score[foundkey] < 12) or (score[key] >= 12 and score[foundkey] >= 12)
        if (diff == 5 or diff == 7) and same:
            dominant += 1
            print("\tdom {} -> {}/{}".format(fld[0], key, foundkey))
        diff = diff % 12
        if (diff == 3 or diff == 9) and (not same):
            rel += 1
            print("\trel {} -> {}/{}".format(fld[0], key, foundkey))

print("{}/{} found, {} true, {} dominant, {} rel".format(match + dominant + rel, total,
                                                         match, dominant, rel))


