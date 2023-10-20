//! @title UART RX testbench
//! @file tb_uart_rx.v
//! @author Felipe Montero Bruni
//! @date 10-2023
//! @version 0.1

`timescale 1ns/100ps

module tb_uart_rx ();

    // COUNTER parameters
    parameter NB_COUNTER = 9;          //! NB of COUNTER REG
    
    // UART parameters             
    parameter NB_DATA    = 8;          //! NB of Data reg (uart, fifo, receiver)
    parameter NB_TCOUNT  = 4;          //! NB of tick counter reg
                                      
    // FIFO parameters                
    parameter NB_ADDR    = 4;          //! NB of ptr regs
    

    reg i_rd;
    reg i_RsRx;
    reg i_rst ;
    reg clk;

    
    wire [NB_DATA - 1 : 0] read_fifo_data;

    wire                   counter_tick_to_uart;
    
    wire [NB_DATA - 1 : 0] rx_data_to_fifo_wdata;
    wire                   rx_done_to_fifo_wr;

    // Baud rate generator
    counter
    #(
        .NB_COUNTER (NB_COUNTER)
    )
        counter_unit
        (
            .o_counter (                    ),  //! Counter status output (not used)
            .o_tick    (counter_tick_to_uart),  //! Output tick
            .i_rst     (i_rst               ),  //! Reset
            .clk       (clk                 )   //! Clock
        );


    // UART RX
    uart_rx
    #(
        .NB_DATA   (NB_DATA  ),
        .NB_TCOUNT (NB_TCOUNT)
    )
        uart_rx_unit
        (
            .o_data    (rx_data_to_fifo_wdata),  //! Data output
            .o_rx_done (rx_done_to_fifo_wr   ),  //! Frame finished output
            .i_rx      (i_RsRx               ),  //! Data in
            .i_stick   (counter_tick_to_uart ),  //! Tick counter input
            .i_rst     (i_rst                ),  //! Reset
            .clk       (clk                  )   //! Clock  
        );
    
    
    // FIFO RX
    fifo
    # (
        .NB_DATA (NB_DATA),
        .NB_ADDR (NB_ADDR)
    )
        fifo_rx_unit
        (
            .o_rdata (read_fifo_data       ),  //! Data output
            .o_empty (                     ),  //! FIFO empty signal output
            .o_full  (                     ),  //! FIFO full signal output (not used)
            .i_rd    (i_rd                 ),  //! Read enable input
            .i_wr    (rx_done_to_fifo_wr   ),  //! Write enable input
            .i_wdata (rx_data_to_fifo_wdata),  //! Data input
            .i_rst   (i_rst                ),  //! Reset
            .clk     (clk                  )   //! Clock
        );
    
    
    reg [31          : 0] rnd;
    reg [NB_DATA - 1 : 0] data_a;
    reg [NB_DATA - 1 : 0] data_b;
    reg [NB_DATA - 1 : 0] data_c;
    reg [NB_DATA - 1 : 0] data_d;
    
    integer          i, j;
    integer          TBAUD = 52083;

    initial begin
        $display("Starting UART Rx Testbench");

        i_RsRx = 1'b1;
        i_rd   = 1'b0;
        i_rst  = 1'b0; 
        clk    = 1'b0;

        data_a = {NB_DATA{1'b0}};
        data_b = {NB_DATA{1'b0}};
        data_c = {NB_DATA{1'b0}};
        data_d = {NB_DATA{1'b0}};

        #10 i_rst  = 1'b1;
        #10 i_rst  = 1'b0;

        for (j = 0; j < 20 ;j = j + 1) begin

            #10 rnd = $random;
            
            // send
            #100   i_RsRx = 1'b0; // start
            for (i = 0; i < 8; i = i + 1) begin
                #TBAUD i_RsRx = (rnd[7 : 0] >> i) & 1'b1; 
            end
            #TBAUD i_RsRx = 1'b1; // stop
            #TBAUD
            
            // send
            #100   i_RsRx = 1'b0; // start
            for (i = 0; i < 8; i = i + 1) begin
                #TBAUD i_RsRx = (rnd[15 : 8] >> i) & 1'b1; 
            end
            #TBAUD i_RsRx = 1'b1; // stop
            #TBAUD
            
            // send
            #100   i_RsRx = 1'b0; // start
            for (i = 0; i < 8; i = i + 1) begin
                #TBAUD i_RsRx = (rnd[23 : 16] >> i) & 1'b1; 
            end
            #TBAUD i_RsRx = 1'b1; // stop
            #TBAUD
            
            // send
            #100   i_RsRx = 1'b0; // start
            for (i = 0; i < 8; i = i + 1) begin
                #TBAUD i_RsRx = (rnd[31 : 24] >> i) & 1'b1; 
            end
            #TBAUD i_RsRx = 1'b1; // stop
            #TBAUD
            
            #5
            
            #10 data_a = read_fifo_data;
            #10 i_rd   = 1'b1;
            #10 i_rd   = 1'b0;
            
            #10 data_b = read_fifo_data;
            #10 i_rd   = 1'b1;
            #10 i_rd   = 1'b0;
            
            #10 data_c = read_fifo_data;
            #10 i_rd   = 1'b1;
            #10 i_rd   = 1'b0;
            
            #10 data_d = read_fifo_data;
            #10 i_rd   = 1'b1;
            #10 i_rd   = 1'b0;
            
            if (rnd != {data_d, data_c, data_b, data_a}) begin
                #20 $display("UART Rx Testbench FAILED");
                #20 $finish;
            end
        end

        #20 $display("UART Rx Testbench finished");
        #20 $finish;

    end


    always #5 clk = ~clk;

endmodule