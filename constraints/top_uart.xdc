## Arty S7-50 constraints for top_uart
## Only the pins used by this design are uncommented.

## 12 MHz oscillator clock
set_property -dict { PACKAGE_PIN F14  IOSTANDARD LVCMOS33 } [get_ports { CLK12MHZ }];
create_clock -add -name sys_clk_pin -period 83.333 -waveform {0 41.667} [get_ports { CLK12MHZ }];

## Reset button (ck_rst, active-low)
set_property -dict { PACKAGE_PIN C18  IOSTANDARD LVCMOS33 } [get_ports { ck_rst }];

## USB-UART TX (board label: uart_rxd_out — this is the FPGA→PC direction)
set_property -dict { PACKAGE_PIN R12  IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }];

## LED[0] — done indicator
set_property -dict { PACKAGE_PIN E18  IOSTANDARD LVCMOS33 } [get_ports { led }];

## Required configuration properties (keep from master XDC)
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property INTERNAL_VREF 0.675 [get_iobanks 34]
