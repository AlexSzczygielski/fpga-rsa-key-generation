`timescale 1ns / 1ps

module prime_number_generator
(
    input wire CLK,
    input wire start,
    input wire clear,
    output reg [7:0] out_result,
    output reg ready
);

wire [7:0] random_number;
reg  [7:0] candidate;
wire [7:0] seed = 8'h4B;

random_number_generator generator(
    .CLK (CLK),
    .seed (seed),
    .clear (clear),
    .out_result (random_number)
);

//0 <-- idle
//1 <-- generating
//2 <-- testing
//3 <-- done
reg [2:0] state = 0;

wire miller_rabin_test_ready;
wire is_prime;
reg miller_rabin_test_start;
miller_rabin_test prime_test(
    .CLK (CLK),
    .start (miller_rabin_test_start),
    .clear (clear),
    .in_candidate (candidate),
    .is_prime (is_prime),
    .ready (miller_rabin_test_ready)
);

always @(posedge CLK)begin
    if(clear == 1)begin
        ready <= 0;
    end else begin
        if(state == 0)begin
            ready <= 0;
            if(start == 1)begin
                state <= 1;
            end
        end else if(state == 1)begin
            candidate <= random_number;
            state <= 2;
        end else if(state == 2)begin
            miller_rabin_test_start <= 1;
            state <= 3;
        end else if(state == 3)begin
            miller_rabin_test_start <= 0;
            state <= 4;
        end else if(state == 4)begin
            if(miller_rabin_test_ready == 1)begin
                if(is_prime == 1)begin
                    state <= 5;
                end else begin
                    state <= 1;
                end
            end
        end else if(state == 5)begin
            out_result <= candidate;
            ready <= 1;
            state <= 0;
        end
    end
end

endmodule
