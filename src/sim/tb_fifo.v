//! @title FIFO testbench
//! @file tb_fifo.v
//! @author Felipe Montero Bruni
//! @date 10-2023
//! @version 0.1

`timescale 1ns/100ps

module tb_fifo ();
    parameter NB_REG  = 32;
    parameter NB_ADDR = 3 ;

    parameter NB_RND  = 32;

    wire [NB_REG - 1 : 0] o_rdata;
    wire                  o_empty;
    wire                  o_full ;
    reg                   i_rd   ;
    reg                   i_wr   ;
    reg  [NB_REG - 1 : 0] i_wdata;
    reg                   i_rst  ;
    reg                   clk    ;

    reg  [NB_RND - 1 : 0] rnd    ;

    fifo
    #(
        .NB_REG  (NB_REG ),
        .NB_ADDR (NB_ADDR)
    )
        u_fifo
        (
            .o_rdata (o_rdata),
            .o_empty (o_empty),
            .o_full  (o_full ),
            .i_rd    (i_rd   ),
            .i_wr    (i_wr   ),
            .i_wdata (i_wdata),
            .i_rst   (i_rst  ),
            .clk     (clk    )
        );

    integer i;

    initial begin
        $display("Starting FIFO Testbench");
        
        i_wdata   = {NB_REG{1'b0}};
        i_rd      = 1'b0;
        i_wr      = 1'b0;
        clk       = 1'b0;
        i_rst     = 1'b0;
        rnd       = {NB_RND{1'b0}};
        
        #20i_rst  = 1'b1;
        #20 i_rst = 1'b0;

        for (i = 0; i < 8; i = i + 1) begin
            #20 rnd = $random;
            #20 i_wdata = rnd;
            #10 i_wr = 1'b1;
            #10 i_wr = 1'b0;
        end
        
        for (i = 0; i < 8; i = i + 1) begin
            #20 rnd = $random;
            #20 i_wdata = rnd;
            #10 i_wr = 1'b1;
            #10 i_wr = 1'b0;
        end
        
        for (i = 0; i < 8; i = i + 1) begin
            #10 i_rd = 1'b1;
            #10 i_rd = 1'b0;
        end
        
        for (i = 0; i < 8; i = i + 1) begin
            #10 i_rd = 1'b1;
            #10 i_rd = 1'b0;
        end
        
        for (i = 0; i < 8; i = i + 1) begin
            #20 rnd = $random;
            #20 i_wdata = rnd;
            #10 i_wr = 1'b1;
            #10 i_wr = 1'b0;
        end

        #20 $display("FIFO Testbench finished");
        #20 $finish;

    end

    always #5 clk = ~clk;

endmodule