`timescale 1ns / 1ps

module tb_prime_checker_auto;

    // Sygna³y steruj¹ce
    reg CLK;
    reg [8:0] candidate;
    reg be;
    reg [8:0] in_s;
    reg [8:0] in_d;
    reg ce;

    // Sygna³y odbierane
    wire is_prime;
    wire ready;

    // Pod³¹czenie badanego modu³u
    prime_checker_inside_module uut (
        .CLK(CLK),
        .candidate(candidate),
        .be(be),
        .in_s(in_s),
        .in_d(in_d),
        .ce(ce),
        .is_prime(is_prime),
        .ready(ready)
    );

    // Generator zegara
    always #5 CLK = ~CLK;

    // ==========================================
    // Z£OTY MODEL - Funkcja programowa sprawdzaj¹ca pierwszoœæ
    // U¿ywamy jej do weryfikacji sprzêtu.
    // ==========================================
    function integer is_prime_golden(input integer n);
        integer i;
        begin
            is_prime_golden = 1; // Zak³adamy, ¿e jest pierwsza
            if (n <= 1) is_prime_golden = 0;
            else if (n == 2 || n == 3) is_prime_golden = 1;
            else if (n % 2 == 0) is_prime_golden = 0;
            else begin
                for (i = 3; i * i <= n; i = i + 2) begin
                    if (n % i == 0) begin
                        is_prime_golden = 0; // Znaleziono dzielnik
                    end
                end
            end
        end
    endfunction

    // Zmienne do pêtli testowej
    integer current_num;
    integer temp_val;
    integer s_calc, d_calc;
    integer expected_result;
    integer errors;

    initial begin
        // Reset sygna³ów
        CLK = 0;
        candidate = 0;
        be = 0;
        in_s = 0;
        in_d = 0;
        errors = 0;
        
        // Inicjalizacja ziarna generatora
        ce = 1;
        #10;
        ce = 0;
        #20;

        $display("==================================================");
        $display("Rozpoczynam zautomatyzowany test dla liczb od 5 do 511...");
        $display("==================================================");

        // Pêtla sprawdzaj¹ca liczby nieparzyste od 5 do 511
        // Pomiñmy 1, 2, 3 oraz liczby parzyste, poniewa¿ dla nich algorytm 
        // Millera-Rabina wymaga oddzielnej logiki pocz¹tkowej (o czym wspomina³em wczeœniej).
        for(current_num = 5; current_num <= 511; current_num = current_num + 2) begin
            
            // 1. Algorytm wyliczaj¹cy 's' i 'd' (N - 1 = 2^s * d)
            temp_val = current_num - 1;
            s_calc = 0;
            while ((temp_val % 2) == 0 && temp_val > 0) begin
                s_calc = s_calc + 1;
                temp_val = temp_val / 2;
            end
            d_calc = temp_val;

            // 2. Podanie sygna³ów do wejœæ sprzêtowych
            candidate = current_num;
            in_s = s_calc;
            in_d = d_calc;
            expected_result = is_prime_golden(current_num); // Oczekiwana odpowiedŸ

            // 3. Wys³anie impulsu 'be' by rozpocz¹æ przetwarzanie
            be = 1;
            #10;
            be = 0;

            // 4. Zatrzymujemy testbench, dopóki modu³ nie wyliczy wartoœci
            wait(ready == 1);
            
            // 5. Weryfikacja wyniku
            if (is_prime !== expected_result) begin
                $display("[BLAD] Liczba: %0d | Twój modul: %b | Oczekiwano: %b | s: %0d, d: %0d", 
                         current_num, is_prime, expected_result, s_calc, d_calc);
                errors = errors + 1;
            end

            // 6. Czekamy 2 takty zegara przed wpisaniem nowej liczby, 
            // by modu³ móg³ siê w pe³ni zresetowaæ.
            #20;
        end

        // Podsumowanie
        $display("==================================================");
        if (errors == 0) begin
            $display("SUKCES! Twój uklad poprawnie zidentyfikowal wszystkie liczby.");
        end else begin
            $display("Zakonczono z bledami. Calkowita liczba pomy³ek: %0d", errors);
        end
        $display("==================================================");
        
        $finish; // Koniec symulacji
    end

endmodule