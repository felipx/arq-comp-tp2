//! @title FIFO
//! @file fifo.v
//! @author Felipe Montero Bruni
//! @date 10-2023
//! @version 0.1

module fifo #(
    parameter NB_DATA  = 8,                               //! NB of data reg
    parameter NB_ADDR = 4                                 //! NB of ptr regs
) (
    output [NB_DATA - 1 : 0] o_rdata,                     //! Data output
    output                   o_empty,                     //! FIFO empty signal output
    output                   o_full ,                     //! FIFO full signal output  
    input                    i_rd   ,                     //! Read enable input
    input                    i_wr   ,                     //! Write enable input
    input  [NB_DATA - 1 : 0] i_wdata,                     //! Data input
    input                    i_rst  ,                     //! Reset
    input                    clk                          //! Clock
);

    reg [NB_DATA - 1 : 0] reg_array [2**NB_ADDR - 1 : 0]; // register array
    reg [NB_ADDR - 1 : 0] w_ptr_reg;
    reg [NB_ADDR - 1 : 0] w_ptr_next;
    reg [NB_ADDR - 1 : 0] r_ptr_reg; 
    reg [NB_ADDR - 1 : 0] r_ptr_next;
    reg                   full_reg;
    reg                   full_next;
    reg                   empty_reg; 
    reg                   empty_next;

    wire wr_en;

    integer ptr;

    //! FSM States 
    always @(posedge clk) begin
        if (i_rst) begin
            w_ptr_reg <= {NB_ADDR{1'b0}};
            r_ptr_reg <= {NB_ADDR{1'b0}};
            full_reg  <= 1'b0           ;
            empty_reg <= 1'b1           ;
        end
        else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next ;
            empty_reg <= empty_next;
        end
    end


    //! FIFO write operation
    always @(posedge clk) begin
        if (i_rst)
            for (ptr = 0; ptr <  2**NB_ADDR; ptr = ptr + 1)
                reg_array[ptr] <= {NB_DATA{1'b0}};              
        else
            if (wr_en)
                reg_array[w_ptr_reg] <= i_wdata;
    end
    

    //! FIFO read operation
    assign o_rdata = reg_array[r_ptr_reg];
    
    //! write enabled if FIFO is not full
    assign wr_en = i_wr & ~full_reg;


    //! Next-state logic for read and write pointers
    always @(*) begin
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next  = full_reg ;
        empty_next = empty_reg;

        case ({i_wr,i_rd})
            2'b01: // read
                if (~empty_reg) begin
                    r_ptr_next = r_ptr_reg + 1'b1;
                    full_next = 1'b0;
                    if ((r_ptr_reg + 1'b1) == w_ptr_reg)
                        empty_next = 1'b1;
                end
            2'b10: // write
                if (~full_reg) begin
                    w_ptr_next = w_ptr_reg + 1'b1;
                    empty_next = 1'b0;
                    if ((w_ptr_reg + 1'b1) == r_ptr_reg)
                        full_next = 1'b1;
                end
            2'b11: begin // write and read
                w_ptr_next = w_ptr_reg + 1'b1;
                r_ptr_next = r_ptr_reg + 1'b1;
            end 
            default: begin
                w_ptr_next = w_ptr_reg;
                r_ptr_next = r_ptr_reg;
                full_next  = full_reg ;
                empty_next = empty_reg;
            end
        endcase
    end

    assign o_full  = full_reg ;
    assign o_empty = empty_reg;
    
endmodule