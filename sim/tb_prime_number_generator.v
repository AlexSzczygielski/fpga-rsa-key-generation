`timescale 1ns / 1ps

module prime_number_generator_tb;

    // --- Sygna³y testbench ---
    reg CLK;
    reg be;
    reg [8:0] seed;
    reg ce;

    wire [8:0] x;
    wire done;

    // --- Instancja testowanego modu³u (DUT) ---
    prime_number_generator uut (
        .CLK(CLK),
        .be(be),
        .seed(seed),
        .x(x),
        .done(done),
        .ce(ce)
    );

    // --- Generowanie zegara (100 MHz, okres 10ns) ---
    always begin
        #5 CLK = ~CLK;
    end

    // --- G³ówny proces testowy ---
    initial begin
        // 1. Inicjalizacja sygna³ów wejœciowych
        CLK = 0;
        be = 0;
        seed = 9'd42; // Przyk³adowy pocz¹tkowy seed dla generatora
        ce = 1;       // W Twoim kodzie 'ce == 1' zeruje 'done' i zatrzymuje FSM, 
                      // dlatego trzymamy ce = 0 podczas normalnej pracy.
                      
        #20
        ce = 0;

        // Odczekaj chwilê na ustabilizowanie uk³adu
        #20;

        $display("====================================================");
        $display("   URUCHOMIENIE GENERATORA LICZB PIERWSZYCH         ");
        $display("====================================================");

        // 2. Wyzwalanie pierwszego szukania liczby pierwszej
        @(posedge CLK);
        be = 1;         // Impuls startu
        seed = 9'd105;  // Mo¿esz zmieniæ seed przed startem
        
        @(posedge CLK);
        be = 0;         // Gasimy impuls po jednym takcie

        // 3. Oczekiwanie na znalezienie liczby pierwszej
        // Uk³ad mo¿e krêciæ siê w pêtli stanów 1 -> 2 -> 1, dopóki test MR nie powie: sukces!
        @(posedge done);
        #1; // Przesuniêcie dla stabilnoœci odczytu danych w konsoli
        $display("[t=%0dns] SUKCES: Wygenerowano liczbê pierwsz¹ x = %0d", $time, x);

        #50;

        // 4. Test ponownego uruchomienia z innym seedem
        $display("\n[t=%0dns] Próba wygenerowania kolejnej liczby z nowym seedem...", $time);
        @(posedge CLK);
        seed = 9'd241;  // Zmiana ziarna, aby wylosowaæ inne liczby
        be = 1;
        
        @(posedge CLK);
        be = 0;

        @(posedge done);
        #1;
        $display("[t=%0dns] SUKCES: Wygenerowano kolejn¹ liczbê pierwsz¹ x = %0d", $time, x);

        // 5. Test sygna³u 'ce' (Clock Enable / Reset w Twojej implementacji)
        #50;
        $display("\n[t=%0dns] Test zachowania sygna³u 'ce'...", $time);
        @(posedge CLK);
        ce = 1; // Aktywacja ce powinna natychmiast wyzerowaæ sygna³ done
        
        #20;
        if (done == 0) begin
            $display("[t=%0dns] Sygna³ 'done' poprawnie wyzerowany przez ce.", $time);
        end else begin
            $display("[t=%0dns] B£¥D: Sygna³ 'done' nie zareagowa³ na ce!", $time);
        end
        
        @(posedge CLK);
        ce = 0; // Powrót do normalnego stanu

        #50;
        $display("====================================================");
        $display("                KONIEC SYMULACJI                    ");
        $display("====================================================");
        $finish;
    end

endmodule