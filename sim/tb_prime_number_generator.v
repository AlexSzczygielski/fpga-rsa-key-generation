`timescale 1ns/1ps

module tb_prime_number_generator;

reg        CLK;
reg        be;
reg [8:0]  seed;
reg        ce;
wire [8:0] x;
wire       done;

prime_number_generator dut (
    .CLK  (CLK),
    .be   (be),
    .seed (seed),
    .x    (x),
    .done (done),
    .ce   (ce)
);

initial CLK = 0;
always #5 CLK = ~CLK;

// Trial-division primality check for use in simulation only
function is_prime;
    input [8:0] n;
    integer i;
    reg result;
    begin
        if (n < 9'd2)       result = 1'b0;
        else if (n == 9'd2) result = 1'b1;
        else if (n[0] == 0) result = 1'b0;
        else begin
            result = 1'b1;
            for (i = 3; i*i <= n; i = i + 2)
                if (n % i == 0) result = 1'b0;
        end
        is_prime = result;
    end
endfunction

integer pass_count;

task run_test;
    input [8:0] test_seed;
    input integer id;
    integer timeout;
    begin
        // Reset: assert ce to reload seed into RNG
        ce = 1'b1;
        be = 1'b0;
        seed = test_seed;
        repeat(5) @(posedge CLK);
        ce = 1'b0;
        repeat(2) @(posedge CLK);

        // Trigger prime generation
        @(posedge CLK);
        be = 1'b1;
        @(posedge CLK);
        be = 1'b0;

        // Wait for done (1-cycle pulse)
        timeout = 0;
        while (!done && timeout < 200000) begin
            @(posedge CLK);
            timeout = timeout + 1;
        end

        if (timeout >= 200000) begin
            $display("TIMEOUT: test %0d seed=%0d", id, test_seed);
        end else if (is_prime(x)) begin
            $display("PASS: test %0d seed=%0d -> x=%0d is prime", id, test_seed, x);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: test %0d seed=%0d -> x=%0d is NOT prime", id, test_seed, x);
        end
    end
endtask

initial begin
    $dumpfile("tb_prime_number_generator.vcd");
    $dumpvars(0, tb_prime_number_generator);

    pass_count = 0;

    run_test(9'd37,  1);
    run_test(9'd101, 2);
    run_test(9'd199, 3);
    run_test(9'd251, 4);
    run_test(9'd13,  5);

    $display("--- %0d/5 tests passed ---", pass_count);
    $finish;
end

endmodule
