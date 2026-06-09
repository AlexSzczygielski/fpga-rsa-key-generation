`timescale 1ns / 1ps

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
    reg initial_checks = 0;
    
    reg [3:0] i = 0; // Dodana inicjalizacja zerem
    reg inside_begin;
    wire inside_ready;
    wire inside_is_prime;
    
    prime_checker_inside_module inside_module(
        .CLK (CLK),
        .candidate (candidate),
        .be (inside_begin),
        .in_s (s),
        .in_d (d),
        .ce (ce),
        .is_prime (inside_is_prime),
        .ready (inside_ready)
    );
    
    always @(posedge CLK) begin
        if(be == 1) begin
            started <= 1;
            ready <= 0;
            i <= 0;          // Reset licznika rund natychmiast przy starcie
            inside_begin <= 0;
            initial_checks <= 0;
        end else if(started == 1) begin
            if (initial_checks == 0) begin
                if (candidate == 1 || candidate == 4) begin
                    is_prime <= 0;
                    ready <= 1;
                    started <= 0; // Koniec pracy - wy³¹czamy maszynê stanów
                end else if (candidate == 3 || candidate == 2) begin
                   is_prime <= 1;
                   ready <= 1;
                   started <= 0;  // Koniec pracy
                end else if (candidate % 2 == 0) begin
                    is_prime <= 0;
                    ready <= 1;
                    started <= 0; // Koniec pracy
                end else begin
                    d <= candidate - 1;
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
                        inside_begin <= 1;
                        state <= 1;
                    end
                end else if(state == 1) begin
                    inside_begin <= 0; // Impuls startu dla podmodulu musi trwac 1 takt
                    
                    if(inside_ready == 1) begin
                        if(inside_is_prime == 1) begin
                            if(i < 2) begin
                                i <= i + 1;
                                inside_begin <= 1; // Odpalamy kolejn¹ rundê
                                state <= 1;        // Pozostajemy w stanie 1 czekaj¹c na nowy gotowoœæ
                            end else begin
                                is_prime <= 1;
                                ready <= 1;
                                started <= 0;      // POPRAWKA: Zatrzymujemy uk³ad po sukcesie
                            end
                        end else begin
                            is_prime <= 0;
                            ready <= 1;
                            started <= 0;          // POPRAWKA: Zatrzymujemy uk³ad po pora¿ce
                        end
                    end
                end
            end
        end
    end
endmodule