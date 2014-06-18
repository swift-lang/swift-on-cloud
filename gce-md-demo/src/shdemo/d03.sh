#! /bin/sh

cr=../c-ray-1.1
md=../mdlite

# $md/md 3 50 30000
  $md/md 3 50 30000 50  .0001  .005  "0.03 1.0 0.2 0.05 50.0 0.1" 2.5 2.0

for t in md??.trj; do
  cat $t $cr/ts2 | $cr/cr >t.ppm
  convert t.ppm $t.png 
done

convert -delay 20 md??.trj.png t.gif; open -a Safari t.gif
