//-----------------------------------------------------------------------------
// RSA Key Generation - Proof of Concept
// 8-bit primes p, q -> 16-bit modulus n
// Outputs all intermediate values via UART at 115200 baud
// Target: Kria KV260/KR260, PL fabric clock 100 MHz
//-----------------------------------------------------------------------------

module rsa_top
(
    // inputs
    input  wire CLK,        // 100 MHz PL fabric clock
    input  wire RSTN,       // active-low reset

    // UART output only (TX pin)
    output wire UART_TX
);

//-----------------------------------------------------------------------------
// Hardcoded primes - change these to experiment
// Rules: both must be prime, 4..255 range, p != q
// Good pairs: (7,11), (13,17), (61,53), (127,131) [131 is 8-bit max prime]
//-----------------------------------------------------------------------------
`define P  8'd61
`define Q  8'd53

//-----------------------------------------------------------------------------
// Internal wires
//-----------------------------------------------------------------------------
wire        keygen_done;
wire [7:0]  p_out, q_out;
wire [15:0] n_out;
wire [15:0] phi_out;
wire [15:0] e_out;
wire [15:0] d_out;
wire        keygen_start;

// UART transmitter signals
wire        uart_busy;
reg         uart_send;
reg  [7:0]  uart_data;

//-----------------------------------------------------------------------------
// RSA key generation core
//-----------------------------------------------------------------------------
rsa_keygen keygen_inst (
    .CLK        (CLK),
    .RSTN       (RSTN),
    .p          (`P),
    .q          (`Q),
    .start      (1'b1),         // auto-start on reset release
    .done       (keygen_done),
    .p_out      (p_out),
    .q_out      (q_out),
    .n_out      (n_out),
    .phi_out    (phi_out),
    .e_out      (e_out),
    .d_out      (d_out)
);

//-----------------------------------------------------------------------------
// UART transmitter (115200 baud, 8N1)
//-----------------------------------------------------------------------------
uart_tx #(.CLK_FREQ(100_000_000), .BAUD(115200)) uart_inst (
    .CLK        (CLK),
    .RSTN       (RSTN),
    .send       (uart_send),
    .data       (uart_data),
    .busy       (uart_busy),
    .TX         (UART_TX)
);

//-----------------------------------------------------------------------------
// Print FSM - streams all intermediate values after keygen is done
//-----------------------------------------------------------------------------

// Message ROM - ASCII strings packed as bytes
// Format: "p=XX q=XX n=XXXX phi=XXXX e=XXXX d=XXXX\r\n"
// We build it byte-by-byte in the FSM using hex conversion

localparam
    PRINT_IDLE      = 4'd0,
    PRINT_WAIT_DONE = 4'd1,
    PRINT_STR       = 4'd2,
    PRINT_HEX_H     = 4'd3,
    PRINT_HEX_L     = 4'd4,
    PRINT_HEX_H2    = 4'd5,
    PRINT_HEX_L2    = 4'd6,
    PRINT_NEWLINE   = 4'd7,
    PRINT_DONE      = 4'd8;

// We'll walk through a sequence of (label, value) pairs
// Sequence index:
//  0: "p = 0x"   val = {8'h00, p_out}
//  1: "q = 0x"   val = {8'h00, q_out}
//  2: "n = 0x"   val = n_out
//  3: "phi= 0x"  val = phi_out
//  4: "e = 0x"   val = e_out
//  5: "d = 0x"   val = d_out

reg [3:0]  print_state;
reg [3:0]  seq_idx;        // which variable we're printing (0-5)
reg [4:0]  char_idx;       // index within a label string
reg [15:0] cur_val;        // current value to print as hex
reg        done_latched;

// label ROM: 6 labels, up to 8 chars each, 0x00 terminated
// "p=0x", "q=0x", "n=0x", "f=0x" (phi), "e=0x", "d=0x"
reg [7:0] label_rom [0:5][0:7];
integer li;
initial begin
    // p=0x
    label_rom[0][0] = "p"; label_rom[0][1] = "="; label_rom[0][2] = "0";
    label_rom[0][3] = "x"; label_rom[0][4] = 0;
    // q=0x
    label_rom[1][0] = "q"; label_rom[1][1] = "="; label_rom[1][2] = "0";
    label_rom[1][3] = "x"; label_rom[1][4] = 0;
    // n=0x
    label_rom[2][0] = "n"; label_rom[2][1] = "="; label_rom[2][2] = "0";
    label_rom[2][3] = "x"; label_rom[2][4] = 0;
    // phi=0x
    label_rom[3][0] = "p"; label_rom[3][1] = "h"; label_rom[3][2] = "i";
    label_rom[3][3] = "="; label_rom[3][4] = "0"; label_rom[3][5] = "x";
    label_rom[3][6] = 0;
    // e=0x
    label_rom[4][0] = "e"; label_rom[4][1] = "="; label_rom[4][2] = "0";
    label_rom[4][3] = "x"; label_rom[4][4] = 0;
    // d=0x
    label_rom[5][0] = "d"; label_rom[5][1] = "="; label_rom[5][2] = "0";
    label_rom[5][3] = "x"; label_rom[5][4] = 0;
end

// hex nibble -> ASCII
function [7:0] nibble_to_ascii;
    input [3:0] n;
    begin
        if(n < 4'd10)
            nibble_to_ascii = "0" + n;
        else
            nibble_to_ascii = "a" + (n - 4'd10);
    end
endfunction

always @(posedge CLK or negedge RSTN) begin
    if(!RSTN) begin
        print_state  <= PRINT_WAIT_DONE;
        seq_idx      <= 0;
        char_idx     <= 0;
        cur_val      <= 0;
        done_latched <= 0;
        uart_send    <= 0;
        uart_data    <= 0;
    end else begin
        uart_send <= 0;  // default: don't send

        case(print_state)

            PRINT_WAIT_DONE: begin
                if(keygen_done)
                    print_state <= PRINT_STR;
            end

            // Send label characters one by one
            PRINT_STR: begin
                if(!uart_busy && !uart_send) begin
                    if(label_rom[seq_idx][char_idx] == 0) begin
                        // Label done, now send the hex value
                        // Load current value
                        case(seq_idx)
                            0: cur_val <= {8'h00, p_out};
                            1: cur_val <= {8'h00, q_out};
                            2: cur_val <= n_out;
                            3: cur_val <= phi_out;
                            4: cur_val <= e_out;
                            5: cur_val <= d_out;
                            default: cur_val <= 0;
                        endcase
                        char_idx    <= 0;
                        print_state <= PRINT_HEX_H2;
                    end else begin
                        uart_data   <= label_rom[seq_idx][char_idx];
                        uart_send   <= 1;
                        char_idx    <= char_idx + 1;
                    end
                end
            end

            // Send upper byte high nibble
            PRINT_HEX_H2: begin
                if(!uart_busy && !uart_send) begin
                    uart_data   <= nibble_to_ascii(cur_val[15:12]);
                    uart_send   <= 1;
                    print_state <= PRINT_HEX_L2;
                end
            end

            // Send upper byte low nibble
            PRINT_HEX_L2: begin
                if(!uart_busy && !uart_send) begin
                    uart_data   <= nibble_to_ascii(cur_val[11:8]);
                    uart_send   <= 1;
                    print_state <= PRINT_HEX_H;
                end
            end

            // Send lower byte high nibble
            PRINT_HEX_H: begin
                if(!uart_busy && !uart_send) begin
                    uart_data   <= nibble_to_ascii(cur_val[7:4]);
                    uart_send   <= 1;
                    print_state <= PRINT_HEX_L;
                end
            end

            // Send lower byte low nibble then newline
            PRINT_HEX_L: begin
                if(!uart_busy && !uart_send) begin
                    uart_data   <= nibble_to_ascii(cur_val[3:0]);
                    uart_send   <= 1;
                    print_state <= PRINT_NEWLINE;
                end
            end

            PRINT_NEWLINE: begin
                if(!uart_busy && !uart_send) begin
                    uart_data <= 8'h0D;   // \r
                    uart_send <= 1;
                    if(seq_idx == 5) begin
                        print_state <= PRINT_DONE;
                    end else begin
                        seq_idx     <= seq_idx + 1;
                        char_idx    <= 0;
                        print_state <= PRINT_STR;
                    end
                end
            end

            PRINT_DONE: begin
                // idle - done printing
            end

            default: print_state <= PRINT_WAIT_DONE;
        endcase
    end
end

endmodule
