#include <stdio.h>
#include "xil_io.h"
#include "xparameters.h"
#include "rsa_key_generator_regs.h"

// Update this to the macro name Vitis generates for IP instance in
// xparameters.h (search for "S00_AXI_BASEADDR" after creating the BSP).
#define RSA_BASEADDR XPAR_RSA_KEY_GENERATOR_0_S00_AXI_BASEADDR

static void rsa_pulse_start(void)
{
    Xil_Out32(RSA_BASEADDR + RSA_REG_CTRL_OFFSET, RSA_CTRL_START_BIT);
    Xil_Out32(RSA_BASEADDR + RSA_REG_CTRL_OFFSET, 0);
}

static void rsa_pulse_clear(void)
{
    Xil_Out32(RSA_BASEADDR + RSA_REG_CTRL_OFFSET, RSA_CTRL_CLEAR_BIT);
    Xil_Out32(RSA_BASEADDR + RSA_REG_CTRL_OFFSET, 0);
}

static int rsa_is_ready(void)
{
    u32 reg = Xil_In32(RSA_BASEADDR + RSA_REG_OUT_E_OFFSET);
    return (reg & RSA_READY_BIT) != 0;
}

int main()
{
    u32 n, e, d;
    u32 timeout;

    print("RSA key generator demo\r\n");

    rsa_pulse_clear();
    rsa_pulse_start();

    print("Waiting for key generation...\r\n");
    timeout = 0;
    while (!rsa_is_ready()) {
        timeout++;
        if (timeout > 100000000u) {
            print("Timed out waiting for ready - check clear/start wiring.\r\n");
            return -1;
        }
    }

    n = Xil_In32(RSA_BASEADDR + RSA_REG_OUT_N_OFFSET) & RSA_16BIT_MASK;
    e = Xil_In32(RSA_BASEADDR + RSA_REG_OUT_E_OFFSET) & RSA_16BIT_MASK;
    d = Xil_In32(RSA_BASEADDR + RSA_REG_OUT_D_OFFSET) & RSA_16BIT_MASK;

    xil_printf("n = %lu\r\n", n);
    xil_printf("e = %lu\r\n", e);
    xil_printf("d = %lu\r\n", d);

    return 0;
}
