module uart_slave(
	input rst,
    input clk_rx,    //clock
    input clk,
    input u_rx,    //input form another uart
    output logic [7:0]data,  //output to main bus or other module
    input en_rx, //enable signal to Rx UART
    output reg u_rx_done //Rx is done
);

reg [3:0] count;
reg [7:0] dout;

parameter clk_freq = 50000000; //MHz
parameter baud_rate = 19200; //bits per second
localparam clkcount = (clk_freq/baud_rate);


integer counts = 0;
 

enum bit[2:0]{ IDLE = 3'b000,
 START = 3'b001,
 DATA = 3'b010,
 PARITY = 3'b011,
 DONE = 3'b100} state_rx;

always_ff @(posedge clk_rx ) 

begin
 if(rst)begin 
	u_rx_done <= '0;  
  end   
 else
   begin 
    case (state_rx)
    IDLE: 
	   begin
        if (en_rx) begin
            count <= 0;
            u_rx_done <= 0;
        end
        else begin
            state_rx <= IDLE;
        end

        if (u_rx == 0) begin
            state_rx <= DATA;
        end
        else begin
                state_rx <= IDLE;
        end

       end

    DATA: begin
        dout[count] <= u_rx;
        if (count == 3'b111) begin
            state_rx <= PARITY;
        end
        else begin
            state_rx <= DATA;
            count <= count + 1;
        end
    end

    PARITY: begin
        if (u_rx == ^dout) begin
            state_rx <= DONE;
          	 u_rx_done <= 1;
        end
        else begin
            state_rx <= IDLE;
        end
    end

    DONE: begin
        state_rx <= IDLE;
    end

    default: begin
        state_rx <= IDLE;
    end

    endcase
  end
end

assign data = ((state_rx == DONE)&(en_rx)) ? 'z : dout;

endmodule
