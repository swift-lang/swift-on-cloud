#! /bin/sh

cr=../c-ray
md=../md

$md/md 3 50 30000

for t in md??.trj; do
  cat $t $cr/ts2 | $cr/cr >t.ppm
  convert t.ppm $t.png 
done

convert -delay 20 md??.trj.png t.gif; open -a Safari t.gif
