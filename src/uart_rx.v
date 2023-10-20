//! @title UART RX
//! @file uart_rx.v
//! @author Felipe Montero Bruni
//! @date 10-2023
//! @version 0.1

module uart_rx #(
    parameter NB_DATA   = 8,                    //! NB of Data reg
    parameter NB_TCOUNT = 4                     //! NB of tick counter reg
    
) (
    output wire [NB_DATA - 1 : 0] o_data   ,    //! Data output
    output reg                    o_rx_done,    //! Frame finished output
    input                         i_rx     ,    //! Data in
    input                         i_stick  ,    //! Tick counter input
    input                         i_rst    ,    //! Reset
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


    //! FSMD state & data registers
    always @(posedge clk) begin
        if (i_rst) begin
            state_reg        <= IDLE;
            data_reg         <= {NB_DATA{1'b0}};
            tick_counter_reg <= {NB_TCOUNT{1'b0}};
            bit_counter_reg  <= {NB_DATA{1'b0}};
        end
        else begin
            state_reg        <= next_state;
            data_reg         <= data_next;
            tick_counter_reg <= tick_counter_next;
            bit_counter_reg  <= bit_counter_next;
        end
    end


    always @(*) begin
        o_rx_done         = 1'b0;
        next_state        = state_reg;
        data_next         = data_reg;
        tick_counter_next = tick_counter_reg;
        bit_counter_next  = bit_counter_reg;

        case (state_reg)
            IDLE: begin
                if (~i_rx) begin
                    next_state        = START;
                    tick_counter_next = {NB_TCOUNT{1'b0}};
                end
            end
            START: begin
                if (i_stick) begin
                    if (tick_counter_reg == 4'b0111) begin
                        next_state        = DATA;
                        tick_counter_next = {NB_TCOUNT{1'b0}};
                        bit_counter_next  = {NB_DATA{1'b0}};
                    end
                    else
                        tick_counter_next = tick_counter_reg + 1'b1;
                end
            end
            DATA: begin
                if (i_stick) begin
                    if (tick_counter_reg == 4'b1111) begin
                        tick_counter_next = {NB_TCOUNT{1'b0}};
                        data_next         = {i_rx, data_reg[NB_DATA - 1 : 1]};
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
                if (i_stick) begin
                    if (tick_counter_reg == 4'b1111) begin
                        if (i_rx == 1'b1) begin
                            next_state = IDLE;
                            o_rx_done  = 1'b1;
                        end
                        else
                            next_state = IDLE;
                    end
                    else
                        tick_counter_next = tick_counter_reg + 1'b1;
                end
            end
            default: begin
                next_state        = IDLE;
                o_rx_done         = 1'b1;
                tick_counter_next = {NB_TCOUNT{1'b0}};
                bit_counter_next  = {NB_DATA{1'b0}};
            end
        endcase
    end

    assign o_data = data_reg;
endmodule