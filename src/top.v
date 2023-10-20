//! @title tp2 top level
//! @file top.v
//! @author Felipe Montero Bruni
//! @date 10-2023
//! @version 0.1

module top
#(
    // COUNTER parameters
    parameter NB_COUNTER = 9,       //! NB of COUNTER REG
    
    // ALU parameters                 
    parameter NB_REG     = 32,      //! NB of inputs and output
    parameter NB_OP      = 6,       //! NB of operation input
                                     
    // UART parameters             
    parameter NB_DATA    = 8,       //! NB of Data reg
    parameter NB_TCOUNT  = 4,       //! NB of tick counter reg
                                      
    // FIFO parameters                
    parameter NB_ADDR    = 4,       //! NB of ptr regs
    
    // INTERFACE parameters
    parameter NB_COUNT   = 3,        //! NB of data counter 

) (
    output [1 : 0] JA,
    output         o_RsTx,
    input          i_RsRx,
    input          i_rst ,
    input          clk
);

    wire                   counter_tick_to_uart;

    wire [NB_REG  - 1 : 0] alu_out_to_interface;
    
    wire [NB_DATA - 1 : 0] uart_rx_data_to_fifo_wdata;
    wire                   uart_rx_done_to_fifo_wr;

    wire [NB_DATA - 1 : 0] fifo_rx_rdata_to_interface;
    wire                   fifo_rx_empty_to_interface;

    wire                   interface_to_fifo_rx_rd;
    wire                   interface_to_fifo_tx_wr;
    wire [NB_DATA - 1 : 0] interface_to_fifo_tx_wdata;
    wire [NB_REG  - 1 : 0] interface_to_alu_a;
    wire [NB_REG  - 1 : 0] interface_to_alu_b;
    wire [NB_OP   - 1 : 0] interface_to_alu_op;
    wire                   interface_to_tx_start;

    wire [NB_DATA - 1 : 0] fifo_tx_rdata_to_uart_tx;

    wire                   uart_tx_done_to_interface;


    assign JA[0] = i_RsRx;
    assign JA[1] = o_RsTx;


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


    // ALU
    alu
    #(
        .NB_REG (NB_REG),
        .NB_OP  (NB_OP )
    )
        alu_unit
        (
            .o_out (alu_out_to_interface),  //! Result output
            .i_a   (interface_to_alu_a  ),  //! a input
            .i_b   (interface_to_alu_b  ),  //! b input
            .i_op  (interface_to_alu_op )   //! Operation type input
        );
    
    
    // UART INTERFACE
    interface
    # (
        .NB_DATA  (NB_DATA ),
        .NB_REG   (NB_REG  ),
        .NB_OP    (NB_OP   ),
        .NB_COUNT (NB_COUNT)
    )
        interface_unit
        (
            .o_tx_start (interface_to_tx_start     ),  //! UART Tx start signal output
            .o_rd       (interface_to_fifo_rx_rd   ),  //! FIFO Rx read enable output
            .o_wr       (interface_to_fifo_tx_wr   ),  //! FIFO Tx write enable output
            .o_alu_out  (interface_to_fifo_tx_wdata),  //! ALU result output
            .o_alu_a    (interface_to_alu_a        ),  //! ALU a output
            .o_alu_b    (interface_to_alu_b        ),  //! ALU b output
            .o_alu_op   (interface_to_alu_op       ),  //! ALU op output
            .i_alu_out  (alu_out_to_interface      ),  //! ALU result input
            .i_rx_data  (fifo_rx_rdata_to_interface),  //! FIFO Rx data input
            .i_rx_done  (uart_rx_done_to_fifo_wr   ),  //! UART Rx done signal input
            .i_rx_empty (fifo_rx_empty_to_interface),  //! FIFO Rx empty signal input
            .i_tx_done  (uart_tx_done_to_interface ),  //! UART Tx done signal input
            .i_rst      (i_rst                     ),  //! Reset
            .clk        (clk                       )   //! Clock
        );


    // UART RX
    uart_rx
    #(
        .NB_DATA   (NB_DATA  ),
        .NB_TCOUNT (NB_TCOUNT)
    )
        uart_rx_unit
        (
            .o_data    (uart_rx_data_to_fifo_wdata),  //! Data output
            .o_rx_done (uart_rx_done_to_fifo_wr   ),  //! Frame finished output
            .i_rx      (i_RsRx                    ),  //! Data in
            .i_stick   (counter_tick_to_uart      ),  //! Tick counter input
            .i_rst     (i_rst                     ),  //! Reset
            .clk       (clk                       )   //! Clock  
        );
    
    
    // FIFO RX
    fifo
    # (
        .NB_DATA (NB_DATA),
        .NB_ADDR (NB_ADDR)
    )
        fifo_rx_unit
        (
            .o_rdata (fifo_rx_rdata_to_interface),  //! Data output
            .o_empty (fifo_rx_empty_to_interface),  //! FIFO empty signal output
            .o_full  (                          ),  //! FIFO full signal output (not used)
            .i_rd    (interface_to_fifo_rx_rd   ),  //! Read enable input
            .i_wr    (uart_rx_done_to_fifo_wr   ),  //! Write enable input
            .i_wdata (uart_rx_data_to_fifo_wdata),  //! Data input
            .i_rst   (i_rst                     ),  //! Reset
            .clk     (clk                       )   //! Clock
        );
    
    
    // FIFO TX
    fifo
    # (
        .NB_DATA (NB_DATA),
        .NB_ADDR (NB_ADDR)
    )
        fifo_tx_unit
        (
            .o_rdata (fifo_tx_rdata_to_uart_tx  ),  //! Data output
            .o_empty (fifo_tx_empty_to_led      ),  //! FIFO empty signal output
            .o_full  (                          ),  //! FIFO full signal output
            .i_rd    (interface_to_tx_start     ),  //! Read enable input
            .i_wr    (interface_to_fifo_tx_wr   ),  //! Write enable input
            .i_wdata (interface_to_fifo_tx_wdata),  //! Data input
            .i_rst   (i_rst                     ),  //! Reset
            .clk     (clk                       )   //! Clock
        );    
    
    
    // UART TX
    uart_tx
    # (
        .NB_DATA   (NB_DATA  ),
        .NB_TCOUNT (NB_TCOUNT)
    )
        uart_tx_unit
        (
            .o_tx      (o_RsTx                   ),  //! TX data bit output
            .o_tx_done (uart_tx_done_to_interface),  //! TX done tick output
            .i_data    (fifo_tx_rdata_to_uart_tx ),  //! Data input
            .i_tx_start(interface_to_tx_start    ),  //! TX start input      
            .i_stick   (counter_tick_to_uart     ),  //! Tick counter input
            .i_rst     (i_rst                    ),  //! Reset
            .clk       (clk                      )   //! Clock
        );


endmodule