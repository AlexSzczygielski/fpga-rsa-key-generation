`timescale 1ns / 1ps

module random_number_generator_validation_tb;

    // Sygna³y do DUT
    reg CLK;
    reg [7:0] seed;
    reg clear;
    wire [7:0] out_result;

    // Tablica testowa: 256 jednobitowych komórek (flagi: 0 = nie by³o, 1 = by³a)
    reg seen [0:255];
    
    // Zmienne pomocnicze do pêtli i zliczania
    integer i;
    integer unique_count;

    // Instancja modu³u generuj¹cego
    random_number_generator uut (
        .CLK(CLK),
        .seed(seed),
        .clear(clear),
        .out_result(out_result)
    );

    // Generowanie zegara 100 MHz (okres 10ns)
    always #5 CLK = ~CLK;

    initial begin
        // --- KROK 1: Wyczyszczenie tablicy 'seen' (ustawienie flag na 0) ---
        for (i = 0; i < 256; i = i + 1) begin
            seen[i] = 0;
        end

        // Inicjalizacja sygna³ów steruj¹cych
        CLK = 0;
        clear = 1;
        seed = 8'h00; // Wybieramy 0 jako ziarno (w klasycznym LFSR by nie zadzia³a³o!)
        #20;

        // --- KROK 2: Za³adowanie ziarna i start ---
        @(posedge CLK);
        #1;
        $display("[INFO] Za³adowano ziarno pocz¹tkowe: %d", out_result);
        
        clear = 0; // Wy³¹czenie resetu - generator rusza

        // --- KROK 3: Zbieranie danych przez dok³adnie 256 taktów zegara ---
        $display("[INFO] Rozpoczêto zbieranie 256 próbek...");
        repeat (256) begin
            @(posedge CLK);
            #1; // Odczekanie chwili na ustabilizowanie siê stanu linii out_result
            seen[out_result] = 1; // Oznaczamy tê liczbê jako "odwiedzon¹"
        end

        // --- KROK 4: Podliczenie wyników ---
        unique_count = 0;
        for (i = 0; i < 256; i = i + 1) begin
            if (seen[i] == 1) begin
                unique_count = unique_count + 1;
            end else begin
                // W przypadku b³êdu, ta linia podpowie jakiej liczby zabrak³o
                $display("[DEBUG] Brakuj¹ca liczba w cyklu: %d", i);
            end
        end

        // --- KROK 5: Generowanie raportu koñcowego ---
        $display("\n==================================================");
        $display("   RAPORT AUTOMATYCZNEJ WERYFIKACJI GENERATORA");
        $display("==================================================");
        $display(" Oczekiwana liczba stanów: 256");
        $display(" Wykryta liczba unikalnych stanów: %d", unique_count);
        $display("--------------------------------------------------");
        
        if (unique_count == 256) begin
            $display(" STATUS: TEST ZALICZONY (SUCCESS)");
            $display(" Modu³ poprawnie generuje KA¯D¥ liczbê z zakresu 0-255!");
        end else begin
            $display(" STATUS: TEST OBLANY (FAIL)");
            $display(" Generator pomija wartoœci! Brakuje %d liczb.", (256 - unique_count));
        end
        $display("==================================================\n");

        // Zakoñczenie symulacji
        $finish;
    end

endmodule