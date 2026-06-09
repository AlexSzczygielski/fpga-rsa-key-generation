`timescale 1ns / 1ps

// 8N1 UART transmitter
// Send one byte by pulsing 'send' high for one clock cycle with 'data' valid.
// 'busy' is high while a byte is being transmitted.
// CLK_DIV = CLK_FREQ / BAUD_RATE  (e.g. 12_000_000 / 9600 = 1250)

module uart_tx #(
    parameter CLK_DIV = 1250
)(
    input  wire       CLK,
    input  wire       rst,
    input  wire       send,
    input  wire [7:0] data,
    output reg        busy,
    output reg        tx
);

localparam IDLE  = 2'd0;
localparam START = 2'd1;
localparam DATA  = 2'd2;
localparam STOP  = 2'd3;

reg [1:0]  state    = IDLE;
reg [12:0] clk_cnt  = 0;       // counts up to CLK_DIV-1
reg [7:0]  shift    = 0;
reg [2:0]  bit_idx  = 0;

always @(posedge CLK) begin
    if (rst) begin
        state   <= IDLE;
        tx      <= 1'b1;
        busy    <= 1'b0;
        clk_cnt <= 0;
    end else begin
        case (state)
            IDLE: begin
                tx   <= 1'b1;
                busy <= 1'b0;
                if (send) begin
                    shift   <= data;
                    clk_cnt <= 0;
                    busy    <= 1'b1;
                    state   <= START;
                end
            end

            START: begin
                tx <= 1'b0;   // start bit
                if (clk_cnt == CLK_DIV - 1) begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    state   <= DATA;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            DATA: begin
                tx <= shift[0];
                if (clk_cnt == CLK_DIV - 1) begin
                    clk_cnt <= 0;
                    shift   <= {1'b0, shift[7:1]};
                    if (bit_idx == 7) begin
                        state <= STOP;
                    end else begin
                        bit_idx <= bit_idx + 1;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            STOP: begin
                tx <= 1'b1;   // stop bit
                if (clk_cnt == CLK_DIV - 1) begin
                    clk_cnt <= 0;
                    state   <= IDLE;
                    busy    <= 1'b0;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
        endcase
    end
end

endmodule
