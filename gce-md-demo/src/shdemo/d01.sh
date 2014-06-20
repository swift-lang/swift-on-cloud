#!/bin/bash

cr=../c-ray
md=../md

for (( i=0; i<50; i++)); 
do
  $md/md 3 50 30000 | tee md$i.trj | grep ^s:$i | cat - $cr/ts2 | $cr/cr >fr$i.ppm ; convert fr$i.ppm fr$i.png 
done
convert fr*png t.gif; open -a Safari t.gif
