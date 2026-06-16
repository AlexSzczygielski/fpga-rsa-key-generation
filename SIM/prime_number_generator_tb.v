`timescale 1ns / 1ps

module tb_prime_number_generator;

    reg CLK;
    reg start;
    reg clear;

    wire [7:0] out_result;
    wire ready;

    prime_number_generator uut (
        .CLK(CLK),
        .start(start),
        .clear(clear),
        .out_result(out_result),
        .ready(ready)
    );

    always begin
        #10 CLK = ~CLK;
    end

    initial begin
        CLK = 0;
        start = 0;
        clear = 0;
        
        #20
        
        clear = 1;
        
        #50
        
        clear = 0;
        
        #50
        
        start = 1;
        
        while(ready == 0)begin
            #1;
        end
        
        $display("-> Wynik: %d\n",out_result);
    end


endmodule