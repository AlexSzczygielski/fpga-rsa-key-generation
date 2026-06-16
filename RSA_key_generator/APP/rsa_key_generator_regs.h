#ifndef RSA_KEY_GENERATOR_REGS_H
#define RSA_KEY_GENERATOR_REGS_H

// Byte offsets from the S00_AXI base address of the RSA_key_generator IP.
// Matches the slv_reg mapping in AXI_S00_AXI_user_logic_snippet.v

#define RSA_REG_CTRL_OFFSET   0x00   // bit0 = start (W), bit1 = clear (W)
#define RSA_REG_OUT_N_OFFSET  0x04   // bits[15:0] = out_n (R)
#define RSA_REG_OUT_E_OFFSET  0x08   // bits[15:0] = out_e (R), bit16 = ready (R)
#define RSA_REG_OUT_D_OFFSET  0x0C   // bits[15:0] = out_d (R)

#define RSA_CTRL_START_BIT    (1u << 0)
#define RSA_CTRL_CLEAR_BIT    (1u << 1)
#define RSA_READY_BIT         (1u << 16)
#define RSA_16BIT_MASK        0xFFFFu

#endif // RSA_KEY_GENERATOR_REGS_H
