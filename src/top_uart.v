`timescale 1ns / 1ps

// Top-level for Arty S7-50
// Clock: 12 MHz (F14)
// UART TX: R12, 9600 baud
// Reset: ck_rst (C18, active-low)
// LED[0] (E18): pulses when both primes have been sent
//
// Behaviour: on reset release, generate prime P1 (seed=105), then P2 (seed=241),
// print "P1: NNN\r\nP2: NNN\r\n" over UART at 9600 8N1, then hold.

module top_uart (
    input  wire CLK12MHZ,
    input  wire ck_rst,       // active-low reset button
    output wire uart_rxd_out, // UART TX to PC (misleading Digilent name)
    output reg  led           // LED[0] — done indicator
);

// -------------------------------------------------------------------------
// Reset synchroniser (active-high internal reset)
// -------------------------------------------------------------------------
reg rst_sync0 = 1, rst_sync1 = 1;
always @(posedge CLK12MHZ) begin
    rst_sync0 <= ~ck_rst;
    rst_sync1 <= rst_sync0;
end
wire rst = rst_sync1;

// -------------------------------------------------------------------------
// Prime generator #1  (seed = 105)
// -------------------------------------------------------------------------
wire [8:0] prime1_val;
wire       prime1_done;
reg        prime1_be  = 0;
reg        prime1_ce  = 1;   // hold in reset initially

prime_number_generator gen1 (
    .CLK  (CLK12MHZ),
    .be   (prime1_be),
    .seed (9'd105),
    .ce   (prime1_ce),
    .x    (prime1_val),
    .done (prime1_done)
);

// -------------------------------------------------------------------------
// Prime generator #2  (seed = 241)
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
// UART TX
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
// Message buffer
// "P1: NNN\r\nP2: NNN\r\n" = 20 bytes max
// Built dynamically once primes are known.
// -------------------------------------------------------------------------
reg [7:0] msg [0:19];
reg [4:0] msg_len  = 0;
reg [4:0] msg_idx  = 0;

// -------------------------------------------------------------------------
// BCD helpers — split 9-bit value (0..511) into hundreds/tens/ones
// -------------------------------------------------------------------------
reg [8:0] bcd_in;
reg [3:0] bcd_h, bcd_t, bcd_u;

task calc_bcd;
    input [8:0] val;
    begin
        bcd_h = val / 100;
        bcd_t = (val % 100) / 10;
        bcd_u = val % 10;
    end
endtask

// -------------------------------------------------------------------------
// Latched prime results
// -------------------------------------------------------------------------
reg [8:0] p1 = 0;
reg [8:0] p2 = 0;

// -------------------------------------------------------------------------
// Main FSM
// -------------------------------------------------------------------------
localparam S_RESET      = 4'd0;
localparam S_START_GEN1 = 4'd1;
localparam S_WAIT_GEN1  = 4'd2;
localparam S_START_GEN2 = 4'd3;
localparam S_WAIT_GEN2  = 4'd4;
localparam S_BUILD_MSG  = 4'd5;
localparam S_SEND_BYTE  = 4'd6;
localparam S_WAIT_UART  = 4'd7;
localparam S_NEXT_BYTE  = 4'd8;
localparam S_DONE       = 4'd9;

reg [3:0] state = S_RESET;

// Message builder — writes into msg[] and sets msg_len
// Called combinatorially from S_BUILD_MSG
integer bi;
task build_message;
    input [8:0] v1;
    input [8:0] v2;
    reg [3:0] h, t, u;
    reg suppress;
    begin
        bi = 0;

        // "P1: "
        msg[bi] = "P"; bi = bi + 1;
        msg[bi] = "1"; bi = bi + 1;
        msg[bi] = ":"; bi = bi + 1;
        msg[bi] = " "; bi = bi + 1;

        // v1 decimal (suppress leading zeros but always print at least one digit)
        h = v1 / 100;
        t = (v1 % 100) / 10;
        u = v1 % 10;
        suppress = 1;
        if (h != 0) begin msg[bi] = "0" + h; bi = bi + 1; suppress = 0; end
        if (t != 0 || !suppress) begin msg[bi] = "0" + t; bi = bi + 1; suppress = 0; end
        msg[bi] = "0" + u; bi = bi + 1;

        // "\r\n"
        msg[bi] = 8'h0D; bi = bi + 1;
        msg[bi] = 8'h0A; bi = bi + 1;

        // "P2: "
        msg[bi] = "P"; bi = bi + 1;
        msg[bi] = "2"; bi = bi + 1;
        msg[bi] = ":"; bi = bi + 1;
        msg[bi] = " "; bi = bi + 1;

        // v2 decimal
        h = v2 / 100;
        t = (v2 % 100) / 10;
        u = v2 % 10;
        suppress = 1;
        if (h != 0) begin msg[bi] = "0" + h; bi = bi + 1; suppress = 0; end
        if (t != 0 || !suppress) begin msg[bi] = "0" + t; bi = bi + 1; suppress = 0; end
        msg[bi] = "0" + u; bi = bi + 1;

        // "\r\n"
        msg[bi] = 8'h0D; bi = bi + 1;
        msg[bi] = 8'h0A; bi = bi + 1;

        msg_len = bi;
    end
endtask

always @(posedge CLK12MHZ) begin
    if (rst) begin
        state      <= S_RESET;
        prime1_ce  <= 1;
        prime2_ce  <= 1;
        prime1_be  <= 0;
        prime2_be  <= 0;
        uart_send  <= 0;
        led        <= 0;
        msg_idx    <= 0;
        msg_len    <= 0;
    end else begin
        // Default: deassert single-cycle pulses
        prime1_be <= 0;
        prime2_be <= 0;
        uart_send <= 0;

        case (state)

            S_RESET: begin
                prime1_ce <= 0;   // release reset on gen1
                state     <= S_START_GEN1;
            end

            S_START_GEN1: begin
                prime1_be <= 1;   // one-cycle start pulse
                state     <= S_WAIT_GEN1;
            end

            S_WAIT_GEN1: begin
                if (prime1_done) begin
                    p1        <= prime1_val;
                    prime2_ce <= 0;   // release reset on gen2
                    state     <= S_START_GEN2;
                end
            end

            S_START_GEN2: begin
                prime2_be <= 1;
                state     <= S_WAIT_GEN2;
            end

            S_WAIT_GEN2: begin
                if (prime2_done) begin
                    p2    <= prime2_val;
                    state <= S_BUILD_MSG;
                end
            end

            S_BUILD_MSG: begin
                build_message(p1, p2);
                msg_idx <= 0;
                state   <= S_SEND_BYTE;
            end

            S_SEND_BYTE: begin
                if (!uart_busy) begin
                    uart_data <= msg[msg_idx];
                    uart_send <= 1;
                    state     <= S_WAIT_UART;
                end
            end

            S_WAIT_UART: begin
                // Wait for uart_busy to go high (transmission started),
                // then fall through to S_NEXT_BYTE which waits for it to go low.
                if (uart_busy) begin
                    state <= S_NEXT_BYTE;
                end
            end

            S_NEXT_BYTE: begin
                if (!uart_busy) begin
                    if (msg_idx + 1 < msg_len) begin
                        msg_idx <= msg_idx + 1;
                        state   <= S_SEND_BYTE;
                    end else begin
                        state <= S_DONE;
                    end
                end
            end

            S_DONE: begin
                led <= 1;
                // Stay here forever until reset
            end

        endcase
    end
end

endmodule
