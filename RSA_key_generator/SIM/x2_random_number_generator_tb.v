`timescale 1ns / 1ps

module tb_x2_random_number_generator;

    // Sygna³y testbenche'a (wejœcia modu³u jako reg, wyjœcia jako wire)
    reg CLK;
    reg [15:0] seed;
    reg clear;
    wire [15:0] out_result;

    // Instancja testowanego modu³u (UUT - Unit Under Test)
    x2_random_number_generator uut (
        .CLK(CLK),
        .seed(seed),
        .clear(clear),
        .out_result(out_result)
    );

    // Generowanie zegara: okres 10ns (czêstotliwoœæ 100 MHz)
    always begin
        #5 CLK = ~CLK;
    end

    // G³ówna procedura testowa
    initial begin
        // Inicjalizacja sygna³ów wejœciowych
        CLK = 0;
        clear = 0;
        seed = 16'h1234; // Przyk³adowy seed pocz¹tkowy

        // 1. Warunki pocz¹tkowe i aktywacja sygna³u clear
        #10;
        clear = 1;
        
        // 2. Wy³¹czenie clear po dwóch taktach zegara
        #20;
        clear = 0;

        // Monitowanie zmian w konsoli symulatora
        $display("Czas\t\t Clear\t Wynik (Hex)\t Wynik (Dec)");
        $monitor("%d ns\t\t %b\t %h\t\t %d", $time, clear, out_result, out_result);

        // 3. Pozwól generatorowi dzia³aæ przez 150ns (15 taktów zegara)
        #150;

        // 4. Test ponownego za³adowania nowego seeda w locie
        $display("\n--- Zmiana seeda w trakcie pracy ---");
        seed = 16'hABCD;
        clear = 1;
        #10;
        clear = 0;
        
        // Dalsza praca z nowym seedem
        #100;

        // Zakoñczenie symulacji
        $display("Koniec testu.");
        $finish;
    end
      
endmodule