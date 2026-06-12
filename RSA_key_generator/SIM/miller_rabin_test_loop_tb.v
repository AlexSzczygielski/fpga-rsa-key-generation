`timescale 1ns / 1ps

module miller_rabin_test_loop_tb;

    // Sygna³y wejœciowe do sterowania uk³adem (reg)
    reg CLK;
    reg start;
    reg clear;
    reg [7:0] in_candidate;
    reg [7:0] in_s;
    reg [7:0] in_d;

    // Sygna³y wyjœciowe monitorowane z uk³adu (wire)
    wire is_prime;
    wire ready;

    // Instancja testowanego modu³u (DUT)
    miller_rabin_test_loop uut (
        .CLK(CLK), 
        .start(start), 
        .clear(clear), 
        .in_candidate(in_candidate), 
        .in_s(in_s), 
        .in_d(in_d), 
        .is_prime(is_prime), 
        .ready(ready)
    );

    // Generowanie zegara 100 MHz (okres 10ns)
    always #5 CLK = ~CLK;

    // G³ówny blok testowy
    initial begin
        // 1. Inicjalizacja sygna³ów
        CLK = 0;
        start = 0;
        clear = 0;
        in_candidate = 0;
        in_s = 0;
        in_d = 0;

        // 2. Reset systemu (Inicjalizacja generatora i modu³u potêgowania)
        #15;
        clear = 1;
        #10;
        clear = 0;
        #20;

        // --- TEST 1: Liczba pierwsza 13 ---
        // Rozk³ad: 13 - 1 = 12 = 2^2 * 3  -->  s = 2, d = 3
        $display("--------------------------------------------------");
        $display("[TEST 1] Testowanie liczby pierwszej: 13 (s=2, d=3)");
        $display("--------------------------------------------------");
        in_candidate = 8'd13;
        in_s         = 8'd2;
        in_d         = 8'd3;
        
        @(posedge CLK);
        start = 1;
        @(posedge CLK);
        start = 0;

        // Maszyna stanów szuka losowego 'a' i liczy potêgê, czekamy na gotowoœæ
        while (!ready) @(posedge CLK);
        
        #1; // Czas na ustabilizowanie wyjœæ rejestrowanych
        if (is_prime == 1) 
            $display("-> WYNIK: Sukces. Wykryto liczbê pierwsz¹ 13.\n");
        else 
            $display("-> WYNIK: B£¥D! Odrzucono liczbê pierwsz¹ 13.\n");

        #50;

        // --- TEST 2: Liczba z³o¿ona 15 ---
        // Rozk³ad: 15 - 1 = 14 = 2^1 * 7  -->  s = 1, d = 7
        $display("--------------------------------------------------");
        $display("[TEST 2] Testowanie liczby z³o¿onej: 15 (s=1, d=7)");
        $display("--------------------------------------------------");
        in_candidate = 8'd15;
        in_s         = 8'd1;
        in_d         = 8'd7;
        
        @(posedge CLK);
        start = 1;
        @(posedge CLK);
        start = 0;

        while (!ready) @(posedge CLK);
        
        #1;
        if (is_prime == 0) 
            $display("-> WYNIK: Sukces. Wykryto, ¿e 15 to liczba z³o¿ona.\n");
        else 
            $display("-> WYNIK: B£¥D! Fa³szywy alarm - uznano 15 za pierwsz¹.\n");

        #50;

        // --- TEST 3: Liczba pierwsza 17 (G³êbokie sprawdzanie potêgowe) ---
        // Rozk³ad: 17 - 1 = 16 = 2^4 * 1  -->  s = 4, d = 1
        // Ten test zmusi maszynê do wejœcia w stany 4 -> 5 -> 6 (pêtla podnoszenia do kwadratu)
        $display("--------------------------------------------------");
        $display("[TEST 3] Testowanie liczby pierwszej: 17 (s=4, d=1)");
        $display("--------------------------------------------------");
        in_candidate = 8'd17;
        in_s         = 8'd4;
        in_d         = 8'd1;
        
        @(posedge CLK);
        start = 1;
        @(posedge CLK);
        start = 0;

        while (!ready) @(posedge CLK);
        
        #1;
        if (is_prime == 1) 
            $display("-> WYNIK: Sukces. Wykryto liczbê pierwsz¹ 17.\n");
        else 
            $display("-> WYNIK: B£¥D! Odrzucono liczbê pierwsz¹ 17.\n");

        #50;
        $display("==================================================");
        $display("Wszystkie scenariusze testu Millera-Rabina wykonane.");
        $display("==================================================");
        $finish;
    end

endmodule