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
    input wire [8:0] seed,
    input wire ce,
    input wire CLK,
    output reg [8:0] result
    );
    
    always @(posedge CLK)begin
        if(ce == 1)begin
            result <= seed;
        end else begin
            result <= {result[7:0], result[8] ^ result[4]};
        end
    end
endmodule
