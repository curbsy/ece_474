//////////////////////////////////////////////////////////////////////////////////
/*!
	\brief      32 bit multiplier for ECE 474
	\details    Top Level Module\n
	\file       mult.sv
	\author     Makenzie Brian
	\date       April/May 2017
*/
//////////////////////////////////////////////////////////////////////////////////


module mult( 
	input  					reset,
	input  					clk,
	input  			[31:0] 	a_in,
	input  			[31:0] 	b_in,
	input  					start,
	output logic 	[63:0] 	product,
	output logic 			done
	);


	logic   [31:0]      	reg_a;        		// output of multiplicand register
	logic   [31:0]      	prod_reg_high;      // prod reg upper half
	logic   [31:0]    		prod_reg_low;     	// prod reg lower half
	logic               	prod_reg_ld_high;   // upper half load for prod reg
	logic               	prod_reg_shift_rt;  //shift prod reg right


	//make the big product register
	assign product = {prod_reg_high, prod_reg_low};


	//create a register for a_in (the multplicand register)
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)   		reg_a <= '0;

		else if (start)   	reg_a <= a_in;
	end


	//makes adder and the prod reg high
	always_ff @(posedge clk, posedge reset)
	begin
		unique if (reset)				prod_reg_high <= '0; //asynchronous reset

		else if (start)					prod_reg_high <= '0; //synchronous reset

		else if (prod_reg_ld_high)		prod_reg_high <= reg_a + prod_reg_high; //do the addition

		else if (prod_reg_shift_rt)		prod_reg_high <= {1'b0, prod_reg_high[31:1]}; //shift

		else							prod_reg_high <= prod_reg_high; //match it if the lsb is 1
	end


	//create prod reg low
	always_ff @(posedge clk, posedge reset)
	begin
	   unique if (reset)				prod_reg_low <= '0;	//asynchronous reset

	   else if (start)					prod_reg_low <= b_in; //synchronous reset

	   else if (prod_reg_shift_rt)		prod_reg_low <= {prod_reg_high[0], prod_reg_low[31:1]}; //shift

	   else								prod_reg_low <= prod_reg_low; //match it if the lsb is 1
	end


	//instantiate the control module
	mult_ctl mult_ctrl_0(
		. reset 			( reset ) ,
		. clk 				( clk ),
		. start 			( start ) ,
		. multiplier_bit0 	( prod_reg_low [0] ) ,		//lsb of prodcut reg
		. prod_reg_ld_high 	( prod_reg_ld_high ),
		. prod_reg_shift_rt ( prod_reg_shift_rt ),
		. done 				( done )
		);

endmodule


module mult_ctl(
	input 			reset,
	input			clk,
	input			start,					//begin multiplication
	input			multiplier_bit0,
	output logic	prod_reg_ld_high,		//load high half of register
	output logic	prod_reg_shift_rt,		//shift product register right
	output logic 	done					//signal completion of mult operation
	);


	logic   [6:0]       	cntr;       		//counts the number of bits that have been processed


	//enumerated states
	enum logic [1:0]{
		HOLD 		= 2'b00,
		COUNTING 	= 2'b01,
		DONE 		= 2'b10
	} count_fsm_ps, count_fsm_ns;


	//enumerated states
	enum logic [2:0]{
		WAIT 	= 3'b000,
		ADD 	= 3'b001,
		SHIFT 	= 3'b010,
		TESTBIT = 3'b100
	} mth_fsm_ps, mth_fsm_ns;


	always_ff @(posedge clk, posedge reset)
	begin
		if(reset) 
		begin
			count_fsm_ps 	<= HOLD;	//at reset, to hold state
			mth_fsm_ps <= WAIT;
		end
		else
		begin
			count_fsm_ps 	<= count_fsm_ns; //ow to the next state
			mth_fsm_ps 		<= mth_fsm_ns;
		end
	end


	always_comb
	begin
		done = 0; //init done to zero
		case (count_fsm_ps)

			HOLD :
				if (start)			count_fsm_ns = COUNTING;
				else				count_fsm_ns = HOLD;

			COUNTING :
				if (!(cntr == 7'd65))		count_fsm_ns = COUNTING;
				else if(cntr == 7'd65)		count_fsm_ns = DONE;

			DONE :
				if (start || reset)		count_fsm_ns = COUNTING;
				else
				begin
					count_fsm_ns = HOLD;
					done = 1;					//signal done counting up
				end
		endcase
	end


	always_ff @(posedge clk, posedge reset)
	begin
		if(reset)			cntr <= 0; 			//set counter to 0
		else if(count_fsm_ps[0])
		begin
			cntr <= cntr + 1; 					//increment counter 
		end
		else		cntr <= 0; 					//reset counter to 0
	end


	always_comb
	begin
		case (mth_fsm_ps)

			WAIT :
				if (count_fsm_ps == COUNTING && multiplier_bit0)		mth_fsm_ns = ADD;
				else if (count_fsm_ps == COUNTING && !multiplier_bit0)	mth_fsm_ns = SHIFT;
				else													mth_fsm_ns = WAIT;

			ADD :
				if(done)	mth_fsm_ns = WAIT;
				else 		mth_fsm_ns = SHIFT;
				

			SHIFT :
				if(done)				mth_fsm_ns = WAIT;
				else if (cntr == 7'd65)	mth_fsm_ns = WAIT;
				else if (cntr != 7'd65)	mth_fsm_ns = TESTBIT;


			TESTBIT :
				if(done)					mth_fsm_ns = WAIT;
				else if (!multiplier_bit0)	mth_fsm_ns = SHIFT;
				else if (multiplier_bit0)	mth_fsm_ns = ADD;
				else 						mth_fsm_ns = TESTBIT;
				

		endcase
	end


	always_comb
	begin
		if(mth_fsm_ps[1])
		begin
			prod_reg_shift_rt = 1'b1; 	//shift
			prod_reg_ld_high = 1'b0;
		end

		else if (mth_fsm_ps[0])
		begin
			prod_reg_ld_high = 1'b1; 	//load high
			prod_reg_shift_rt = 1'b0;
		end
		else
		begin
			prod_reg_ld_high = 1'b0; 
			prod_reg_shift_rt = 1'b0;
		end
	end


endmodule
