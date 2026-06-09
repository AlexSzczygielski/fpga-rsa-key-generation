## Arty S7-50 Rev E constraints for top_uart
## Part: xc7s50csga324-1
##
## Using 100 MHz DDR clock (R2, bank 34, SSTL135) — proper MRCC pin, no BUFG routing issues.
## UART divisor in top_uart.v must be 10417 (100_000_000 / 9600).

## 100 MHz clock (bank 34, SSTL135)
set_property -dict { PACKAGE_PIN R2  IOSTANDARD SSTL135 } [get_ports { CLK }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5.000} [get_ports { CLK }];

## Reset button (ck_rst, active-low, bank 15, LVCMOS33)
set_property -dict { PACKAGE_PIN C18  IOSTANDARD LVCMOS33 } [get_ports { ck_rst }];

## USB-UART TX to PC (R12, bank 14, LVCMOS33)
## Signal name on schematic: uart_rxd_out (direction is from PC's perspective)
set_property -dict { PACKAGE_PIN R12  IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }];

## LED[0] — done indicator (E18, bank 15, LVCMOS33)
set_property -dict { PACKAGE_PIN E18  IOSTANDARD LVCMOS33 } [get_ports { led }];

## Required configuration properties
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property INTERNAL_VREF 0.675 [get_iobanks 34]
