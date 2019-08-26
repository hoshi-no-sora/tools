#!/bin/bash
PerlTOOLS_HOME="$HOME/Tools/perl"
echo -n "Perl File Name: "
read filename
echo -n "where(PATH)?: "
read outdir

ln -s ${PerlTOOLS_HOME}/${filename} ${outdir}

exit

