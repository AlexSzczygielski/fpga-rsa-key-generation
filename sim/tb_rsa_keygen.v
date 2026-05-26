//-----------------------------------------------------------------------------
// Testbench for rsa_keygen.v
// Simulates p=61, q=53 -> expected: n=3233, phi=3120, e=17, d=2753
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_rsa_keygen;

reg        CLK;
reg        RSTN;
wire       done;
wire [7:0] p_out, q_out;
wire [15:0] n_out, phi_out, e_out, d_out;

rsa_keygen dut (
    .CLK     (CLK),
    .RSTN    (RSTN),
    .p       (8'd61),
    .q       (8'd53),
    .start   (1'b1),
    .done    (done),
    .p_out   (p_out),
    .q_out   (q_out),
    .n_out   (n_out),
    .phi_out (phi_out),
    .e_out   (e_out),
    .d_out   (d_out)
);

// 10 ns clock (100 MHz)
initial CLK = 0;
always #5 CLK = ~CLK;

initial begin
    $dumpfile("tb_rsa_keygen.vcd");
    $dumpvars(0, tb_rsa_keygen);

    RSTN = 0;
    #30;
    RSTN = 1;

    // Wait for done with timeout
    repeat(100000) begin
        @(posedge CLK);
        if(done) begin
            $display("-----------------------------");
            $display("RSA Key Generation Results");
            $display("-----------------------------");
            $display("p       = %0d (0x%02h)", p_out, p_out);
            $display("q       = %0d (0x%02h)", q_out, q_out);
            $display("n       = %0d (0x%04h)", n_out, n_out);
            $display("phi(n)  = %0d (0x%04h)", phi_out, phi_out);
            $display("e       = %0d (0x%04h)", e_out, e_out);
            $display("d       = %0d (0x%04h)", d_out, d_out);
            $display("-----------------------------");
            $display("Verify: (e*d) mod phi = %0d  [should be 1]",
                     (e_out * d_out) % phi_out);
            $display("Verify: encrypt(42) = %0d^%0d mod %0d",
                     42, e_out, n_out);
            $finish;
        end
    end

    $display("TIMEOUT - keygen did not complete");
    $finish;
end

endmodule
