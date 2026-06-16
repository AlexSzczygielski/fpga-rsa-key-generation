`timescale 1ns / 1ps

module miller_rabin_test(
    input wire CLK,
    input wire start,
    input wire clear,
    input wire [7:0] in_candidate,
    output reg is_prime,
    output reg ready
    );
    
    reg started = 0;
    reg [7:0] d = 0;
    reg [7:0] s = 0;
    reg [2:0] state = 0;
    reg initial_checks = 0;
    
    reg [3:0] i = 0; 
    reg test_loop_start;
    wire test_loop_ready;
    wire test_loop_is_prime;
    
    miller_rabin_test_loop miller_rabin_loop_module(
        .CLK (CLK),
        .start (test_loop_start),
        .clear (clear),
        .in_candidate (in_candidate),
        .in_s (s),
        .in_d (d),
        .is_prime (test_loop_is_prime),
        .ready (test_loop_ready)
    );
    
    always @(posedge CLK) begin
        if(clear == 1) begin
            started <= 0;
            ready <= 0;
            i <= 0;
            test_loop_start <= 0;
            initial_checks <= 0;
            is_prime <= 0;
            state <= 0;
        end else if(start == 1) begin
            started <= 1;
            ready <= 0;
            i <= 0;
            test_loop_start <= 0;
            initial_checks <= 0;
            is_prime <= 0;
            state <= 0;
        end else if(started == 1) begin
            if (initial_checks == 0) begin
                if (in_candidate == 1 || in_candidate == 4) begin
                    is_prime <= 0;
                    ready <= 1;
                    started <= 0; 
                end else if (in_candidate == 3 || in_candidate == 2) begin
                   is_prime <= 1;
                   ready <= 1;
                   started <= 0;  
                end else if (in_candidate % 2 == 0) begin
                    is_prime <= 0;
                    ready <= 1;
                    started <= 0; 
                end else begin
                    d <= in_candidate - 1;
                    s <= 0;
                    state <= 0;
                    initial_checks <= 1;
                end
            end else begin
                if(state == 0) begin
                    if(d % 2 == 0) begin
                        d <= d >> 1;
                        s <= s + 1;
                    end else begin
                        test_loop_start <= 1;
                        state <= 1;
                    end
                end 
                
                else if(state == 1) begin
                    test_loop_start <= 0;
                    state <= 2;
                end 
                
                else if(state == 2) begin
                    if(test_loop_ready == 1) begin
                        if(test_loop_is_prime == 1) begin
                            if(i < 2) begin
                                i <= i + 1;
                                test_loop_start <= 1;
                                state <= 1;
                            end else begin
                                is_prime <= 1;
                                ready <= 1;
                                started <= 0;      
                            end
                        end else begin
                            is_prime <= 0;
                            ready <= 1;
                            started <= 0;          
                        end
                    end
                end
            end
        end
    end
endmodule