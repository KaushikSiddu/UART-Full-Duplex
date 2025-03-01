module uart_master(
	input rst,
    input clk_tx, //clock
	input clk,
    input [7:0]data, //input from main bus or other module
    input en_tx, //enable signal to Tx UART 
    
    output reg u_tx, //output to another uart 
    output reg u_tx_done //Tx is done
   
);

parameter clk_freq = 50000000; //MHz
parameter baud_rate = 19200; //bits per second
localparam clkcount = (clk_freq/baud_rate);


reg [2:0] count;
reg [7:0] din;

integer counts = 0;
 

enum bit[2:0]{ IDLE = 3'b000,
 START = 3'b001,
 DATA = 3'b010,
 PARITY = 3'b011,
  DONE = 3'b100} state_tx;

always_ff @(posedge clk_tx)
begin
  
  if(rst)
   begin
    u_tx <= '0; 
    u_tx_done <= '0; end
  else 
  begin

    case (state_tx)

    START: 
	  begin
        if (en_tx) 
		 begin
            state_tx <= DATA;
            din <= data;
            u_tx <= 0;
            u_tx_done <= 0;
            count <= 0;
         end
        else u_tx <= 1'bz;
      end

    DATA: 
	 begin
        count <= count + 1;
        if (count == 3'b111) begin u_tx <= din[count]; state_tx <= PARITY;   end
        else begin u_tx <= din[count];  end
     end

    PARITY: 
	 begin
        u_tx <= ^din;  
        state_tx <= DONE;
     end

    DONE: 
	 begin
        u_tx_done <= 1;
        u_tx <= 0;
        state_tx <= START;
     end
    
    default: begin state_tx <= START; end
    endcase
	
  end
end

endmodule
  
