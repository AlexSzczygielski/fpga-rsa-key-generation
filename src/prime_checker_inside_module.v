`timescale 1ns / 1ps

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
    
    reg [3:0] state = 0;
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
    
    always @(posedge CLK) begin
        if(be == 1) begin
            number      <= candidate;
            s           <= in_s;
            d           <= in_d;
            state       <= 0;
            i           <= 0;
            is_prime    <= 0;
            ready       <= 0;
            begin_power <= 0;
        end else begin
            if(state == 0) begin
                a        <= result;
                state    <= 1;
                base     <= result;
                exponent <= d;
            end 
            
            else if(state == 1) begin
                if(a > 1 && a < number - 1) begin
                    begin_power <= 1; // Wysy³amy impuls startu
                    state       <= 2;
                end else begin
                    state       <= 0; // Losuj ponownie
                end
            end 
            
            else if(state == 2) begin
                begin_power <= 0; // Gasimy impuls w kolejnym takcie
                // Czekamy na pow_ready, upewniaj¹c siê, ¿e modu³ pow zd¹¿y³ zresetowaæ swój gotowoœæ po odebraniu be
                if(pow_ready == 1 && begin_power == 0) begin
                    x     <= pov_result;
                    state <= 3;
                end
            end 
            
            else if(state == 3) begin
                if(x == 1 || x == number - 1) begin
                    is_prime <= 1;
                    ready    <= 1;
                    state    <= 8;
                end else begin
                    state <= 4;
                end
            end 
            
            else if(state == 4) begin
                base        <= x;
                exponent    <= 2;
                begin_power <= 1; // Wymuszamy kwadrat modulo
                state       <= 5;
            end 
            
            else if(state == 5) begin
                begin_power <= 0; // Gasimy impuls startu
                if(pow_ready == 1 && begin_power == 0) begin
                    x     <= pov_result;
                    state <= 6;
                end
            end 
            
            else if(state == 6) begin
                if(x == number - 1) begin
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
                        state <= 4; // Kolejny obieg pêtli
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