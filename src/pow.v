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


module pow(
    input wire be,
    input wire [8:0] in_base,
    input wire [8:0] in_exponent,
    input wire [8:0] n,
    input wire CLK,
    output reg ready,
    output reg [8:0] out_result
    );
    
reg [8:0] base;
reg [8:0] exponent;
reg [8:0] result;


always @(posedge CLK) begin
    if (be) begin
        result <= 1;
        ready <= 0;
        base <= in_base;
        exponent <= in_exponent;
    end else if (exponent > 0) begin
        if (exponent[0] == 1) begin
            result <= ({9'd0, result} * base) % n;
        end
        base <= ({9'd0, base} * base) % n;
        exponent <= exponent >> 1;
    end else begin
        out_result <= result;
        ready <= 1;
    end
end
endmodule
