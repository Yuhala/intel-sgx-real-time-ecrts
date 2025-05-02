#!/bin/bash

# cleaning
./clean_cyclictest_results.sh
rm histogram*
rm *.png plotcmd

names=("gramine_idle" "gramine_hackbench" "gramine_stressng_vm" "gramine_stressng_irq")

for name in "${names[@]}"

do
  data=$name.ct


  max=`grep "Max Latencies" $data | tr " " "\n" | sort -n | tail -1 | sed s/^0*//`
  grep -v -e "^#" -e "^$" $data | tr " " "\t" >histogram 
  cores=4

  for i in `seq 1 $cores`
  do
    column=`expr $i + 1`
    cut -f1,$column histogram >histogram$i
 done

echo -n -e "set title \"Latency plot\"\n\
set terminal png\n\
set xlabel \"Latency (us), max $max us\"\n\
set logscale y\n\
set xrange [0:400]\n\
set yrange [0.8:*]\n\
set ylabel \"Number of latency samples\"\n\
set output \"$name.png\"\n\
plot " >plotcmd

for i in `seq 1 $cores`
do
  if test $i != 1
  then
    echo -n ", " >>plotcmd
  fi
  cpuno=`expr $i - 1`
  if test $cpuno -lt 10
  then
    title=" CPU$cpuno"
   else
    title="CPU$cpuno"
  fi
  echo -n "\"histogram$i\" using 1:2 title \"$title\" with histeps" >>plotcmd
done

gnuplot -persist <plotcmd

done

echo "Generated Gramine LibOS cyclictest plots successfully; see the corresponding .png files"