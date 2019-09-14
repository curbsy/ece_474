//////////////////////////////////////////////////////////////////////////////////
/*!
	brief      Digital Clock for 7 segment display
	details    Top Level Module
	file       clock.sv
	author     Makenzie Brian
	date       June 2017
*/
//////////////////////////////////////////////////////////////////////////////////

module clock(
	input             reset_n,             //reset pin
	input             clk_1sec,            //1 sec clock
	input             clk_1ms,             //1 mili sec clock
	input             mil_time,            //mil time pin
	output reg [6:0]  segment_data,        //output 7 segment data
	output reg [2:0]  digit_select         //digit select
	);

	//Internal Variables
	logic [3:0]	D0_count;			// register to store count of digit 0
	logic [2:0] D1_count;			// register to store count of digit 1 
	logic [3:0]	D2_count;			// register to store count of digit 2
	logic [2:0] D3_count;			// register to store count of digit 3 
	logic [3:0]	D4_count;			// register to store count of digit 4
	logic [2:0] D5_count;			// register to store count of digit 5 	
	logic [6:0] segment;			//for use before outputting to segment_data
	logic [3:0]	data;				//to interface between the count and the segment
	logic [2:0] digit_select_flag; 	//flag for assiging digit_select

	assign digit_select = digit_select_flag;			// set digit select bit
	assign segment_data = segment;					// set the 7 segment data

	//clock counting
    always_ff @(posedge(clk_1sec), negedge reset_n)
    begin
        if(!reset_n) 
        begin              	//reset the time if reset
            D0_count = 0;
            D1_count = 0;
            D2_count = 0;
            D3_count = 0;
            D4_count = 0; 
            D5_count = 0; 
        end
        else if(clk_1sec == 1'b1) 
        begin  									//beginning of each second
            D0_count = D0_count + 1; 			//inc D0_count always
            if(D0_count == 10) 
            begin 								//check value of D0_count
                D0_count = 0;  					//reset D0_count
                D1_count = D1_count + 1; 		//inc D1_count
                if(D1_count == 6) 
                begin 							//check value of D1_count
                    D1_count = 0;  				//reset D1_count
                    D2_count = D2_count + 1;  	//inc D2_count
                   if(D2_count ==  10) 
                   begin  						//check value of D2_count
                        D2_count = 0; 			//reset D2_count, ETC.
                        D3_count = D3_count + 1;
                        if(D3_count == 6)
                        begin
                        	D3_count = 0;
                        	D4_count = D4_count + 1;
                        	if(D4_count == 10)
                        	begin
                        		D4_count = 0;
                        		D5_count = D5_count + 1;
                        	end
                    		else if(D5_count == 2 && D4_count == 4)
                    		begin
                    			D5_count = 0;
                    			D4_count = 0;
                    		end
                    	
                       	end
                    end 
                end
            end     
        end
    end

	//get the current number to display
	always_ff @(posedge clk_1ms or negedge reset_n) 
	begin
		if(~reset_n) 
			digit_select_flag <= 0;
		else 
			digit_select_flag <= (digit_select_flag + 1) % 6;
	end


	always_comb
	begin
		case(digit_select_flag)
			0: data = D0_count;
			1: data = D1_count;
			2: data = D2_count;
			3: data = D3_count;
			4: data = D4_count;
			5: data = D5_count;
		endcase // digit_select_flag
	end     

	//translate current number to 7seg
	always_comb
	begin
		case(data)
			0: segment = 7'b111_1110;
			1: segment = 7'b011_0000;
			2: segment = 7'b110_1101;
			3: segment = 7'b111_1001;
			4: segment = 7'b011_0011;
			5: segment = 7'b101_1011;
			6: segment = 7'b001_1111;
			7: segment = 7'b111_0000;
			8: segment = 7'b111_1111;
			9: segment = 7'b111_0011;
			default: segment = 7'b000_0000;
		endcase // data
	end


endmodule
