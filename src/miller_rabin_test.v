`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.05.2026 20:59:06
// Design Name: 
// Module Name: miller_rabin_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module miller_rabin_test(
    input wire [8:0] candidate,
    input wire be,
    input wire CLK,
    input wire ce,
    output reg is_prime,
    output reg ready
    );
    
    
    reg started = 0;
    reg [8:0] d = 0;
    reg [8:0] s = 0;
    reg [1:0] state = 0;
    
    reg [3:0] i;
    reg inside_begin;
    wire inside_ready;
    wire inside_is_prime;
    prime_checker_inside_module inside_module(
        .CLK (CLK),
        .candidate (candidate),
        .be (inside_begin),
        .in_s (s),
        .in_d (d),
        .ce (1'b0),
        .is_prime (inside_is_prime),
        .ready (inside_ready)
    );
    
    always @(posedge CLK)begin
        if(be == 1)begin
            started <= 0;
            ready <= 0;
            i <= 0;
            inside_begin <= 0;
        end else if (started == 0)begin
            i <= 0;
            inside_begin <= 0;
            if (candidate == 1 || candidate == 4)begin
                is_prime <= 0;
                ready <= 1;
                started <= 1;
            end else if (candidate == 3)begin
               is_prime <= 1;
               ready <= 1;
               started <= 1;
            end else if (candidate % 2 == 0)begin
                is_prime <= 0;
                ready <= 1;
                started <= 1;
            end else begin
                started <= 1;
                d <= candidate - 1;
                s <= 0;
                state <= 0;
            end
        end else begin
            if(state == 0)begin
                if(d % 2 == 0)begin
                    d <= d >> 1;
                    s <= s + 1;
                end else begin
                    inside_begin <= 1;
                    state <= 1;
                end
            end else if(state == 1)begin
                inside_begin <= 0;
                if(inside_ready == 1)begin
                    if(inside_is_prime == 1)begin
                        i <= i + 1;
                        if(i < 14)begin
                            inside_begin <= 1;
                        end else begin
                            is_prime <= 1;
                            ready <= 1;
                        end
                    end else begin
                        is_prime <= 0;
                        ready <= 1;
                    end
                end
            end
        end
    end
endmodule
