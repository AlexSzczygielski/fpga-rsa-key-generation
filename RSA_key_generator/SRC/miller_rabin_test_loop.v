`timescale 1ns / 1ps

module miller_rabin_test_loop(
        input wire CLK,
        input wire start,
        input wire clear,
        input wire [7:0] in_candidate,
        input wire [7:0] in_s,
        input wire [7:0] in_d,
        output reg is_prime,
        output reg ready
    );
    
    reg [7:0] state;
    reg [7:0] candidate;
    reg [7:0] s;
    reg [7:0] d;
    
    reg [7:0] seed = 8'h1F;
    wire [7:0] random_number;

    random_number_generator random_generator_module(
        .CLK (CLK),
        .seed (seed),
        .clear (clear),
        .out_result (random_number)
    );
    
    reg power_operation_start;
    reg [7:0] base;
    reg [7:0] exponent;
    wire power_operation_ready;
    wire [7:0] power_operation_result;
    
    power_operation power_module(
        .CLK (CLK),
        .start (power_operation_start),
        .clear (clear),
        .in_base (base),
        .in_exponent (exponent),
        .in_modulo_base (candidate),
        .out_result (power_operation_result),
        .ready (power_operation_ready)
    );
    
    reg [7:0] a;
    reg [7:0] x;
    reg [7:0] i; 
    
    always @(posedge CLK) begin
        if(start == 1) begin
            candidate      <= in_candidate;
            s           <= in_s;
            d           <= in_d;
            state       <= 0;
            i           <= 0;
            is_prime    <= 0;
            ready       <= 0;
            power_operation_start <= 0;
        end else begin
            if(state == 0) begin
                state <= 1;
            end 
            
            else if(state == 1) begin
                if(random_number > 1 && random_number < candidate - 1) begin
                    a        <= random_number;
                    base     <= random_number;
                    exponent <= d;
                    power_operation_start <= 1;
                    state       <= 2;
                end else begin
                    state       <= 0;
                end
            end 
            
            else if(state == 2) begin
                power_operation_start <= 0;
                if(power_operation_ready == 1 && power_operation_start == 0) begin
                    x     <= power_operation_result;
                    state <= 3;
                end
            end 
            
            else if(state == 3) begin
                if(x == 1 || x == candidate - 1) begin
                    is_prime <= 1;
                    ready    <= 1;
                    state    <= 8;
                end else if(s == 1)begin
                    is_prime <=0;
                    ready <= 1;
                    state <= 8;
                end else begin
                    i <= 0;
                    state <= 4;
                end
            end 
            
            else if(state == 4) begin
                base        <= x;
                exponent    <= 2;
                power_operation_start <= 1;
                state       <= 5;
            end 
            
            else if(state == 5) begin
                power_operation_start <= 0;
                if(power_operation_ready == 1 && power_operation_start == 0) begin
                    x     <= power_operation_result;
                    state <= 6;
                end
            end 
            
            else if(state == 6) begin
                if(x == candidate - 1) begin
                    is_prime <= 1;
                    ready    <= 1;
                    state    <= 8;
                end else if(x == 1) begin
                    is_prime <= 0;
                    ready    <= 1;
                    state    <= 8;
                end else begin
                    i <= i + 1;
                    if((i + 1) < s - 1) begin
                        state <= 4;
                    end else begin
                        is_prime <= 0;
                        ready    <= 1;
                        state    <= 8;
                    end
                end
            end
            
            else if(state == 8) begin
                ready <= 1;
            end
        end
    end
endmodule