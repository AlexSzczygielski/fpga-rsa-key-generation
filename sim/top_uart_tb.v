`timescale 1ns / 1ps

module top_uart_tb;

reg  CLK12MHZ = 0;
reg  ck_rst   = 0;   // active-low: 0 = reset asserted
wire uart_rxd_out;
wire led;

// 12 MHz clock: period = 83.333 ns
always #41 CLK12MHZ = ~CLK12MHZ;

top_uart dut (
    .CLK12MHZ    (CLK12MHZ),
    .ck_rst      (ck_rst),
    .uart_rxd_out(uart_rxd_out),
    .led         (led)
);

// UART monitor: capture bytes at 9600 baud (1 bit = 1250 cycles @ 12MHz = 104166 ns)
localparam BIT_PERIOD = 104166;

task receive_uart_byte;
    output [7:0] rxbyte;
    integer i;
    begin
        // Wait for start bit (falling edge)
        @(negedge uart_rxd_out);
        // Sample in middle of start bit
        #(BIT_PERIOD / 2);
        // Shift in 8 data bits LSB first
        rxbyte = 0;
        for (i = 0; i < 8; i = i + 1) begin
            #BIT_PERIOD;
            rxbyte[i] = uart_rxd_out;
        end
        // Skip stop bit
        #BIT_PERIOD;
        $write("%c", rxbyte);
    end
endtask

reg [7:0] rxbyte;

initial begin
    $display("=== top_uart_tb start ===");
    $write("UART output: ");

    // Hold reset for 10 clock cycles
    ck_rst = 0;
    #1000;
    ck_rst = 1;   // release reset

    // Receive up to 20 bytes (enough for "P1: NNN\r\nP2: NNN\r\n")
    begin : rx_loop
        integer b;
        for (b = 0; b < 20; b = b + 1) begin
            receive_uart_byte(rxbyte);
            if (rxbyte == 8'h0A && b >= 15) begin
                // Second newline received - message complete
                disable rx_loop;
            end
        end
    end

    $display("");
    $display("=== done (led=%b) ===", led);
    #100000;
    $finish;
end

// Timeout watchdog - prime generation can take many cycles
initial begin
    #500_000_000;
    $display("TIMEOUT");
    $finish;
end

endmodule