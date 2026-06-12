`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 22:20:28
// Design Name: 
// Module Name: 2x_random_number_generator
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


module x2_random_number_generator(
    input wire CLK,
    input wire [15:0] seed,
    input wire clear,
    output reg [15:0] out_result
    );
    
    always @(posedge CLK)begin
        if(clear == 1)begin
            out_result <= seed;
        end else begin
            out_result <= (out_result * 16'd25173) + 16'd13849;
        end
    end
endmodule
