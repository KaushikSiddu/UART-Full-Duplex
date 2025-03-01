`include "uart_slave.sv"
`include "uart_master.sv"



module top();
    bit rst;
    bit clk; //clock
	bit uclk;
    bit [7:0]data_tx1; //input from main bus or other module
	bit [7:0]data_tx2;
    bit en_tx1; //enable signal to Tx UART
    bit en_tx2;	
    // logic en_rx,
    // logic u_tx, //output to another uart 
    logic u_tx_done1; //Tx is done
	logic u_tx_done2;
    // logic u_rx,    //input form another uart
    logic [7:0]data_rx1;  //output to main bus or other module
	 logic [7:0]data_rx2;  //output to main bus or other module
    bit en_rx1; //enable signal to Rx1 UART
	bit en_rx2; //enable signal to Rx2 UART
    logic u_rx_done1; //Rx1 is done
	logic u_rx_done2; //Rx2 is done

    wire m1s2;
	wire m2s1;
	
    //logic uclk = 0;

parameter clk_freq = 50000000; //MHz
parameter baud_rate = 19200; //bits per second
localparam clkcount = (clk_freq/baud_rate);

    uart_master u1(
		.rst(rst),
		.clk(clk),
        .clk_tx(uclk),
        .data(data_tx1),
        .en_tx(en_tx1),
        .u_tx(m1s2),
        .u_tx_done(u_tx_done1)
    );

    uart_slave u2(
		.rst(rst),
		.clk(clk),
        .clk_rx(uclk),
        .u_rx(m1s2),
        .en_rx(en_rx1),
        .data(data_rx1),
        .u_rx_done(u_rx_done1)
    );
	
    uart_slave u3(
	    .rst(rst),
		.clk(clk),
        .clk_rx(uclk),
        .u_rx(m2s1),
        .en_rx(en_rx2),
        .data(data_rx2),
        .u_rx_done(u_rx_done2)
    );
	
	 uart_master u4(
		.rst(rst),
		.clk(clk),
        .clk_tx(uclk),
        .data(data_tx2),
        .en_tx(en_tx2),
        .u_tx(m2s1),
        .u_tx_done(u_tx_done2)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top);
    end

initial begin
    fork
        uclkgen();
		clkgen();
        #180000 enable();
        #100 send(8'b 10010101,8'b0000_1011);
    join_any
   #300000 $display("Data received from slave1 is %b", data_rx1);
    #100    $display("Data received from slave2 is %b", data_rx2);
    #200 $finish;


end

task send;
    input [7:0]data1;
	input [7:0]data2;
    begin
        data_tx1 = data1;
		data_tx2 = data2;
       wait(u_tx_done);
        $display("Tx is done from master1 data is %d", data_tx1);
		$display("Tx is done from master2 data is %d", data_tx2);
        en_tx1 = 0;
		en_tx2 = 0;
    end
endtask

task reset;
input i_rst;
 begin
  rst = i_rst;
 end


endtask

task uclkgen;
    clk = 0;
    uclk = 0;
    begin
	    forever #clkcount uclk = ~uclk;
		
    end
endtask

task clkgen;
    clk = 0;
    
    begin
	    forever #5 clk = ~clk;
		
    end
endtask


task enable;
    begin
        en_rx1 = 1;
		en_rx2 = 1;
        en_tx1 = 1;
		en_tx2 = 1;
        fork
            begin
                wait(u_tx_done1);
                en_tx1 = 0;
            end
            begin
                wait(u_rx_done1);
                en_rx1 = 0;
            end
			begin
			wait(u_rx_done2);
                en_rx2 = 0;
				end
				begin
                wait(u_tx_done2);
                en_tx2 = 0;
            end
        join
    end
endtask

endmodule
