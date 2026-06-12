`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 21:04:40
// Design Name: 
// Module Name: euclidean_algorithm
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


module euclidean_algorithm(
    input wire CLK,
    input wire start,
    input wire clear,
    input wire [15:0] in_e,
    input wire [15:0] in_euler_function,
    output reg [15:0] out_d,   
    output reg wrong_e,
    output reg ready
    );
    
    reg [15:0] R1;
    reg [15:0] R2;
    reg signed [16:0] T1;
    reg signed [16:0] T2;
    
    reg running;
    
always @(posedge CLK)begin
    if(clear == 1)begin
        running <= 0;
        ready <= 0;
        wrong_e <= 0;
    end else begin
        if(running == 0)begin
            if(start == 1)begin
                running <= 1;
                R1 <= in_euler_function;
                R2 <= in_e;
                T1 <= 0;
                T2 <= 1;
                ready <= 0;
                wrong_e <= 0;
            end
        end else begin
            if(R2 == 0)begin
                if(R1 != 1)begin
                    wrong_e <= 1;
                end else begin
                    wrong_e <= 0;
                    if(T1 > 0)begin
                        out_d <= T1[15:0];
                    end else begin
                        out_d <= T1 + $signed({1'b0, in_euler_function});
                    end
                end
                ready <= 1;
                running <= 0;
            end else begin
                if(R1 >= R2)begin
                    R1 <= R1 - R2;
                    T1 <= T1 - T2;
                end else begin
                    R1 <= R2;
                    R2 <= R1;
                    T1 <= T2;
                    T2 <= T1;
                end
            end
        end
    end
end
    
endmodule
