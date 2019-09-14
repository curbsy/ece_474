///////////////////////////////////////////////////////////////////////////////////
/*
	\brief      FIFO 
	\details    Creates a 8x8 byte FIFO using Verilog for ECE 474
	\file       fifo.sv
	\author     Makenzie Brian
	\date       May 12 2017
*/
///////////////////////////////////////////////////////////////////////////////////



module fifo ( 
    input            wr_clk,   //write clock
    input            rd_clk,   //read clock
    input            reset_n,  //reset async active low
    input            wr,       //write enable 
    input            rd,       //read enable    
    input      [7:0] data_in,  //data in
    output reg [7:0] data_out, //data out
    output           empty,    //empty flag
    output           full      //full flag
    );

	logic [2:0] wr_ptr; 		//next write
	logic [2:0] rd_ptr; 		//next read
	logic [7:0] buff[7:0];

	//regs for full and empty
	logic sync_empty;
	logic sync_full;
	assign full = sync_full;		//full flag
	assign empty = sync_empty;		//empty flag

	//write pointer
	always_ff @(posedge wr_clk or negedge reset_n)
	begin
		if(~reset_n)				wr_ptr <= 0;
		else if (wr_clk && wr && !full)	
		begin 		
									wr_ptr <= wr_ptr + 1; 
									buff[wr_ptr] <= data_in;	//happens in parallel

		end
		else						wr_ptr <= wr_ptr;			//do nothing

		//full sync logico
		if (~reset_n)								sync_full <= 0;		//reset so not full
		else if (((wr_ptr - rd_ptr) == 7) && wr)	sync_full <= 1;		//full when pointer diff is 7 and writing
		else if (((wr_ptr - rd_ptr) == 0) && full)	sync_full <= 1;		//still full
		else										sync_full <= 0;		//stay not full

	end


	//read pointer
	always_ff @(posedge rd_clk or negedge reset_n)
	begin
		if(~reset_n)				rd_ptr <= 0;
		else if (rd_clk && rd && !empty)
		begin	
									rd_ptr <= rd_ptr + 1;
									data_out <= buff[rd_ptr];
		end
		else						rd_ptr <= rd_ptr;			//do nothing

		//flag sync logico
		if (~reset_n)								sync_empty <= 1;		//start empty on reset
		else if (((wr_ptr - rd_ptr) == 0) && !full)	sync_empty <= 1;		//empty wher diff is 0 and it is not full
		else										sync_empty <= 0;		//ow not empty

	end


endmodule