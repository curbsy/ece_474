add wave -r /*
force -freeze sim:/clock/clk_1sec 1 0, 0 {3000 ns} -r 6000
force -freeze sim:/clock/clk_1ms 1 0, 0 {3 ns} -r 6

force reset_n 1
run 24000
force reset_n 0
run 12000
force reset_n 1
run 555000000