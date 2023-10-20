//! @title INTERFACE
//! @file interface.v
//! @author Felipe Montero Bruni
//! @date 10-2023
//! @version 0.1

module interface #(
    parameter NB_DATA  = 8,                   //! NB of Data input
    parameter NB_REG   = 32,                  //! NB of ALU inputs
    parameter NB_OP    = 6,                   //! NB of ALU operation
    parameter NB_COUNT = 3                    //! NB of data counter
) (
    output reg                   o_tx_start,  //! UART Tx start signal output
    output reg                   o_rd      ,  //! FIFO Rx read enable output
    output reg                   o_wr      ,  //! FIFO Tx write enable output
    output reg [NB_DATA - 1 : 0] o_alu_out ,  //! ALU result output
    output     [NB_REG  - 1 : 0] o_alu_a   ,  //! ALU a output
    output     [NB_REG  - 1 : 0] o_alu_b   ,  //! ALU b output
    output     [NB_OP   - 1 : 0] o_alu_op  ,  //! ALU op output
    input      [NB_REG  - 1 : 0] i_alu_out ,  //! ALU result input
    input      [NB_DATA - 1 : 0] i_rx_data ,  //! FIFO Rx data input
    input                        i_rx_done ,  //! UART Rx done signal input
    input                        i_rx_empty,  //! FIFO Rx empty signal input
    input                        i_tx_done ,  //! UART Tx done signal input
    input                        i_rst     ,  //! Reset
    input                        clk          //! Clock
);

    localparam NB_STATE = 8;

    //! FSMD states
    localparam [NB_STATE - 1 : 0] IDLE     = 8'b00000001;
    localparam [NB_STATE - 1 : 0] DATA_A   = 8'b00000010;
    localparam [NB_STATE - 1 : 0] DATA_B   = 8'b00000100;
    localparam [NB_STATE - 1 : 0] DATA_OP  = 8'b00001000;
    localparam [NB_STATE - 1 : 0] END_RX   = 8'b00010000;
    localparam [NB_STATE - 1 : 0] FIFO_OUT = 8'b00100000;
    localparam [NB_STATE - 1 : 0] SEND     = 8'b01000000;
    localparam [NB_STATE - 1 : 0] ERROR    = 8'b10000000;

    //! Internal Signals
    reg [NB_STATE  - 1 : 0] state_reg;
    reg [NB_STATE  - 1 : 0] next_state;

    reg [NB_REG    - 1 : 0] alu_a_reg;
    reg [NB_REG    - 1 : 0] alu_a_next;
    reg [NB_REG    - 1 : 0] alu_b_reg;
    reg [NB_REG    - 1 : 0] alu_b_next;
    reg [NB_OP     - 1 : 0] alu_op_reg;
    reg [NB_OP     - 1 : 0] alu_op_next;
    reg [NB_REG    - 1 : 0] alu_out_reg;
    reg [NB_REG    - 1 : 0] alu_out_next;

    reg [NB_COUNT  - 1 : 0] d_count_reg;
    reg [NB_COUNT  - 1 : 0] d_count_next;

    reg                     rx_done_reg;
    reg                     tx_done_reg;


    //! FSMD states
    always @(posedge clk) begin
        if (i_rst) begin
            state_reg   <= IDLE;
            alu_a_reg   <= {NB_REG{1'b0}};
            alu_b_reg   <= {NB_REG{1'b0}};
            alu_op_reg  <= {NB_OP{1'b0}};
            alu_out_reg <= {NB_REG{1'b0}};
            d_count_reg <= {NB_COUNT{1'b0}};
        end
        else begin
            state_reg   <= next_state;
            alu_a_reg   <= alu_a_next;
            alu_b_reg   <= alu_b_next;
            alu_op_reg  <= alu_op_next;
            alu_out_reg <= alu_out_next;
            d_count_reg <= d_count_next;
        end
    end


    always @(posedge clk) begin
        if (i_rst) begin
            rx_done_reg <= 1'b0;
            tx_done_reg <= 1'b0;
        end
        else begin
            if (i_rx_done)
                rx_done_reg <= 1'b1;
            else
                rx_done_reg <= 1'b0;
            
            if (i_tx_done == 1'b1)
                tx_done_reg <= 1'b1;
            else
                tx_done_reg <= 1'b0;
        end
    end

    // Next-state logic
    always @(*) begin
        o_tx_start   = 1'b0;
        o_rd         = 1'b0;
        o_wr         = 1'b0;
        o_alu_out    = {NB_DATA{1'b0}};
        next_state   = state_reg;
        alu_a_next   = alu_a_reg;   
        alu_b_next   = alu_b_reg; 
        alu_op_next  = alu_op_reg;
        alu_out_next = alu_out_reg;
        d_count_next = d_count_reg;

        case (state_reg)
            IDLE: begin
                if (rx_done_reg) begin
                    o_rd = 1'b1;
                    if (i_rx_data == 8'hA5)
                        next_state = DATA_A;
                    else
                        next_state = ERROR;
                end
            end
            DATA_A: begin
                if (d_count_reg == 3'b100) begin
                    next_state = DATA_B;
                    d_count_next = {NB_COUNT{1'b0}};
                end
                else begin
                    if (rx_done_reg) begin
                        o_rd = 1'b1;
                        alu_a_next = {i_rx_data, alu_a_reg[NB_REG - 1 : NB_DATA]};
                        d_count_next = d_count_reg + 1'b1;
                    end
                end
            end
            DATA_B: begin
                if (d_count_reg == 3'b100) begin
                    next_state = DATA_OP;
                    d_count_next = {NB_COUNT{1'b0}};
                end
                else begin
                    if (rx_done_reg) begin
                        o_rd = 1'b1;
                        alu_b_next = {i_rx_data, alu_b_reg[NB_REG - 1 : NB_DATA]};
                        d_count_next = d_count_reg + 1'b1;
                    end
                end
            end
            DATA_OP: begin
                if (rx_done_reg) begin
                    next_state = END_RX;
                    o_rd = 1'b1;
                    alu_op_next = i_rx_data[NB_DATA - 3 : 0];
                end
            end
            END_RX: begin
                if (rx_done_reg) begin
                    o_rd = 1'b1;
                    if (i_rx_data == 8'hF5) begin
                        next_state   = FIFO_OUT;
                        alu_out_next = i_alu_out; 
                    end
                    else
                        next_state = ERROR;
                end
            end
            FIFO_OUT: begin
                if (d_count_reg == 3'b100) begin
                    next_state = SEND;
                    d_count_next = {NB_COUNT{1'b0}};
                end
                else begin
                    o_wr = 1'b1;
                    if (d_count_reg == 3'b000)
                        o_alu_out = alu_out_reg[7  :  0];
                    else if (d_count_reg == 3'b001)
                        o_alu_out = alu_out_reg[15 :  8];
                    else if (d_count_reg == 3'b010)
                        o_alu_out = alu_out_reg[23 : 16];
                    else
                        o_alu_out = alu_out_reg[31 : 24];
                    
                    d_count_next = d_count_reg + 1'b1;
                end
            end
            SEND: begin
                if (d_count_reg == 3'b100) begin
                    next_state = IDLE;
                    d_count_next = {NB_COUNT{1'b0}};
                end
                else if (d_count_reg == 3'b000) begin
                    o_tx_start = 1'b1;
                    d_count_next = d_count_reg + 1'b1;
                end
                else begin
                    if (tx_done_reg) begin
                        o_tx_start = 1'b1;
                        d_count_next = d_count_reg + 1'b1;
                    end  
                end  
            end
            ERROR: begin
                //o_alu_out    = {NB_DATA{1'b0}};
                alu_a_next   = {NB_REG{1'b0}};
                alu_b_next   = {NB_REG{1'b0}};
                alu_op_next  = {NB_OP{1'b0}};
                d_count_next = {NB_COUNT{1'b0}};
                if (~i_rx_empty)
                    o_rd = 1'b1;
                else begin
                    alu_out_next = 32'hA5FFFFF5;
                    next_state = FIFO_OUT;
                    //next_state = IDLE;
                end
            end
            default: begin
                o_alu_out    = {NB_DATA{1'b0}};
                alu_a_next   = {NB_REG{1'b0}};
                alu_b_next   = {NB_REG{1'b0}};
                alu_op_next  = {NB_OP{1'b0}};
                d_count_next = {NB_COUNT{1'b0}};
                next_state = IDLE;
            end
        endcase
    end

    assign o_alu_a        = alu_a_reg;
    assign o_alu_b        = alu_b_reg;
    assign o_alu_op       = alu_op_reg;

endmodule