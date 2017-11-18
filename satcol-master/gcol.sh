#!/bin/bash

#echo "Graph:  $2"
#echo "Colors: $1"

SOLVER=glueSplit_clasp
CNF=satcol-tmp.cnf

./satcol $1 $2 > $CNF

if ./$SOLVER $CNF | grep --quiet "s SATISFIABLE"; then
  #echo "Is $1-colorable"
  echo "1"
else
  #echo "Is not $1$-colorable"
  echo "0"
fi
