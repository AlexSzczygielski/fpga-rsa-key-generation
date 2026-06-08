`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.06.2026 18:37:31
// Design Name: 
// Module Name: prime_checker_inside_module
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


module prime_checker_inside_module(
        input wire CLK,
        input wire [8:0] candidate,
        input wire be,
        input wire [8:0] in_s,
        input wire [8:0] in_d,
        input wire ce,
        output reg is_prime,
        output reg ready
    );
    
    reg [2:0] state = 0;
    reg [8:0] number = 0;
    reg [8:0] s = 0;
    reg [8:0] d = 0;
    
    reg [8:0] seed = 5782;
    wire [8:0] result;

    random_number_generator generator(
        .seed (seed),
        .ce (ce),
        .CLK (CLK),
        .result (result)
    );
    
    reg begin_power;
    reg [8:0] base;
    reg [8:0] exponent;
    wire pow_ready;
    wire [8:0] pov_result;
    pow power(
        .be (begin_power),
        .in_base (base),
        .in_exponent (exponent),
        .n (number),
        .CLK (CLK),
        .ready (pow_ready),
        .out_result (pov_result)
    );
    
    reg [8:0] a;
    reg [8:0] x;
    
    reg [8:0] i; 
    
    always @(posedge CLK)begin
        if(be == 1)begin
            number <= candidate;
            s <= in_s;
            d <= in_d;
            state <= 0;
            i <= 0;
            is_prime <= 0;
            ready <= 0;
        end else begin
            if(state == 0)begin //tutaj ewentualnie da� begin poewr do nast�pnego stanu �eby mie� pewno�� �� liczy na dobrych danych
                a <= result;
                state <= 1;
                base <= result;
                exponent <= d;
                begin_power <= 1;
            end else if(state == 1)begin
                begin_power <= 0;
                if(pow_ready == 1)begin
                    x <= pov_result;
                    state <= 2;
                end
            end else if(state == 2)begin
                if(x == 1 || x == number - 1)begin
                    is_prime <= 1;
                    ready <= 1;
                    state <= 7;
                end else begin
                    state <= 3;
                end
            end else if(state == 3)begin    //tutaj zaczynamy p�tle
                base <= x;
                exponent <= 2;
                begin_power <= 1;
                state <= 4;
            end else if(state == 4)begin
                begin_power <= 0;
                if(pow_ready == 1)begin
                    x <= pov_result;
                    state <= 5;
                end
            end else if(state == 5)begin
                if(x == number - 1)begin
                    is_prime <= 1;
                    ready <= 1;
                    state <= 7;
                end
                if(x == 1)begin
                    is_prime <= 0;
                    ready <= 1;
                    state <= 7;
                end
                i <= i + 1;
                if(i < s - 1)begin
                    state <= 3;
                end else begin
                    is_prime <= 0;
                    ready <= 1;
                    state <= 7;
                end
            end
        end
    end
endmodule
