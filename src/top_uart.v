`timescale 1ns / 1ps

// Top-level for Arty S7-50
// Clock : 12 MHz oscillator (F14, LVCMOS33)
// UART  : R12, 9600 baud, CLK_DIV = 12_000_000/9600 = 1250
// Reset : ck_rst (C18, active-low)
// LED   : E18 - lights when both primes sent

module top_uart (
    input  wire CLK12MHZ,
    input  wire ck_rst,
    output wire uart_rxd_out,
    output reg  led
);

// -------------------------------------------------------------------------
// Reset synchroniser - active-high internal reset
// -------------------------------------------------------------------------
reg rst_sync0 = 1, rst_sync1 = 1;
always @(posedge CLK12MHZ) begin
    rst_sync0 <= ~ck_rst;
    rst_sync1 <= rst_sync0;
end
wire rst = rst_sync1;

// -------------------------------------------------------------------------
// Prime generator #1  seed=105
// -------------------------------------------------------------------------
wire [8:0] prime1_val;
wire       prime1_done;
reg        prime1_be = 0;
reg        prime1_ce = 1;

prime_number_generator gen1 (
    .CLK  (CLK12MHZ),
    .be   (prime1_be),
    .seed (9'd105),
    .ce   (prime1_ce),
    .x    (prime1_val),
    .done (prime1_done)
);

// -------------------------------------------------------------------------
// Prime generator #2  seed=241
// -------------------------------------------------------------------------
wire [8:0] prime2_val;
wire       prime2_done;
reg        prime2_be = 0;
reg        prime2_ce = 1;

prime_number_generator gen2 (
    .CLK  (CLK12MHZ),
    .be   (prime2_be),
    .seed (9'd241),
    .ce   (prime2_ce),
    .x    (prime2_val),
    .done (prime2_done)
);

// -------------------------------------------------------------------------
// UART TX - 9600 baud @ 12 MHz
// -------------------------------------------------------------------------
reg        uart_send = 0;
reg  [7:0] uart_data = 0;
wire       uart_busy;

uart_tx #(.CLK_DIV(1250)) utx (
    .CLK  (CLK12MHZ),
    .rst  (rst),
    .send (uart_send),
    .data (uart_data),
    .busy (uart_busy),
    .tx   (uart_rxd_out)
);

// -------------------------------------------------------------------------
// Latched primes
// -------------------------------------------------------------------------
reg [8:0] p1 = 0;
reg [8:0] p2 = 0;

// -------------------------------------------------------------------------
// Decimal digit extraction - combinational, no division in timing path
// -------------------------------------------------------------------------
wire [3:0] p1_h = p1 / 100;
wire [3:0] p1_t = (p1 % 100) / 10;
wire [3:0] p1_u = p1 % 10;

wire [3:0] p2_h = p2 / 100;
wire [3:0] p2_t = (p2 % 100) / 10;
wire [3:0] p2_u = p2 % 10;

// -------------------------------------------------------------------------
// Message ROM - combinational, 18 bytes fixed layout
// "P1: NNN\r\nP2: NNN\r\n"
// -------------------------------------------------------------------------
reg [7:0] msg [0:17];
localparam MSG_LEN = 18;

always @(*) begin
    msg[0]  = "P";
    msg[1]  = "1";
    msg[2]  = ":";
    msg[3]  = " ";
    msg[4]  = "0" + p1_h;
    msg[5]  = "0" + p1_t;
    msg[6]  = "0" + p1_u;
    msg[7]  = 8'h0D;
    msg[8]  = 8'h0A;
    msg[9]  = "P";
    msg[10] = "2";
    msg[11] = ":";
    msg[12] = " ";
    msg[13] = "0" + p2_h;
    msg[14] = "0" + p2_t;
    msg[15] = "0" + p2_u;
    msg[16] = 8'h0D;
    msg[17] = 8'h0A;
end

// -------------------------------------------------------------------------
// Main FSM
//  0 S_RESET      - hold generators in reset
//  1 S_START_GEN1 - pulse be for gen1
//  2 S_WAIT_GEN1  - wait for prime1_done
//  3 S_START_GEN2 - pulse be for gen2
//  4 S_WAIT_GEN2  - wait for prime2_done
//  5 S_SEND_BYTE  - load uart_data, fire uart_send
//  6 S_WAIT_HIGH  - wait uart_busy -> 1 (byte accepted)
//  7 S_WAIT_LOW   - wait uart_busy -> 0 (byte sent)
//  8 S_NEXT_BYTE  - advance index or finish
//  9 S_DONE       - light LED, hold
// -------------------------------------------------------------------------
localparam S_RESET      = 4'd0;
localparam S_START_GEN1 = 4'd1;
localparam S_WAIT_GEN1  = 4'd2;
localparam S_START_GEN2 = 4'd3;
localparam S_WAIT_GEN2  = 4'd4;
localparam S_SEND_BYTE  = 4'd5;
localparam S_WAIT_HIGH  = 4'd6;
localparam S_WAIT_LOW   = 4'd7;
localparam S_NEXT_BYTE  = 4'd8;
localparam S_DONE       = 4'd9;

reg [3:0] state   = S_RESET;
reg [4:0] msg_idx = 0;

always @(posedge CLK12MHZ) begin
    if (rst) begin
        state      <= S_RESET;
        prime1_ce  <= 1;
        prime2_ce  <= 1;
        prime1_be  <= 0;
        prime2_be  <= 0;
        uart_send  <= 0;
        uart_data  <= 0;
        led        <= 0;
        msg_idx    <= 0;
        p1         <= 0;
        p2         <= 0;
    end else begin
        prime1_be <= 0;
        prime2_be <= 0;
        uart_send <= 0;

        case (state)

            S_RESET: begin
                prime1_ce <= 0;
                state     <= S_START_GEN1;
            end

            S_START_GEN1: begin
                prime1_be <= 1;
                state     <= S_WAIT_GEN1;
            end

            S_WAIT_GEN1: begin
                if (prime1_done) begin
                    p1        <= prime1_val;
                    prime2_ce <= 0;
                    state     <= S_START_GEN2;
                end
            end

            S_START_GEN2: begin
                prime2_be <= 1;
                state     <= S_WAIT_GEN2;
            end

            S_WAIT_GEN2: begin
                if (prime2_done) begin
                    p2      <= prime2_val;
                    msg_idx <= 0;
                    state   <= S_SEND_BYTE;
                end
            end

            S_SEND_BYTE: begin
                uart_data <= msg[msg_idx];
                uart_send <= 1;
                state     <= S_WAIT_HIGH;
            end

            S_WAIT_HIGH: begin
                if (uart_busy)
                    state <= S_WAIT_LOW;
            end

            S_WAIT_LOW: begin
                if (!uart_busy)
                    state <= S_NEXT_BYTE;
            end

            S_NEXT_BYTE: begin
                if (msg_idx < MSG_LEN - 1) begin
                    msg_idx <= msg_idx + 1;
                    state   <= S_SEND_BYTE;
                end else begin
                    state <= S_DONE;
                end
            end

            S_DONE: begin
                led <= 1;
            end

        endcase
    end
end

endmodule