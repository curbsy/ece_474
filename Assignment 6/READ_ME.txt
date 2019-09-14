TAS takes the average of 4 valid temperature readings and sends it to be stored in ram.

To run the TAS file and see timing diagram:

	vlog tas.sv
	vlog tb.sv
	vsim tb -novopt -do tb.do


Number of gates:
	750