#!/usr/bin/bash

sv_file="mult.sv"	#make the file a variable
do_file="mult.do" 
syn_file="syn_mult"
gate_file="mult.gate.v"

#if directory doesn't exist, make it
if [ ! -d "./work" ]
then 
echo "Creating work directory"
mkdir ./work
fi

#if file exists, compile it
if [ -e "$sv_file" ]
then
echo 
echo "Compile .sv file"
vlog "$sv_file"
fi

#if do file exists, run simulator and quit
if [ -e "$do_file" ]
then
echo
echo "Simulate the module"
echo
vsim -novopt mult -do mult.do -quiet -c -t 1ps
fi

#if syn_mult exists, create gate file
if [ -e "$syn_file" ]
then
echo
echo "Create gate file"
design_vision-xg -no_gui -f "$syn_file"
fi

#if (the gate library has not been compiled yet) then
#synthesize the cell library into /work
#Hint: to check for prior compilation, look in work/_info, grep cell name 
echo
echo "Compiling Library"
echo
./comp_lib >/dev/null 2>&1

#compile gate.sv if it exists
if [ -e "$gate_file" ]
then
echo
echo "Compile gate file"
echo
vlog "$gate_file"
fi
