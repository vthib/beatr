#!/usr/bin/python

import sys
import os
from subprocess import check_output
import locale
import getopt

encoding = locale.getdefaultlocale()[1]

print("i\treal\tuser\tsys");

with open(sys.argv[1]) as f:
    line = f.readline()
    while line != '':
        i = int(line)
        r = float(f.readline().split(" ")[1])
        u = float(f.readline().split(" ")[1])
        s = float(f.readline().split(" ")[1])
        print("{}\t{}\t{}\t{}".format(i, r, u, s))
        line = f.readline()

