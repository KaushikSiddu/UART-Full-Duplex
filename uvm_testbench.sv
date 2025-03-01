`timescale 1 ns/ 1 ps
 import uvm_pkg::*;
`include "uvm_macros.svh"


interface uart_interface(input logic uclk, input logic rst, input bit clk);
  
    logic [7:0]data_tx1;                      //input data from master 1
	logic [7:0]data_tx2;                     //input data from master 2
    logic en_tx1;                           //enable signal to tx of UART1
    logic en_tx2;	                         //enable signal to tx of UART2 
    logic u_tx_done1;                      //Tx is done
	logic u_tx_done2;
    logic [7:0]data_rx1;                     //output to main bus or other module
	logic [7:0]data_rx2;                   //output to main bus or other module
    logic en_rx1;                          //enable signal to Rx1 UART
	logic en_rx2;                          //enable signal to Rx2 UART
    logic u_rx_done1;                     //Rx1 is done
	logic u_rx_done2;                    //Rx2 is done
    wire m1s2;
	wire m2s1;
	
endinterface



class uart_packet extends uvm_sequence_item;
	`uvm_object_utils(uart_packet)
	
	rand bit rst;
	bit uclk;
    rand bit [7:0]data_tx1; //input from main bus or other module
	rand bit [7:0]data_tx2; //input from main bus or other module
    rand bit en_tx1; //enable signal to Tx UART1
    rand bit en_tx2; //enable signal to Tx UART2
	rand bit en_rx1; //enable signal to Rx1 UART
	rand bit en_rx2; //enable signal to Rx2 UART
    
    logic u_tx_done1; //Tx is done
	logic u_tx_done2; 
    logic [7:0]data_rx1;  //output to main bus or other module
	logic [7:0]data_rx2;  //output to main bus or other module
	logic u_rx_done1; //Rx1 is done
	logic u_rx_done2; //Rx2 is done 
	
	constraint c1 {(en_tx1 & en_rx1) == '1 ;}
    constraint c2 {(en_tx2 & en_rx2) == '1 ;}	
	//constraint c3 {(en_tx1 & en_rx2) == '1 ;}
	
    function new(string name="uart_packet");
		super.new(name);
	endfunction
endclass:uart_packet


//------------------------------------------------------
class uart_pkt_sequence extends uvm_sequence;
	`uvm_object_utils(uart_pkt_sequence)
	uart_packet pkt;
	function new(string name="uart_pkt_sequence");
	super.new(name);
	`uvm_info("pkt_sequence","Inside Constructor!",UVM_MEDIUM)
	endfunction
	
	task body();
		pkt=uart_packet::type_id::create("uart_packet");
		repeat(5)
		begin
			start_item(pkt);
			assert(pkt.randomize());
			finish_item(pkt);
		end
	endtask
endclass:uart_pkt_sequence

//----------------------------------------------
class uart_seqr extends uvm_sequencer#(uart_packet);
	`uvm_component_utils(uart_seqr)
	function new(string name="uart_seqr",uvm_component parent);
	super.new(name,parent);
	`uvm_info("sequencer","Inside Constructor!",UVM_MEDIUM)
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("sequencer","Build Phase!",UVM_MEDIUM)
	endfunction:build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("sequencer","Connect Phase!",UVM_MEDIUM)
	endfunction:connect_phase 
endclass:uart_seqr
//----------------------------------------------------------



class uart_drv extends uvm_driver#(uart_packet);
	`uvm_component_utils(uart_drv)
	virtual uart_interface vif;
	uart_packet item;
	
	function new(string name="uart_drv",uvm_component parent);
	super.new(name,parent);
	`uvm_info("Driver Class","Inside Constructor!",UVM_MEDIUM)
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("Driver Class","Build Phase!",UVM_MEDIUM)
		
		if(!(uvm_config_db#(virtual uart_interface)::get(this,"*","vif",vif)))
		begin
			`uvm_error("Driver class","Failed to get vif from Config DB")
		end
	endfunction:build_phase
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("Driver Class","Connect Phase!",UVM_MEDIUM)
	endfunction:connect_phase
	
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		`uvm_info("Driver Class","Run phase!",UVM_MEDIUM)
		
		forever
		
		begin	
			item=uart_packet::type_id::create("item");
			seq_item_port.get_next_item(item);
			  @(posedge vif.uclk); begin
			  send(item);
			  if(item.en_tx1 && item.en_rx2 && !item.en_tx2 && !item.en_rx1) `uvm_info("ERROR","Invalid Transmission nad reception cant happen in same UART!",UVM_MEDIUM)
			  end
			  repeat(10) 
			   begin
			    @(posedge vif.uclk);
			   end
	        seq_item_port.item_done();
			
		end
	endtask: run_phase
	
	
	task send(uart_packet item);
     begin
	    begin
        vif.data_tx1 = item.data_tx1;
		vif.data_tx2 = item.data_tx2;
		 vif.en_rx1 = item.en_rx1;
		vif.en_rx2 = item.en_rx2;
        vif.en_tx1 = item.en_tx1;
		vif.en_tx2 = item.en_tx2;
		end
     end
    endtask
	
	
	
endclass:uart_drv

//----------------------------------------------------------------------------------------//
//---------------------------------------------------------------------------------------//


class uart_monitor extends uvm_monitor;
event event_sent;
`uvm_component_utils(uart_monitor)
 uart_packet trans;
 virtual uart_interface vif;
 
 uvm_analysis_port #(uart_packet) monitor_port;


	function new(string name="uart_monitor",uvm_component parent);
	super.new(name,parent);
	`uvm_info("monitor","Inside monitor Constructor!",UVM_MEDIUM)
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("sequencer","Build Phase!",UVM_MEDIUM)
		monitor_port = new("monitor_port", this);
		
		if(!(uvm_config_db#(virtual uart_interface)::get(this,"*","vif",vif)))
		begin
			`uvm_error("Monitor class","Failed to get vif from Config DB")
		end
		
	endfunction:build_phase
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("monitor Class","Connect Phase!",UVM_MEDIUM)
	endfunction:connect_phase
	
	
	task run_phase(uvm_phase phase);
	 super.run_phase(phase);
	 `uvm_info("monitor Class","Run Phase!",UVM_MEDIUM)
	 
	 forever 
	  begin
	   trans = uart_packet::type_id::create("trans");
       @(posedge vif.uclk); 
	     begin
          trans.data_tx1 = vif.data_tx1;
          trans.data_tx2 = vif.data_tx2;
	      trans.data_rx1 = vif.data_rx1;
          trans.data_rx2 = vif.data_rx2;
	      trans.u_tx_done1 = vif.u_tx_done1;
	      trans.u_tx_done2 = vif.u_tx_done2;
	      trans.u_rx_done1 = vif.u_rx_done1;
	      trans.u_rx_done2 = vif.u_tx_done2;
		  monitor_port.write(trans);
	     end
	
	    fork
	      begin
	     `uvm_info("",$sformatf("\t [mon] data_tx2 = %b @ time: %t", vif.data_tx2, $time),UVM_MEDIUM)
	      @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(negedge vif.uclk);
	     `uvm_info("",$sformatf("\t [mon] data_rx2 = %b @ time: %t", vif.data_rx2, $time),UVM_MEDIUM)
		 `uvm_info("",$sformatf("\t TRANSMISSION SUCESSFULL"),UVM_MEDIUM)
		 `uvm_info("",$sformatf("\t DATA MATCHED  SUCESSFULL"),UVM_MEDIUM)
		 `uvm_info("",$sformatf("-----------------------------------------------------------"),UVM_MEDIUM)
	      end
	     
		  begin
	     `uvm_info("",$sformatf("\t [mon] data_tx1 = %b @ time: %t", vif.data_tx1, $time),UVM_MEDIUM)
		 
	      @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(posedge vif.uclk);
		  @(negedge vif.uclk);
	     `uvm_info("",$sformatf("\t [mon] data_rx1 = %b @ time: %t", vif.data_rx1, $time),UVM_MEDIUM)
	      end
		  
	    join
		 @(posedge vif.uclk);
		 @(posedge vif.uclk);
		 @(posedge vif.uclk);
		 
	  end
    endtask: run_phase
	


endclass: uart_monitor


class uart_cov extends uvm_subscriber #(uart_packet);
  
  `uvm_component_utils(uart_cov)
  uart_packet trans;
	

  covergroup cov_inst;
  EN_RX1:coverpoint trans.en_rx1 {option.auto_bin_max = 1;}
  EN_RX2:coverpoint trans.en_rx2 {option.auto_bin_max = 1;}
  EN_TX1:coverpoint trans.en_tx1 {option.auto_bin_max = 1;}
  EN_TX2:coverpoint trans.en_tx2 {option.auto_bin_max = 1;}
  DATA_TX1:coverpoint trans.data_tx1 {option.auto_bin_max = 8;}
  DATA_TX2:coverpoint trans.data_tx2 {option.auto_bin_max = 8;}
  DATA_RX1:coverpoint trans.data_rx1 {option.auto_bin_max = 8;}
  DATA_RX2:coverpoint trans.data_rx2 {option.auto_bin_max = 8;}
  U_rx_Done1:coverpoint trans.u_rx_done1 {option.auto_bin_max = 1;}
  U_rx_Done2:coverpoint trans.u_rx_done2 {option.auto_bin_max = 1;}
  
  endgroup 
  
  
  function new(string name="", uvm_component parent);
		super.new(name, parent);
		cov_inst = new();
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction


  	virtual function void write(uart_packet t);
  	$cast(trans, t);
	 cov_inst.sample();
	 endfunction

endclass


//----------------------------------------------------------------------------------
class uart_agent extends uvm_agent;
	
 `uvm_component_utils(uart_agent)
	  
	uart_seqr seqr;
    uart_drv   driv;
    uart_monitor mon;
    uart_cov cov;
    
    function new(string name = "uart_agent", uvm_component parent);
      super.new(name, parent);
    endfunction
 
    function void build_phase(uvm_phase phase);
      seqr = uart_seqr::type_id::create("seqr", this);
      driv = uart_drv::type_id::create("driv", this);
      mon = uart_monitor::type_id::create("mon", this);
      cov = uart_cov::type_id::create("cov", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
      driv.seq_item_port.connect( seqr.seq_item_export);
      mon.monitor_port.connect(cov.analysis_export);
    endfunction
    

endclass



class uart_env extends uvm_env;

  `uvm_component_utils(uart_env)
    
   uart_agent agent;
    
    function new(string name = "uart_env", uvm_component parent);
      super.new(name, parent);
    endfunction
 
    function void build_phase(uvm_phase phase);
    agent = uart_agent::type_id::create("agent",this);  
    endfunction
    
    
  endclass: uart_env

//-------------------------------------------------------------------------------------------
  class uart_test extends uvm_test;
  
    `uvm_component_utils(uart_test)
    
     uart_env env;
     uart_pkt_sequence seq;
     function new(string name = "", uvm_component parent);
      super.new(name, parent);
     endfunction
    
     function void build_phase(uvm_phase phase);
      env = uart_env::type_id::create("env", this);
     endfunction
    
     function void end_of_elaboration_phase(uvm_phase phase);
	 `uvm_info("", this.sprint(), UVM_NONE)
	 endfunction
    
     task run_phase(uvm_phase phase);
	 phase.raise_objection(this);
	 repeat(5)begin
      uart_pkt_sequence seq;
      seq = uart_pkt_sequence::type_id::create("seq");
      seq.start( env.agent.seqr );
	  #10;
	  end
	 phase.drop_objection(this);
     endtask
     
  endclass: uart_test
  
  
module tb_uart_top;
  
parameter clk_freq = 50000000; //MHz
parameter baud_rate = 19200; //bits per second
localparam clkcount = (clk_freq/baud_rate);
  
bit clk = 0;
bit rst;
bit uclk;
  
  uart_interface intf(.clk(clk), .uclk(uclk), .rst(rst));
 //--------------------------------------------------UART 1-------------------------- 
	   uart_master u1(
		.rst(intf.rst),
		.clk(intf.clk),
        .clk_tx(intf.uclk),
        .data(intf.data_tx1),
        .en_tx(intf.en_tx1),
        .u_tx(intf.m1s2),
        .u_tx_done(intf.u_tx_done1)
    );

   
    uart_slave u3(
	    .rst(intf.rst),
		.clk(intf.clk),
        .clk_rx(intf.uclk),
        .u_rx(intf.m2s1),
        .en_rx(intf.en_rx2),
        .data(intf.data_rx2),
        .u_rx_done(intf.u_rx_done2)
    );
//----------------------------------------------------------------------------

//-------------------------------------------UART2--------------------------------------------
	 uart_master u4(
		.rst(intf.rst),
		.clk(intf.clk),
        .clk_tx(intf.uclk),
        .data(intf.data_tx2),
        .en_tx(intf.en_tx2),
        .u_tx(intf.m2s1),
        .u_tx_done(intf.u_tx_done2)
    );
	
	
	 uart_slave u2(
		.rst(intf.rst),
		.clk(intf.clk),
        .clk_rx(intf.uclk),
        .u_rx(intf.m1s2),
        .en_rx(intf.en_rx1),
        .data(intf.data_rx1),
        .u_rx_done(intf.u_rx_done1)
    );


  initial
  begin
    uclk = 0;
    forever #clkcount uclk = ~uclk;
  end
  
  initial
  begin
    uvm_config_db #(virtual uart_interface)::set(null, "*", "vif", intf);   
    run_test("uart_test");
  end
  initial begin 
  forever #10 clk = ~clk;
  end
  
  initial 
  begin
   #3000000 $finish();
  end

endmodule: tb_uart_top
  
  
  