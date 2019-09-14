//////////////////////////////////////////////////////////////////////////////////
/*!
  \brief      8 bit ALU for ECE 474
  \details    Top Level Module\n
  \file       mult.sv
  \author     Makenzie Brian
  \date       May 2017
*/
//////////////////////////////////////////////////////////////////////////////////


module alu(
    input        [7:0] in_a     ,  //input a
    input        [7:0] in_b     ,  //input b
    input        [3:0] opcode   ,  //opcode input
    output  reg  [7:0] alu_out  ,  //alu output
    output  reg        alu_zero ,  //logic '1' when alu_output [7:0] is all zeros
    output  reg        alu_carry   //indicates a carry out from ALU 
    );


    parameter c_add   = 4'h1;
    parameter c_sub   = 4'h2;
    parameter c_inc   = 4'h3;
    parameter c_dec   = 4'h4;
    parameter c_or    = 4'h5;
    parameter c_and   = 4'h6;
    parameter c_xor   = 4'h7;
    parameter c_shr   = 4'h8;
    parameter c_shl   = 4'h9;
    parameter c_one   = 4'hA;
    parameter c_two   = 4'hB;


    always_comb
    begin
        unique case (opcode)
            c_add :
                {alu_carry, alu_out} = in_a + in_b;

            c_sub :
                {alu_carry, alu_out} = in_a - in_b;

            c_inc :
                {alu_carry, alu_out} = in_a + 1;

            c_dec : 
                {alu_carry, alu_out} = in_a - 1;

            c_or : 
                {alu_carry, alu_out} = {1'b0, in_a | in_b};

            c_and :
                {alu_carry, alu_out} = {1'b0, in_a & in_b};

            c_xor :
                {alu_carry, alu_out} = {1'b0, in_a ^ in_b};

            c_shr :
                {alu_carry, alu_out} = {2'b0, in_a[7:1]};

            c_shl :
                {alu_carry, alu_out} = {in_a[7:0], 1'b0};

            c_one :
                {alu_carry, alu_out} = {1'b0, ~in_a};

            c_two :
                {alu_carry, alu_out} = {1'b0, ~in_a + 1};

            default : 
                {alu_carry, alu_out} = 9'bx;
        endcase

        alu_zero = ~((((alu_out[0])|(alu_out[1]))|((alu_out[2])|(alu_out[3])))|((((alu_out[4])|(alu_out[5]))|((alu_out[6])|(alu_out[7])))));

    end

  endmodule

  