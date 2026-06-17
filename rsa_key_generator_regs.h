#ifndef RSA_KEY_GENERATOR_REGS_H
#define RSA_KEY_GENERATOR_REGS_H


#define RSA_REG_CTRL_OFFSET   0x00   
#define RSA_REG_OUT_N_OFFSET  0x04   
#define RSA_REG_OUT_E_OFFSET  0x08   
#define RSA_REG_OUT_D_OFFSET  0x0C   

#define RSA_CTRL_START_BIT    (1u << 0)
#define RSA_CTRL_CLEAR_BIT    (1u << 1)
#define RSA_READY_BIT         (1u << 16)
#define RSA_16BIT_MASK        0xFFFFu

#endif // RSA_KEY_GENERATOR_REGS_H
