//-----------------------------------------------------------------------------
// UART Transmitter - 8N1
// Parameters: CLK_FREQ (Hz), BAUD (bps)
// Usage: assert send=1 with data for one clock cycle; wait until busy=0
//-----------------------------------------------------------------------------

module uart_tx
#(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD     = 115200
)
(
    input  wire       CLK,
    input  wire       RSTN,
    input  wire       send,
    input  wire [7:0] data,
    output reg        busy,
    output reg        TX
);

localparam integer BIT_PERIOD = CLK_FREQ / BAUD;  // clock cycles per bit

reg [15:0] baud_counter;
reg [3:0]  bit_index;    // 0=start, 1-8=data, 9=stop
reg [9:0]  shift_reg;    // {stop, data[7:0], start}
reg        transmitting;

always @(posedge CLK or negedge RSTN) begin
    if(!RSTN) begin
        TX           <= 1'b1;    // idle high
        busy         <= 1'b0;
        transmitting <= 1'b0;
        baud_counter <= 0;
        bit_index    <= 0;
        shift_reg    <= 10'h3FF;
    end else begin

        if(!transmitting) begin
            TX   <= 1'b1;  // line idle
            busy <= 1'b0;

            if(send) begin
                // pack: stop(1) | data[7:0] | start(0)
                shift_reg    <= {1'b1, data, 1'b0};
                bit_index    <= 0;
                baud_counter <= 0;
                transmitting <= 1'b1;
                busy         <= 1'b1;
            end
        end else begin
            busy <= 1'b1;

            if(baud_counter < BIT_PERIOD - 1) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
                TX           <= shift_reg[0];
                shift_reg    <= {1'b1, shift_reg[9:1]};
                bit_index    <= bit_index + 1;

                if(bit_index == 9) begin
                    transmitting <= 1'b0;
                    busy         <= 1'b0;
                end
            end
        end
    end
end

endmodule
