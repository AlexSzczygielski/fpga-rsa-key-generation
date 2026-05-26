//-----------------------------------------------------------------------------
// RSA Key Generation Core
// Computes: n, phi(n), e, d for 8-bit primes p and q
//
// Steps:
//   1. n   = p * q                  (16-bit result)
//   2. phi = (p-1) * (q-1)         (16-bit result)
//   3. e   = smallest integer > 1 coprime with phi (try 3,5,7,... via GCD)
//   4. d   = modular inverse of e mod phi (Extended Euclidean Algorithm)
//
// All arithmetic is done combinatorially inside a Moore FSM clocked by CLK.
// The Extended Euclidean Algorithm takes multiple cycles (one per iteration).
//-----------------------------------------------------------------------------

module rsa_keygen
(
    input  wire        CLK,
    input  wire        RSTN,

    // Inputs
    input  wire [7:0]  p,
    input  wire [7:0]  q,
    input  wire        start,

    // Outputs (valid when done=1)
    output reg         done,
    output reg [7:0]   p_out,
    output reg [7:0]   q_out,
    output reg [15:0]  n_out,
    output reg [15:0]  phi_out,
    output reg [15:0]  e_out,
    output reg [15:0]  d_out
);

//-----------------------------------------------------------------------------
// FSM states
//-----------------------------------------------------------------------------
localparam
    S_IDLE          = 4'd0,
    S_CALC_N        = 4'd1,
    S_CALC_PHI      = 4'd2,
    S_FIND_E        = 4'd3,
    S_GCD_INIT      = 4'd4,
    S_GCD_STEP      = 4'd5,
    S_GCD_DONE      = 4'd6,
    S_EXTGCD_INIT   = 4'd7,
    S_EXTGCD_STEP   = 4'd8,
    S_EXTGCD_DONE   = 4'd9,
    S_FIX_D         = 4'd10,
    S_DONE          = 4'd11;

reg [3:0] state;

//-----------------------------------------------------------------------------
// Working registers
//-----------------------------------------------------------------------------
reg [15:0] n;
reg [15:0] phi;
reg [15:0] e_cand;    // e candidate being tested

// GCD working registers (Euclidean algorithm for gcd(e, phi))
reg [15:0] gcd_a;
reg [15:0] gcd_b;
reg [15:0] gcd_r;

// Extended Euclidean working registers
// Computes: old_s * e + old_t * phi = gcd(e, phi)
// When gcd=1, d = old_s mod phi
reg signed [31:0] ext_old_r, ext_r;
reg signed [31:0] ext_old_s, ext_s;
reg signed [31:0] ext_quotient;

//-----------------------------------------------------------------------------
// FSM
//-----------------------------------------------------------------------------
always @(posedge CLK or negedge RSTN) begin
    if(!RSTN) begin
        state    <= S_IDLE;
        done     <= 0;
        p_out    <= 0;
        q_out    <= 0;
        n_out    <= 0;
        phi_out  <= 0;
        e_out    <= 0;
        d_out    <= 0;
        n        <= 0;
        phi      <= 0;
        e_cand   <= 0;
        gcd_a    <= 0;
        gcd_b    <= 0;
        gcd_r    <= 0;
        ext_old_r <= 0;
        ext_r    <= 0;
        ext_old_s <= 0;
        ext_s    <= 0;
        ext_quotient <= 0;
    end else begin
        case(state)

            //------------------------------------------------------------------
            S_IDLE: begin
                done <= 0;
                if(start) begin
                    p_out <= p;
                    q_out <= q;
                    state <= S_CALC_N;
                end
            end

            //------------------------------------------------------------------
            // Step 1: n = p * q
            //------------------------------------------------------------------
            S_CALC_N: begin
                n     <= p * q;
                n_out <= p * q;
                state <= S_CALC_PHI;
            end

            //------------------------------------------------------------------
            // Step 2: phi = (p-1)*(q-1)
            //------------------------------------------------------------------
            S_CALC_PHI: begin
                phi     <= (p - 8'd1) * (q - 8'd1);
                phi_out <= (p - 8'd1) * (q - 8'd1);
                e_cand  <= 16'd3;    // start trying e from 3
                state   <= S_FIND_E;
            end

            //------------------------------------------------------------------
            // Step 3: Find smallest e >= 3, odd, coprime with phi
            // Launch a GCD check on e_cand
            //------------------------------------------------------------------
            S_FIND_E: begin
                // Skip even candidates (e must be odd and > 1)
                if(e_cand[0] == 0)
                    e_cand <= e_cand + 1;
                else begin
                    // init GCD(e_cand, phi)
                    gcd_a <= e_cand;
                    gcd_b <= phi;
                    state <= S_GCD_STEP;
                end
            end

            //------------------------------------------------------------------
            // GCD step: Euclidean algorithm
            // gcd(a,b): while b!=0: (a,b) = (b, a mod b)
            //------------------------------------------------------------------
            S_GCD_STEP: begin
                if(gcd_b == 0) begin
                    state <= S_GCD_DONE;
                end else begin
                    gcd_r <= gcd_a % gcd_b;
                    gcd_a <= gcd_b;
                    gcd_b <= gcd_a % gcd_b;
                end
            end

            //------------------------------------------------------------------
            // GCD done - gcd_a holds result
            //------------------------------------------------------------------
            S_GCD_DONE: begin
                if(gcd_a == 16'd1) begin
                    // found valid e
                    e_out <= e_cand;
                    state <= S_EXTGCD_INIT;
                end else begin
                    // try next odd candidate
                    e_cand <= e_cand + 16'd2;
                    state  <= S_FIND_E;
                end
            end

            //------------------------------------------------------------------
            // Step 4: Extended Euclidean Algorithm to find d = e^-1 mod phi
            //
            // Iterative version of:
            //   input: a=e, b=phi
            //   maintain: old_r=a, r=b, old_s=1, s=0
            //   while r != 0:
            //       q     = old_r / r
            //       (old_r, r)   = (r, old_r - q*r)
            //       (old_s, s)   = (s, old_s - q*s)
            //   result: d = old_s mod phi
            //------------------------------------------------------------------
            S_EXTGCD_INIT: begin
                ext_old_r <= e_cand;   // a
                ext_r     <= phi;      // b
                ext_old_s <= 32'sd1;
                ext_s     <= 32'sd0;
                state     <= S_EXTGCD_STEP;
            end

            S_EXTGCD_STEP: begin
                if(ext_r == 0) begin
                    state <= S_EXTGCD_DONE;
                end else begin
                    ext_quotient <= ext_old_r / ext_r;
                    // (old_r, r) = (r, old_r - q*r)
                    ext_old_r    <= ext_r;
                    ext_r        <= ext_old_r - (ext_old_r / ext_r) * ext_r;
                    // (old_s, s) = (s, old_s - q*s)
                    ext_old_s    <= ext_s;
                    ext_s        <= ext_old_s - (ext_old_r / ext_r) * ext_s;
                end
            end

            //------------------------------------------------------------------
            // ext_old_s is d, but may be negative -> reduce mod phi
            //------------------------------------------------------------------
            S_EXTGCD_DONE: begin
                state <= S_FIX_D;
            end

            S_FIX_D: begin
                if(ext_old_s < 0)
                    d_out <= ext_old_s + phi;
                else
                    d_out <= ext_old_s[15:0];
                state <= S_DONE;
            end

            //------------------------------------------------------------------
            S_DONE: begin
                done <= 1;
                // stay here
            end

            default: state <= S_IDLE;
        endcase
    end
end

endmodule
