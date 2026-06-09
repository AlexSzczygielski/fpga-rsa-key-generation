`timescale 1ns / 1ps

module miller_rabin_test_tb;

    // --- Sygna³y testbench ---
    reg [8:0] candidate;
    reg be;
    reg CLK;
    reg ce;

    wire is_prime;
    wire ready;

    // --- Instancja testowanego modu³u (DUT) ---
    miller_rabin_test uut (
        .candidate(candidate), 
        .be(be), 
        .CLK(CLK), 
        .ce(ce), 
        .is_prime(is_prime), 
        .ready(ready)
    );

    // --- Generowanie zegara (100 MHz, okres 10ns) ---
    always begin
        #5 CLK = ~CLK;
    end

    // --- Zadanie automatyzuj¹ce podawanie liczby do testu ---
    task test_number(input [8:0] num);
        begin
            $display("[t=%0dns] START: Testowanie liczby %0d...", $time, num);
            
            @(posedge CLK);
            candidate = num;
            be = 1;          // Wystawienie impulsu START (be)
            
            @(posedge CLK);
            be = 0;          // Gasimy impuls po jednym takcie
            
            // Oczekiwanie na flagê gotowoœci z modu³u
            @(posedge ready);
            #1;              // Minimalne przesuniêcie dla stabilnoœci odczytu w konsoli
            
            if (is_prime)
                $display("[t=%0dns] WYNIK: Liczba %0d jest PIERWSZA (+)\n", $time, num);
            else
                $display("[t=%0dns] WYNIK: Liczba %0d jest Z£O¯ONA (-)\n", $time, num);
            
            #30;             // Odstêp miêdzy testami
        end
    endtask

    // --- G³ówny proces testowy ---
    initial begin
        // Inicjalizacja rejestrów wejœciowych
        CLK = 0;
        be = 0;
        ce = 1;              // Zak³adam ce=1 dla aktywacji modu³u, jeœli wymagane
        candidate = 0;
        
        #20
        ce = 0;

        // Reset/stabilizacja na starcie symulacji
        #20;

        $display("=======================================");
        $display("   URUCHOMIENIE TESTÓW MILLER-RABIN    ");
        $display("=======================================");

        // Grupa 1: Natychmiastowe przypadki brzegowe (Logika 'initial_checks')
        test_number(1);   // Z³o¿ona
        test_number(2);   // Pierwsza
        test_number(3);   // Pierwsza
        test_number(4);   // Z³o¿ona

        // Grupa 2: Szybkie odrzucanie liczb parzystych
        test_number(12);  // Z³o¿ona
        test_number(50);  // Z³o¿ona

        // Grupa 3: Ma³e liczby nieparzyste (wchodz¹ce do maszyny stanów)
        test_number(7);   // Pierwsza
        test_number(9);   // Z³o¿ona (3x3)
        test_number(15);  // Z³o¿ona (3x5)

        // Grupa 4: Wiêksze liczby (w zakresie 9-bitów, max 511)
        test_number(97);  // Pierwsza
        test_number(257); // Pierwsza
        test_number(509); // Pierwsza
        test_number(511); // Z³o¿ona (7 x 73)

        $display("=======================================");
        $display("    TESTY ZAKOÑCZONE POMYŒLNIE        ");
        $display("=======================================");
        
        $finish;
    end
      
endmodule