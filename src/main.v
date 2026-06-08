`timescale 1ns / 1ps

module prime_number_generator
(
    input wire CLK,
    input wire be,
    input wire [8:0] seed,
    output reg[8:0] x,
    output reg done,
    input wire ce
);

wire [8:0] result;
reg  [8:0] candidate;

random_number_generator generator(
    .seed (seed),
    .ce (ce),
    .CLK (CLK),
    .result (result)
);

//0 <-- idle
//1 <-- generating
//2 <-- testing
//3 <-- done
reg [1:0] state = 0;

wire ready;
wire is_prime;
reg test_begin;
miller_rabin_test prime_test(
    .candidate (candidate),
    .be (test_begin),
    .CLK (CLK),
    .ce (ce),
    .is_prime (is_prime),
    .ready (ready)
);

always @(posedge CLK)begin
    if(ce == 1)begin
        done <= 0;
    end else begin
        if(state == 0)begin
            done <= 0;
            if(be == 1)begin
                state <= 1;
            end
        end else if(state == 1)begin
            candidate <= result;
            test_begin <= 1; 
            state <= 2;     
        end else if(state == 2)begin
            test_begin <= 0; 
            if(ready == 1)begin
                if(is_prime == 1)begin
                    state = 3;
                end else begin
                    state = 1;
                end
            end
        end else if(state == 3)begin
            x <= candidate;
            done <= 1;
            state <= 0;
        end
    end
end

endmodule
