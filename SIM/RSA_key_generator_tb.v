`timescale 1ns / 1ps

module RSA_key_generator_tb;

    // Sygna³y wejœciowe do testowanego modu³u (w TB jako reg)
    reg CLK;
    reg start;
    reg clear;

    // Sygna³y wyjœciowe z testowanego modu³u (w TB jako wire)
    wire [15:0] out_n;
    wire [15:0] out_e;
    wire [15:0] out_d;
    wire ready;

    // Instancja Twojego modu³u generacji kluczy (UUT - Unit Under Test)
    RSA_key_generator uut (
        .CLK(CLK),
        .start(start),
        .clear(clear),
        .out_n(out_n),
        .out_e(out_e),
        .out_d(out_d),
        .ready(ready)
    );

    // 1. Generator zegara: okres 10ns (czêstotliwoœæ 100 MHz)
    always begin
        #5 CLK = ~CLK;
    end

    // 2. G³ówny blok stymulacji testowej
    initial begin
        // Stan pocz¹tkowy sygna³ów
        CLK = 0;
        start = 0;
        clear = 0;

        // Wymuszenie bezpiecznego startu - krótki reset na pocz¹tku
        $display("[TB] --- ROZPOCZÊCIE SYMULACJI ---");
        #20;
        clear = 1;
        #20;
        clear = 0;
        #50; // Chwila stabilizacji po resecie

        // ==========================================
        // PRÓBA 1
        // ==========================================
        $display("[TB] [%0t ns] Uruchomienie generacji: PRÓBA 1", $time);
        @(posedge CLK);
        start = 1;       // Podanie sygna³u start
        @(posedge CLK);
        start = 0;       // Opuszczenie sygna³u start (impuls 1-taktowy)

        // Czekamy a¿ modu³ skoñczy pracê i zapali flagê ready
        @(posedge ready);
        $display("[TB] [%0t ns] >> PRÓBA 1 ZAKOÑCZONA SUCCESS <<", $time);
        $display("[TB] WYNIKI -> N = %d (0x%h), E = %d, D = %d\n", out_n, out_n, out_e, out_d);
        
        #100; // Odczekanie 100ns przed kolejnym testem (bez u¿ywania clear!)

        // ==========================================
        // PRÓBA 2
        // ==========================================
        $display("[TB] [%0t ns] Uruchomienie generacji: PRÓBA 2 (bez clear)", $time);
        @(posedge CLK);
        start = 1;
        @(posedge CLK);
        start = 0;

        @(posedge ready);
        $display("[TB] [%0t ns] >> PRÓBA 2 ZAKOÑCZONA SUCCESS <<", $time);
        $display("[TB] WYNIKI -> N = %d (0x%h), E = %d, D = %d\n", out_n, out_n, out_e, out_d);
        
        #100; // Kolejna przerwa

        // ==========================================
        // PRÓBA 3
        // ==========================================
        $display("[TB] [%0t ns] Uruchomienie generacji: PRÓBA 3 (bez clear)", $time);
        @(posedge CLK);
        start = 1;
        @(posedge CLK);
        start = 0;

        @(posedge ready);
        $display("[TB] [%0t ns] >> PRÓBA 3 ZAKOÑCZONA SUCCESS <<", $time);
        $display("[TB] WYNIKI -> N = %d (0x%h), E = %d, D = %d\n", out_n, out_n, out_e, out_d);

        // Zakoñczenie symulacji
        #200;
        $display("[TB] --- KONIEC SYMULACJI: Wszystkie próby wykonane ---");
        $finish;
    end

endmodule