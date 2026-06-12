`timescale 1ns / 1ps

module euclidean_algorithm_tb;

    // Sygna³y wejœciowe (rejestry w TB)
    reg CLK;
    reg start;
    reg clear;
    reg [15:0] in_e;
    reg [15:0] in_euler_function;

    // Sygna³y wyjœciowe (wire w TB)
    wire [15:0] out_d;
    wire wrong_e;
    wire ready;

    // Instancja modu³u testowanego (UUT - Unit Under Test)
    euclidean_algorithm uut (
        .CLK(CLK),
        .start(start),
        .clear(clear),
        .in_e(in_e),
        .in_euler_function(in_euler_function),
        .out_d(out_d),
        .wrong_e(wrong_e),
        .ready(ready)
    );

    // Generowanie zegara (okres 10ns -> 100 MHz)
    always begin
        #5 CLK = ~CLK;
    end

    // G³ówny blok testowy
    initial begin
        // Inicjalizacja sygna³ów
        CLK = 0;
        start = 0;
        clear = 0;
        in_e = 0;
        in_euler_function = 0;

        // Reset pocz¹tkowy
        #15;
        clear = 1;
        #10;
        clear = 0;
        #20;

        // -------------------------------------------------------------
        // TEST 1: Poprawne dane (e = 17, phi = 3120)
        // Oczekiwany wynik: d = 2753, wrong_e = 0
        // -------------------------------------------------------------
        $display("[TB] Test 1: Start obliczen dla e=17, phi=3120");
        in_euler_function = 16'd3120;
        in_e = 16'd17;
        start = 1;
        #10;
        start = 0; // Wy³¹czenie startu po jednym takcie

        // Oczekiwanie na sygna³ ready
        @(posedge ready);
        #1; // Ma³e opóŸnienie na zatwierdzenie wyników
        if (wrong_e == 0 && out_d == 16'd2753) begin
            $display("[TB] Test 1 ZALICZONY: out_d = %d (Oczekiwano: 2753)", out_d);
        end else begin
            $display("[TB] Test 1 BLAD: out_d = %d, wrong_e = %b", out_d, wrong_e);
        end
        
        #50;

        // -------------------------------------------------------------
        // TEST 2: Bledne dane (e = 6, phi = 20) -> NWD(6,20) = 2 != 1
        // Oczekiwany wynik: wrong_e = 1
        // -------------------------------------------------------------
        $display("[TB] Test 2: Start obliczen dla e=6, phi=20 (brak wzglednej pierwszosci)");
        in_euler_function = 16'd20;
        in_e = 16'd6;
        start = 1;
        #10;
        start = 0;

        @(posedge ready);
        #1;
        if (wrong_e == 1) begin
            $display("[TB] Test 2 ZALICZONY: Wykryto niepoprawne 'e' (wrong_e = 1)");
        end else begin
            $display("[TB] Test 2 BLAD: Nie wykryto bledu! out_d = %d", out_d);
        end

        #50;

        // -------------------------------------------------------------
        // TEST 3: Przerwanie pracy sygna³em CLEAR
        // -------------------------------------------------------------
        $display("[TB] Test 3: Test sygnalu CLEAR w trakcie obliczen");
        in_euler_function = 16'd5000;
        in_e = 16'd3;
        start = 1;
        #10;
        start = 0;
        
        // Odczekaj kilka taktów i rzuæ reset
        #30;
        clear = 1;
        #10;
        clear = 0;
        
        // Sprawdzenie czy modu³ wróci³ do stanu IDLE (nie powinien wystawiæ ready)
        #100;
        if (ready == 0) begin
            $display("[TB] Test 3 ZALICZONY: Modul poprawnie zresetowany.");
        end else begin
            $display("[TB] Test 3 BLAD: Modul wystawil READY mimo resetu!");
        end

        // Koniec symulacji
        $display("[TB] Symulacja zakonczona.");
        $finish;
    end

endmodule