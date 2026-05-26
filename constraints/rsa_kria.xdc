# -----------------------------------------------------------------------------
# Constraints for Kria KV260 - RSA PoC
# PL fabric clock from PS (configure in block design as 100 MHz)
# UART TX routed to PMOD connector (adjust pin if needed)
# -----------------------------------------------------------------------------

# PL Fabric Clock - driven from PS in block design, not constrained here
# If using a standalone clock source, uncomment and adjust:
# create_clock -period 10.000 -name CLK [get_ports CLK]

# UART TX - PMOD JA pin 1 (adjust to your wiring)
# Kria KV260 PMOD connector - check your board schematic
set_property PACKAGE_PIN  H12     [get_ports UART_TX]
set_property IOSTANDARD   LVCMOS33 [get_ports UART_TX]

# Active-low reset - PMOD JA pin 2 (or tie to PS GPIO)
set_property PACKAGE_PIN  B11     [get_ports RSTN]
set_property IOSTANDARD   LVCMOS33 [get_ports RSTN]

# Timing - relax for PoC (modulo operation is multi-cycle)
set_multicycle_path 4 -setup -from [get_cells -hierarchical -filter {NAME =~ *state*}]
set_multicycle_path 3 -hold  -from [get_cells -hierarchical -filter {NAME =~ *state*}]
