//! @title UART TX
//! @file uart_tx.v
//! @author Felipe Montero Bruni
//! @date 10-2023
//! @version 0.1

module uart_tx #(
    parameter NB_DATA   = 8,                    //! NB of Data reg
    parameter NB_TCOUNT = 4                     //! NB of tick counter reg
) (
    output wire                   o_tx      ,   //! TX data bit output
    output reg                    o_tx_done ,   //! TX done tick output
    input       [NB_DATA - 1 : 0] i_data    ,   //! Data input
    input                         i_tx_start,   //! TX start input      
    input                         i_stick   ,   //! Tick counter input
    input                         i_rst     ,   //! Reset
    input                         clk           //! Clock
);

    localparam NB_STATE = 4;
    
    //! FSMD states
    localparam [NB_STATE - 1 : 0] IDLE  = 4'b0001;
    localparam [NB_STATE - 1 : 0] START = 4'b0010;
    localparam [NB_STATE - 1 : 0] DATA  = 4'b0100;
    localparam [NB_STATE - 1 : 0] STOP  = 4'b1000;
    
    //! Internal Signals
    reg [NB_STATE  - 1 : 0] state_reg;
    reg [NB_STATE  - 1 : 0] next_state;
    
    reg [NB_DATA   - 1 : 0] data_reg;
    reg [NB_DATA   - 1 : 0] data_next;

    reg [NB_TCOUNT - 1 : 0] tick_counter_reg;
    reg [NB_TCOUNT - 1 : 0] tick_counter_next;

    reg [NB_DATA   - 1 : 0] bit_counter_reg;
    reg [NB_DATA   - 1 : 0] bit_counter_next;

    reg                     tx_reg;
    reg                     tx_next;


    //! FSMD state & data registers
    always @(posedge clk) begin
        if (i_rst) begin
            state_reg        <= IDLE;
            data_reg         <= {NB_DATA{1'b0}};
            tick_counter_reg <= {NB_TCOUNT{1'b0}};
            bit_counter_reg  <= {NB_DATA{1'b0}};
            tx_reg           <= 1'b1;
        end
        else begin
            state_reg        <= next_state;
            data_reg         <= data_next;
            tick_counter_reg <= tick_counter_next;
            bit_counter_reg  <= bit_counter_next;
            tx_reg           <= tx_next;
        end
    end


    always @(*) begin
        o_tx_done         = 1'b0;
        next_state        = state_reg;
        data_next         = data_reg;
        tick_counter_next = tick_counter_reg;
        bit_counter_next  = bit_counter_reg;
        tx_next           = tx_reg;

        case (state_reg)
            IDLE: begin
                tx_next = 1'b1;
                if (i_tx_start) begin
                    next_state        = START;
                    tick_counter_next = {NB_TCOUNT{1'b0}};
                    data_next         = i_data;
                end
            end
            START: begin
                tx_next = 1'b0;
                if (i_stick) begin
                    if (tick_counter_reg == 4'b1111) begin
                        next_state        = DATA;
                        tick_counter_next = {NB_TCOUNT{1'b0}};
                        bit_counter_next  = {NB_DATA{1'b0}};
                    end
                    else
                        tick_counter_next = tick_counter_reg + 1'b1;
                end
            end
            DATA: begin
                tx_next = data_reg[0];
                if (i_stick) begin
                    if (tick_counter_reg == 4'b1111) begin
                        tick_counter_next = {NB_TCOUNT{1'b0}};
                        data_next         = data_reg >> 1;
                        if (bit_counter_reg == 3'b111)
                            next_state = STOP;
                        else
                            bit_counter_next = bit_counter_reg + 1'b1;
                    end
                    else
                        tick_counter_next = tick_counter_reg + 1'b1;
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (i_stick) begin
                    if (tick_counter_reg == 4'b1111) begin
                        next_state = IDLE;
                        o_tx_done  = 1'b1;
                    end
                    else
                        tick_counter_next = tick_counter_reg + 1'b1;
                end
            end
            default: begin
                next_state        = IDLE;
                tx_next           = 1'b1;
                tick_counter_next = {NB_TCOUNT{1'b0}};
                bit_counter_next  = {NB_DATA{1'b0}};
            end
        endcase
    end

    assign o_tx = tx_reg;
    
endmodule