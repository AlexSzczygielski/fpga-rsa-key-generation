`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.06.2026 18:38:02
// Design Name: 
// Module Name: random_number_generator
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


module random_number_generator(
    input wire CLK,
    input wire [7:0] seed,
    input wire clear,
    output reg [7:0] out_result
    );
    
    always @(posedge CLK)begin
        if(clear == 1)begin
            out_result <= seed;
        end else begin
            out_result <= (out_result << 2) + out_result + 8'd1;
        end
    end
endmodule
