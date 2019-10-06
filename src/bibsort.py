#!/usr/bin/env python

from bibtexparser.bwriter import BibTexWriter

import bibtexparser
import sys

if len(sys.argv) < 2:
    print("Usage:", sys.argv[0], "<bib-file>")
    sys.exit(0)

bibfile = sys.argv[1]
    
with open(bibfile) as bibf:
    bibtex = bibtexparser.load(bibf)

# NOTE: this puts uppercase CKs first: A < ... < Z < a ... < z
#entries = sorted(bibtex.entries, key=lambda e: e['ID'])
#print("Sorted manually CKs:")
#for bib in entries:
#    print(bib['ID'])

# apparently this sorts automatically by CK
bibwriter = BibTexWriter()
print(bibwriter.write(bibtex))

