#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Compiles the .tex file associated with the specified citation key in CK's BibBir and creates a <citation-key>.tex.pdf PDF file for it in the BibDir"
    echo
    echo "Usage: $0 <citation-key>"
    exit 0
fi

which ck &>/dev/null || { echo "ERROR: ck is not installed!"; exit 1; }
which latexmk &>/dev/null || { echo "ERROR: latexmk is not installed!"; exit 1; }

ck=$1
bibdir=$(cat "`ck config`" | grep BibDir | cut -f 2 -d=)
#tex=$bibdir/$ck
tex=$ck.tex
tmpdir=`mktemp -d`

bibdir=`greadlink -f $bibdir`
if [ ! -d "$bibdir" ]; then
    echo "ERROR: '$bibdir' BibDir does not exist!"
    exit 1
fi

cd $bibdir
latexmk -pdf -outdir=$tmpdir -jobname=$ck $tex

ls $tmpdir

cp $tmpdir/$ck.pdf "$bibdir/$ck.tex.pdf"
