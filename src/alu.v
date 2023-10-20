//! @title ALU
//! @file alu.v
//! @author Felipe Montero Bruni
//! @date 09-2023
//! @version 0.1

module alu
#(
    parameter NB_REG = 32,              //! NB of inputs and output
    parameter NB_OP  = 6                //! NB of operation input
) (
    output reg  [NB_REG - 1 : 0] o_out, //! Result output
    input       [NB_REG - 1 : 0] i_a  , //! a input
    input       [NB_REG - 1 : 0] i_b  , //! b input
    input       [NB_OP  - 1 : 0] i_op   //! Operation type input
);

    //! ALU logic
    always @(*) begin
        case (i_op)
            6'b000000 : o_out = i_a << i_b                                         ;  // SLL
            6'b000010 : o_out = i_a >> i_b                                         ;  // SRL
            6'b000011 : o_out = $signed(i_a) >>> i_b                               ;  // SRA
            6'b100000 : o_out = i_a + i_b                                          ;  // ADD
            6'b100010 : o_out = i_a - i_b                                          ;  // SUB
            6'b100100 : o_out = i_a & i_b                                          ;  // AND
            6'b100101 : o_out = i_a | i_b                                          ;  // OR
            6'b100110 : o_out = i_a ^ i_b                                          ;  // XOR
            6'b100111 : o_out = ~(i_a | i_b)                                       ;  // NOR
            6'b101010 : o_out = $signed(i_a) < $signed(i_b) ? 1'b1 : {NB_REG{1'b0}};  // SLT
            6'b101011 : o_out = (i_a < i_b) ? 1'b1 : {NB_REG{1'b0}}                ;  // SLTu
            default   : o_out = {NB_REG{1'b0}}                                     ;
        endcase
    end

endmodule
