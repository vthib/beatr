#!/bin/sh

if [ $# -lt 1 ]; then
	echo "need output argument";
	exit
fi

rm -f $1
touch $1

for i in db/*; do
	sed -e 's/&#9839;/#/' $i >> $1
done

sed -ie 's/^\(.*\)\t\(.*\)\t\(.*\)\t\(.*\)/\1\/\2.mp3\t\4/' $1
