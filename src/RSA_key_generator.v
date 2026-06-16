`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 20:40:57
// Design Name: 
// Module Name: RSA_key_generator
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


module RSA_key_generator(
        input wire CLK,
        input wire start,
        input wire clear,
        output reg [15:0] out_n,
        output reg [15:0] out_e,
        output reg [15:0] out_d,
        output reg ready
    );
    
    reg [7:0] p;
    reg [7:0] q;
    reg [15:0] euler_function;
    
    wire prime_number_ready;
    wire [7:0] prime_number;
    reg prime_number_generator_start;
    prime_number_generator prime_number_generator_module(
        .CLK (CLK),
        .start (prime_number_generator_start),
        .clear (clear),
        .out_result (prime_number),
        .ready (prime_number_ready)
    );
    
    wire [15:0] random_number;
    wire [15:0] seed = 16'h1234;
    x2_random_number_generator generator(
        .CLK (CLK),
        .seed (seed),
        .clear (clear),
        .out_result (random_number)
    );
    
    reg euclidean_algorithm_start;
    wire [15:0] euclidean_algorithm_result;
    wire euclidean_algorithm_ready;
    wire wrong_e;
    euclidean_algorithm euclidean_algorithm_module(
        .CLK (CLK),
        .start (euclidean_algorithm_start),
        .clear (clear),
        .in_e (out_e),
        .in_euler_function (euler_function),
        .out_d (euclidean_algorithm_result),
        .wrong_e (wrong_e), //e musi byæ wzglêdnie pierwsze z d czyli wynikiem tego algorytmu
        .ready (euclidean_algorithm_ready)
    );
    
    reg [4:0] state;
    // 0 -> waiting for start
    
    always @(posedge CLK)begin
        if(clear)begin
            state <= 0;
            prime_number_generator_start <= 0;
            euclidean_algorithm_start <= 0;
            ready <= 0;
        end else begin
            if(state == 0)begin //oczekiwanie na start
                if(start == 1)begin
                    state <= 1;
                    ready <= 0;
                end
            end else if(state == 1)begin // w³¹czenie generatora liczb pierwszych dla p
                prime_number_generator_start <= 1;
                state <= 2;
            end else if(state == 2)begin // wy³¹czenie generatora liczb pierwszych dla p
                prime_number_generator_start <= 0;
                state <= 3;
            end else if(state == 3)begin // oczekiwanie na p
                if(prime_number_ready == 1)begin
                    p <= prime_number;
                    state <= 4;
                end
            end else if(state == 4)begin // w³¹czenie generatora liczb pierwszych dla q
                prime_number_generator_start <= 1;
                state <= 5;
            end else if(state == 5)begin // wy³¹czenie generatora liczb pierwszych dla q
                prime_number_generator_start <= 0;
                state <= 6;
            end else if(state == 6)begin //oczekiwanie na q oraz obliczanie funkcji eulera i n
                if(prime_number_ready == 1)begin
                    q <= prime_number;
                    euler_function <= (p - 1) * (prime_number - 1);
                    out_n <= p * prime_number;
                    state <= 7;
                end
            end else if(state == 7)begin //generacja e
                if(random_number> 1 && random_number < euler_function)begin
                    out_e <= random_number;
                    state <= 8;
                end
            end else if(state == 8)begin //w³¹czenie algorytmu eukledesa
                euclidean_algorithm_start <= 1;
                state <= 9;
            end else if(state == 9)begin //wy³¹czenie algorytmu eukledesa
                euclidean_algorithm_start <= 0;
                state <= 10;
            end else if(state == 10)begin //oczekiwanie na wynik i ostateczne warunki algorytmu
                if(euclidean_algorithm_ready == 1)begin
                    if(wrong_e == 1)begin
                        state <= 7;
                    end else begin
                        out_d <= euclidean_algorithm_result;
                        ready <= 1;
                        state <= 0;
                    end
                end
            end
        end
    end
    
endmodule
