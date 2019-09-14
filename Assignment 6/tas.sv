//////////////////////////////////////////////////////////////////////////////////
/*!
	brief      Temperature Averaging System
	details    takes the average of 4 valid temperature readings, sends it to be stored in ram
	file       tas.sv
	author     Makenzie Brian
	date       June 2 2017
*/
//////////////////////////////////////////////////////////////////////////////////


module tas (
    input  clk_50,               // 50Mhz input clock
    input  clk_2,                // 2Mhz input clock
    input  reset_n,              // reset async active low
    input  serial_data,          // serial input data
    input  data_ena,             // serial data enable
    output ram_wr_n,             // write strobe to ram
    output [7:0] ram_data,       // ram data
    output [10:0] ram_addr       // ram address
    );

	logic	[7:0]  data;
	logic	[3:0]  sel;
	logic 		   done_flg;
	logic 		   hold;
	logic	[7:0]  data_done;
	logic 	[31:0] val;
	logic 	[7:0]  avg_out;
	

	assign ram_data = data_done;

	always_ff @ (posedge clk_50, negedge reset_n) begin
		if (~reset_n) begin
			data <= '0;
			val <= '0;
			data_done <= '0;
		end else begin
			if (data_ena) begin
				data <= data >> 1;
				data[7] <= serial_data;
			end
			if (sel[0]) val[7:0] <= data;
			if (sel[1]) val[15:8] <= data;	
			if (sel[2]) val[23:16] <= data;
			if (sel[3]) val[31:24] <= data;
			if (done_flg) data_done <= avg_out;
		end
	end

	assign avg_out = (val[7:0] + val[15:8] + val[23:16] + val[31:24]) / 4;   //probably takes lots of gates...

	ctrl_50MHz ctrl_50MHz_0 (.*);
	ctrl_2MHz ctrl_2MHz_0 (.*);

endmodule // tas



module ctrl_50MHz (
	input	data_ena,
	input	clk_50,
	input	ram_wr_n,
	input	[7:0] data,
	input 	reset_n,
	output 	[3:0] sel,
	output	done_flg,
	output 	hold
	);

	//Serial Reading FSM
	enum logic [3:0] {			
		B0 =		4'b0000,
		B1 =		4'b0001,
		B2 =		4'b0010,
		B3 =		4'b0011,
		B4 =		4'b0100,
		B5 = 		4'b0101,
		B6 = 		4'b0110,
		B7 = 		4'b0111,
		DONE = 		4'b1000
	} srd_ps, srd_ns;

	//Packet Control FSM
	enum logic [2:0] {			
		BY0 	 =  3'b000,
		BY1 	 =	3'b001,
		BY2 	 =	3'b010,
		BY3 	 =	3'b011,
		PKT_DONE =	3'b100
	} pkt_ps, pkt_ns;

	//HOLD and Not Hold FSM
	enum logic [1:0] {
		HOLD 	 = 2'b01,
		HOLD_N	 = 2'b10
	} hold_ns, hold_ps;

	always_ff @(posedge clk_50 or negedge reset_n)
	begin
		if(~reset_n)
		begin
			srd_ps <= B0;
			pkt_ps <= BY0;
			hold_ps <= HOLD_N;
		end
		else
		begin
			srd_ps <= srd_ns;
			pkt_ps <= pkt_ns;
			hold_ps <= hold_ns;
		end
	end

	always_comb
	begin
		srd_ns = B0;
		case(srd_ps)
			B0: if (data_ena) 	srd_ns = B1;

			B1: if (data_ena) 	srd_ns = B2;

			B2: if (data_ena) 	srd_ns = B3;

			B3: if (data_ena) 	srd_ns = B4;

			B4: if (data_ena) 	srd_ns = B5;

			B5: if (data_ena) 	srd_ns = B6;

			B6: if (data_ena) 	srd_ns = B7;

			B7: if (data_ena) 	srd_ns = DONE;

			DONE: srd_ns = B0;

		endcase // srd_ps
	end

	assign byte_finished = srd_ps[3];

	assign done_flg = pkt_ps[2];


	always_comb
	begin
		pkt_ns = BY0;
		case(pkt_ps)
			BY0:
			begin
				if(byte_finished && (data != 8'hA5 && data != 8'hC3)) 	pkt_ns = BY1;
				else if(byte_finished && (data == 8'hA5 || data == 8'hC3)) pkt_ns = BY0;
				else pkt_ns = pkt_ps;
			end

			BY1: 
			begin
				if(byte_finished && (data != 8'hA5 && data != 8'hC3)) 	pkt_ns = BY2;
				else if(byte_finished && (data == 8'hA5 || data == 8'hC3)) pkt_ns = BY0;
				else pkt_ns = pkt_ps;
			end

			BY2: 
			begin
				if(byte_finished && (data != 8'hA5 && data != 8'hC3)) 	pkt_ns = BY3;
				else if(byte_finished && (data == 8'hA5 || data == 8'hC3)) pkt_ns = BY0;
				else pkt_ns = pkt_ps;
			end

			BY3: 
			begin
				if(byte_finished && (data != 8'hA5 && data != 8'hC3)) 	pkt_ns = PKT_DONE;
				else if(byte_finished && (data == 8'hA5 || data == 8'hC3)) pkt_ns = BY0;
				else pkt_ns = pkt_ps;
			end

			PKT_DONE: pkt_ns = BY0;

		endcase // pkt_ps
	end

	//enables
	assign sel[0] = (pkt_ps == BY0) ? 1 : 0;
	assign sel[1] = (pkt_ps == BY1) ? 1 : 0;
	assign sel[2] = (pkt_ps == BY2) ? 1 : 0;
	assign sel[3] = (pkt_ps == BY3) ? 1 : 0;

	always_comb
	begin
		hold_ns = HOLD_N;
		case(hold_ps)
			HOLD:
			begin
				if(~ram_wr_n)	hold_ns = HOLD_N;
				else 			hold_ns = hold_ps;
			end

			HOLD_N: if(done_flg)	hold_ns = HOLD;

		endcase // hold_ps
	end

	assign hold = hold_ps[0];

endmodule // ctrl_50MHz

module ctrl_2MHz (
	input 	hold,
	input 	clk_2,
	input 	reset_n,
	output	ram_wr_n,
	output 	[10:0] ram_addr	
	);

	//Ram Write FSM
	enum logic {
		RAM_WR_N 	= 0,
		RAM_WR  	= 1
	} ram_ns, ram_ps;

	logic [10:0] cur_ram_addr;
	logic [10:0] nxt_ram_addr;

	assign ram_addr = cur_ram_addr;

	always_ff @(posedge clk_2 or negedge reset_n)
	begin
		if(~reset_n)
		begin
			ram_ps <= RAM_WR;
			cur_ram_addr <= 11'h7ff;
		end
		else
		begin
			ram_ps <= ram_ns;
			cur_ram_addr <= nxt_ram_addr;
		end
	end

	always_comb
	begin
		ram_ns = RAM_WR;
		case(ram_ps)
			RAM_WR: if(hold) ram_ns = RAM_WR_N;

			RAM_WR_N: ram_ns = RAM_WR;

		endcase // ram_ps
	end

	assign ram_wr_n = ram_ps;

	always_comb
	begin
		if (~ram_wr_n && ram_addr != 0) 		nxt_ram_addr = ram_addr - 1;
		else if (~ram_wr_n && ram_addr == 0) 	nxt_ram_addr = 11'h7FF; //wrap around if addr=zero
		else 									nxt_ram_addr = ram_addr;
	end

endmodule // ctrl_2MHz