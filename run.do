vlib test
vmap work test 
vlog   uart_master.sv -lint
vlog   uart_slave.sv -lint
vlog  uart_top.sv -lint
#vlog   directed_test.sv -lint
vlog uvm_testbench.sv -lint
#vlog interface.sv -lint 

#vlog combined.sv -lint
#vlog -work test -coveropt 3 +cover +acc combined.sv -lint
vsim work.tb_uart_top
vsim -voptargs=+acc work.tb_uart_top
add wave sim:/tb_uart_top/u1.*
add wave sim:/tb_uart_top/u2.*
add wave sim:/tb_uart_top/u4.*
add wave sim:/tb_uart_top/u3.*

#vsim -coverage tb_uart_top -voptargs="+cover=bcesfx"


#run -all
vsim -coverage tb_uart_top -voptargs="+cover=bcesfx"
vsim -vopt -coverage test.tb_uart_top -do "coverage save -onexit -directive -codeAll file; run -all"

#coverage exclude -src N:/work/work/combined.sv -line 92
#coverage exclude -src Desktop/Checks/Milestone-4/combined.sv -line 20
#coverage exclude -src N:/work/work/scoreboard.sv -line 93

vcover report -details -codeAll -html file
coverage report -assert -binrhs -details -cvg



#add wave -r *
#run -all
