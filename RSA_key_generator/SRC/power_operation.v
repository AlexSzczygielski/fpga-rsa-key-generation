`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.06.2026 19:24:46
// Design Name: 
// Module Name: pow
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module power_operation(
    input wire CLK,
    input wire start,
    input wire clear,
    input wire [7:0] in_base,
    input wire [7:0] in_exponent,
    input wire [7:0] in_modulo_base,
    output reg [7:0] out_result,
    output reg ready
    );
    
reg [7:0] base;
reg [7:0] exponent;
reg [7:0] result;
reg running;

always @(posedge CLK) begin
    if(clear == 1)begin
        running    <= 0;
        ready      <= 0;
        out_result <= 0;
        result     <= 1;
        base       <= 0;
        exponent   <= 0;
    end else if (running == 0)begin
        if (start) begin
            result <= 1;
            ready <= 0;
            base <= in_base;
            exponent <= in_exponent;
            running <= 1;
        end else begin
            ready <= 1;
        end
    end else begin
        if (exponent > 0) begin
            if (exponent[0] == 1) begin
                result <= ({8'd0, result} * base) % in_modulo_base;
            end
            base <= ({8'd0, base} * base) % in_modulo_base;
            exponent <= exponent >> 1;
        end else begin
            out_result <= result;
            ready <= 1;
            running <= 0;
        end
    end
end
endmodule
