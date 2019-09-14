///////////////////////////////////////////////////////////////////////////////////
/*
  \brief      FIFO 
  \details    Greastest Common Divisor using Verilog for ECE 474
  \file       gcd.sv
  \author     Makenzie Brian
  \date       May 21 2017
*/
///////////////////////////////////////////////////////////////////////////////////

module gcd( input [31:0] a_in,
            input [31:0] b_in,
            input start,
            input reset_n,
            input clk,
            output reg [31:0] result,
            output reg done);

//sk: declare the internal 32-bit register busses
reg [31:0] reg_a;
reg [31:0] reg_b;

//sk: declare the enumerated values for register a mux select
  enum reg [1:0]{
  	LOAD_A 	= 2'b00,
  	SUB_A 	= 2'b01,
  	SWAP_A 	= 2'b10,
  	HOLD_A 	= 2'b11
  	} reg_a_sel;

//sk: delcare the enumerated values for register b mux select
  enum reg [1:0]{
  	LOAD_B = 2'b00,
  	SWAP_B = 2'b10,
  	HOLD_B = 2'b11
  	} reg_b_sel;

//sk: create reg_a and its mux
always_ff @(posedge clk, negedge reset_n) 
begin
  if (!reset_n)  reg_a <= 2'b00;
  else
  begin
  	unique case (reg_a_sel)
  		LOAD_A	:	reg_a <= a_in;
  		SUB_A	  :	reg_a <= reg_a - reg_b;
  		SWAP_A	:	reg_a <= reg_b;
  		HOLD_A 	:	reg_a <= reg_a;
  	endcase //reg_a_sel
  end
end

//sk: create reg_b and its mux
always_ff @(posedge clk, negedge reset_n) 
begin
  if (!reset_n)  reg_b <= 2'b00;
  else
  begin
  	unique case (reg_b_sel)
  		LOAD_B	:	reg_b <= b_in;
  		SWAP_B	:	reg_b <= reg_a;
  		HOLD_B 	:	reg_b <= reg_b;
  	endcase //reg_b_sel
  end
end

//sk: reate the combinatorial signals that will steer the state machine 
assign a_lt_b = (reg_a < reg_b);      //if a < b, a_lt_b = 1
assign b_neq_zero = (reg_b != 0);     //if b != 0, b_neq_zero = 1

//sk: create the output signal from the internal register output
assign result = reg_a;

//sk: declare the enumerated values for gcd_sm
enum reg [2:0]{
	IDLE    = 3'b000,
	LOAD   	= 3'b001,
	SWAP	  = 3'b010,
	HOLD	  = 3'b011,
	SUB		  = 3'b100,
	FINISH  = 3'b101,
	XX		  = 'x
	} gcd_ps, gcd_ns;

//sk: build the present state storage for the state machine
always_ff @(posedge clk, negedge reset_n)
    if (!reset_n) 	gcd_ps <= IDLE;
    else			gcd_ps <= gcd_ns;

//sk: build the next state combo logic for the state machine
always_comb begin
  gcd_ns = XX;       //sk: default _ns assignment
  case (gcd_ps)
  	IDLE:
  	begin
  		if (start) 				gcd_ns = LOAD;
  		else							gcd_ns = IDLE;
  	end
  	LOAD:
  	begin
  		if(a_lt_b)				gcd_ns = SWAP;
  		else							gcd_ns = HOLD;
  	end
  	SWAP:
  		gcd_ns = HOLD;

  	HOLD:
  	begin
  		if(a_lt_b)				gcd_ns = SWAP;
  		else if(!a_lt_b && b_neq_zero)	gcd_ns = SUB;
      else if (!b_neq_zero)           gcd_ns = FINISH;
  		else							gcd_ns = HOLD;
  	end
  	SUB:
 	begin
  		if(!b_neq_zero)		gcd_ns = FINISH;
  		else							gcd_ns = HOLD;
  	end
  	FINISH:
  		gcd_ns = IDLE;
  
  endcase //gcd_ps
end

//sk: form the state machine mealy outputs here
always_comb begin
  reg_a_sel = HOLD_A;           //sk: default assignments
  reg_b_sel = HOLD_B;
  done = 1'b0;
    case (gcd_ps)
  		IDLE:
  		begin
  			reg_a_sel = HOLD_A;
  			reg_b_sel = HOLD_B;
  		end
  		LOAD:
  		begin
  			reg_a_sel = LOAD_A;
  			reg_b_sel = LOAD_B;
  		end
	  	SWAP:
	  	begin
  			reg_a_sel = SWAP_A;
  			reg_b_sel = SWAP_B;
  		end
  		HOLD:
  		begin
  			reg_a_sel = HOLD_A;
  			reg_b_sel = HOLD_B;
  		end  	
  		SUB:
  		begin
  			reg_a_sel = SUB_A;
  			reg_b_sel = HOLD_B;
  		end
  		FINISH:
  		begin
	  		reg_a_sel = HOLD_A;
  			reg_b_sel = HOLD_B;
  			done = 1'b1;           //asserts done signal
  		end
  	endcase

end //sk: always_comb

endmodule