`timescale 1ns / 1ps

module miller_rabin_test_tb;

    // Sygna³y wejœciowe do sterowania (reg)
    reg CLK;
    reg start;
    reg clear;
    reg [7:0] in_candidate;

    // Sygna³y wyjœciowe (wire)
    wire is_prime;
    wire ready;

    // Instancja testowanego modu³u g³ównego (DUT)
    miller_rabin_test uut (
        .CLK(CLK), 
        .start(start), 
        .clear(clear), 
        .in_candidate(in_candidate), 
        .is_prime(is_prime), 
        .ready(ready)
    );

    // Generowanie zegara 100 MHz (okres 10ns)
    always #5 CLK = ~CLK;

    // G³ówny blok testowy
    initial begin
        // 1. Inicjalizacja linii wejœciowych
        CLK = 0;
        start = 0;
        clear = 0;
        in_candidate = 0;

        // Reset pocz¹tkowy ca³ego uk³adu
        #15;
        clear = 1;
        #10;
        clear = 0;
        #20;

        // ==================================================
        // GRUPA 1: SZYBKIE TESTY BRZEGOWE (Initial Checks)
        // ==================================================
        
        // --- TEST 1: Liczba parzysta (np. 6) ---
        $display("[TEST 1] Kandydat: 6 (Oczekiwano: Z³o¿ona - natychmiast)");
        in_candidate = 8'd6;
        @(posedge CLK); start = 1;
        @(posedge CLK); start = 0;
        
        while (!ready) @(posedge CLK);
        #1; $display("-> Wynik: %s\n", is_prime ? "PIERWSZA (B£¥D)" : "Z£O¯ONA (OK)");
        #20;

        // --- TEST 2: Liczba pierwsza 2 (Wyj¹tek parzystoœci) ---
        $display("[TEST 2] Kandydat: 2 (Oczekiwano: Pierwsza - natychmiast)");
        in_candidate = 8'd2;
        @(posedge CLK); start = 1;
        @(posedge CLK); start = 0;
        
        while (!ready) @(posedge CLK);
        #1; $display("-> Wynik: %s\n", is_prime ? "PIERWSZA (OK)" : "Z£O¯ONA (B£¥D)");
        #20;


        // ==================================================
        // GRUPA 2: PE£NA PROCEDURA MATEMATYCZNA
        // ==================================================

        // --- TEST 3: Liczba pierwsza 13 (Musi przejœæ 3 rundy) ---
        // Rozk³ad: 13-1 = 12 = 2^2 * 3 (s=2, d=3)
        $display("[TEST 3] Kandydat: 13 (Oczekiwano: Pierwsza - wymaga 3 rund)");
        in_candidate = 8'd13;
        @(posedge CLK); start = 1;
        @(posedge CLK); start = 0;
        
        // Czekamy na zakoñczenie wszystkich 3 pêtli wewnêtrznych
        while (!ready) @(posedge CLK);
        #1; $display("-> Wynik: %s\n", is_prime ? "PIERWSZA (OK)" : "Z£O¯ONA (B£¥D)");
        #20;

        // --- TEST 4: Liczba z³o¿ona nieparzysta 9 ---
        // Rozk³ad: 9-1 = 8 = 2^3 * 1 (s=3, d=1)
        // Test powinien odrzuciæ tê liczbê w pierwszej lub kolejnej rundzie
        $display("[TEST 4] Kandydat: 9 (Oczekiwano: Z³o¿ona)");
        in_candidate = 8'd9;
        @(posedge CLK); start = 1;
        @(posedge CLK); start = 0;
        
        while (!ready) @(posedge CLK);
        #1; $display("-> Wynik: %s\n", is_prime ? "PIERWSZA (B£¥D)" : "Z£O¯ONA (OK)");
        #20;

        // --- TEST 5: Liczba pierwsza 17 ---
        // Rozk³ad: 17-1 = 16 = 2^4 * 1 (s=4, d=1)
        $display("[TEST 5] Kandydat: 17 (Oczekiwano: Pierwsza - g³êbokie kwadratowanie)");
        in_candidate = 8'd17;
        @(posedge CLK); start = 1;
        @(posedge CLK); start = 0;
        
        while (!ready) @(posedge CLK);
        #1; $display("-> Wynik: %s\n", is_prime ? "PIERWSZA (OK)" : "Z£O¯ONA (B£¥D)");
        #20;

        // ==================================================
        // KONIEC SYMULACJI
        // ==================================================
        $display("==================================================");
        $display(" Wszystkie scenariusze testu g³ównego MR wykonane.");
        $display("==================================================");
        $finish;
    end

endmodule