`timescale 1ns / 1ps

module power_operation_tb;

    // Sygna³y wejœciowe (sterowane z poziomu testbenchu jako reg)
    reg CLK;
    reg start;
    reg clear;
    reg [7:0] in_base;
    reg [7:0] in_exponent;
    reg [7:0] in_modulo_base;

    // Sygna³y wyjœciowe z modu³u (monitorowane jako wire)
    wire [7:0] out_result;
    wire ready;

    // Instancja testowanego modu³u (DUT - Device Under Test)
    power_operation uut (
        .CLK(CLK), 
        .start(start), 
        .clear(clear), 
        .in_base(in_base), 
        .in_exponent(in_exponent), 
        .in_modulo_base(in_modulo_base), 
        .out_result(out_result), 
        .ready(ready)
    );

    // Generowanie zegara: okres 10ns daje czêstotliwoœæ 100 MHz
    always #5 CLK = ~CLK;

    // G³ówny blok testowy
    initial begin
        // 1. Inicjalizacja sygna³ów wejœciowych
        CLK = 0;
        start = 0;
        clear = 0;
        in_base = 0;
        in_exponent = 0;
        in_modulo_base = 0;

        // Odczekanie na rozpoczêcie symulacji
        #20;
        
        // 2. Sekwencja Resetu (Clear)
        @(posedge CLK);
        clear = 1;
        @(posedge CLK);
        clear = 0;
        @(posedge CLK);

        // --- TEST 1: 2^3 mod 10 = 8 ---
        $display("[TEST 1] Uruchamianie: 2^3 mod 10");
        in_base = 8'd2;
        in_exponent = 8'd3;
        in_modulo_base = 8'd10;
        
        @(posedge CLK);
        start = 1;          // Aktywacja sygna³u start
        @(posedge CLK);
        start = 0;          // Dezaktywacja po jednym takcie
        
        // Oczekiwanie na zakoñczenie obliczeñ (sygna³ ready = 1)
        while (!ready) @(posedge CLK);
        #1; // Krótkie opóŸnienie, aby upewniæ siê, ¿e dane wyjœciowe siê ustabilizowa³y
        $display("[TEST 1] Wynik: %d (Oczekiwano: 8)\n", out_result);


        // --- TEST 2: 5^4 mod 13 = 1 ---
        // (5^4 = 625, 625 / 13 = 48 reszty 1)
        $display("[TEST 2] Uruchamianie: 5^4 mod 13");
        in_base = 8'd5;
        in_exponent = 8'd4;
        in_modulo_base = 8'd13;
        
        @(posedge CLK);
        start = 1;
        @(posedge CLK);
        start = 0;
        
        while (!ready) @(posedge CLK);
        #1;
        $display("[TEST 2] Wynik: %d (Oczekiwano: 1)\n", out_result);


        // --- TEST 3: 3^5 mod 7 = 5 ---
        // (3^5 = 243, 243 / 7 = 34 reszty 5)
        $display("[TEST 3] Uruchamianie: 3^5 mod 7");
        in_base = 8'd3;
        in_exponent = 8'd5;
        in_modulo_base = 8'd7;
        
        @(posedge CLK);
        start = 1;
        @(posedge CLK);
        start = 0;
        
        while (!ready) @(posedge CLK);
        #1;
        $display("[TEST 3] Wynik: %d (Oczekiwano: 5)\n", out_result);


        // --- TEST 4: Przerwanie pracy przez sygna³ CLEAR ---
        $display("[TEST 4] Test awaryjnego czyszczenia (CLEAR w trakcie pracy)");
        in_base = 8'd3;
        in_exponent = 8'd7;
        in_modulo_base = 8'd5;
        
        @(posedge CLK);
        start = 1;
        @(posedge CLK);
        start = 0;
        
        // Pozwól modu³owi popracowaæ przez 2 takty zegara
        @(posedge CLK);
        @(posedge CLK);
        
        // Wymuszenie czyszczenia w trakcie obliczeñ
        clear = 1;
        @(posedge CLK);
        clear = 0;
        
        #1;
        if (ready == 0 && out_result == 0) begin
            $display("[TEST 4] Sukces: Modu³ poprawnie zresetowa³ stan wewnêtrzny.\n");
        end else begin
            $display("[TEST 4] B³¹d: Modu³ nie zareagowa³ prawid³owo na reset!\n");
        end

        // Zakoñczenie symulacji
        $display("Wszystkie testy zakoñczone.");
        $finish;
    end
      
endmodule