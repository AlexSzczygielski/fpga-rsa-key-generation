// ============================================================
// Paste this block into the "// Add user logic here" section
// before "// User logic ends"
// ============================================================

// Control bits, written by software via slv_reg0 (left fully writable)
wire RSA_start;
wire RSA_clear;
assign RSA_start = slv_reg0[0];
assign RSA_clear = slv_reg0[1];

// Full-width wires that get registered into the read-only slave registers.
// Using one always block per register avoids multiple-driver conflicts.
wire [C_S_AXI_DATA_WIDTH-1:0] slv_wire1;
wire [C_S_AXI_DATA_WIDTH-1:0] slv_wire2;
wire [C_S_AXI_DATA_WIDTH-1:0] slv_wire3;

always @( posedge S_AXI_ACLK )
begin
    slv_reg1 <= slv_wire1;
    slv_reg2 <= slv_wire2;
    slv_reg3 <= slv_wire3;
end

// RSA_key_generator outputs
wire [15:0] out_n_w;
wire [15:0] out_e_w;
wire [15:0] out_d_w;
wire        ready_w;

// Pack outputs into the 32-bit registers, zero the unused bits
assign slv_wire1[15:0]  = out_n_w;
assign slv_wire1[31:16] = 16'b0;

assign slv_wire2[15:0]  = out_e_w;
assign slv_wire2[16]    = ready_w;
assign slv_wire2[31:17] = 15'b0;

assign slv_wire3[15:0]  = out_d_w;
assign slv_wire3[31:16] = 16'b0;

RSA_key_generator RSA_key_generator_inst (
    .CLK   ( S_AXI_ACLK ),
    .start ( RSA_start  ),
    .clear ( RSA_clear  ),
    .out_n ( out_n_w    ),
    .out_e ( out_e_w    ),
    .out_d ( out_d_w    ),
    .ready ( ready_w    )
);

// ============================================================
// Register map (32-bit words, byte offsets from S00_AXI base):
//   0x00 (slv_reg0)  bit0 = start (W),  bit1 = clear (W)
//   0x04 (slv_reg1)  bits[15:0] = out_n (R)
//   0x08 (slv_reg2)  bits[15:0] = out_e (R),  bit16 = ready (R)
//   0x0C (slv_reg3)  bits[15:0] = out_d (R)
// ============================================================
