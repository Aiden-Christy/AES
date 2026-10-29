##--------------------------------------------------------------------------------------------------------------------------------------
##
##	RADPC
##  HYDRA (SBC-001) BOARD INSTANTIATION CONSTRAINTS TEMPLATE
##
##	Created by Chris Major & Hezekiah Austin
## 	3/28/2024
##
##	A constraints template for the Resilient Computing Hydra board, using the Xilinx Artix-7 XC7A100T-FGB484I FPGA.
##
##--------------------------------------------------------------------------------------------------------------------------------------


##--------------------------------------------------------------------------------------------------------------------------------------
##  CONFIGURATION STANDARDS
##--------------------------------------------------------------------------------------------------------------------------------------

# Set the Essential Bits reporting in the design
set_property BITSTREAM.SEU.ESSENTIALBITS YES [current_design]

# Set the configuration voltage to 3.3 [V]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Set the Configuration Bank Voltage Select (CFGBVS) to VCCO
set_property CFGBVS VCCO [current_design]

# Compress the bitstreams to try and improve performance
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]


##--------------------------------------------------------------------------------------------------------------------------------------
##  CLOCK AND RESET
##--------------------------------------------------------------------------------------------------------------------------------------

# Set IO standard voltage and pins for the Rev. A input clock (16 MHz)
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports i_clk]

# Set IO standard voltage and pins for the Rev. A active low reset
set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS33} [get_ports i_reset_n]


##--------------------------------------------------------------------------------------------------------------------------------------
##  CLOCKING CONSTRAINTS
##--------------------------------------------------------------------------------------------------------------------------------------

# Create dedicated clock in Vivado based on input clock pin (16 [MHz])
create_clock -period 62.500 -name sys_clk_pin -waveform {0.000 31.250} -add [get_ports i_clk]


##--------------------------------------------------------------------------------------------------------------------------------------
##  DEVICE PINOUT
##--------------------------------------------------------------------------------------------------------------------------------------

# Set IO standard voltage and pins for PC104 Connector Port A
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {io_port_A[31]}]
set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports {io_port_A[30]}]
set_property -dict {PACKAGE_PIN T1 IOSTANDARD LVCMOS33} [get_ports {io_port_A[29]}]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports {io_port_A[28]}]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS33} [get_ports {io_port_A[27]}]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {io_port_A[26]}]
set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports {io_port_A[25]}]
set_property -dict {PACKAGE_PIN U3 IOSTANDARD LVCMOS33} [get_ports {io_port_A[24]}]
set_property -dict {PACKAGE_PIN W1 IOSTANDARD LVCMOS33} [get_ports {io_port_A[23]}]
set_property -dict {PACKAGE_PIN W2 IOSTANDARD LVCMOS33} [get_ports {io_port_A[22]}]
set_property -dict {PACKAGE_PIN Y2 IOSTANDARD LVCMOS33} [get_ports {io_port_A[21]}]
set_property -dict {PACKAGE_PIN Y1 IOSTANDARD LVCMOS33} [get_ports {io_port_A[20]}]
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVCMOS33} [get_ports {io_port_A[19]}]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVCMOS33} [get_ports {io_port_A[18]}]
set_property -dict {PACKAGE_PIN Y3 IOSTANDARD LVCMOS33} [get_ports {io_port_A[17]}]
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVCMOS33} [get_ports {io_port_A[16]}]
set_property -dict {PACKAGE_PIN AA3 IOSTANDARD LVCMOS33} [get_ports {io_port_A[15]}]
set_property -dict {PACKAGE_PIN AB3 IOSTANDARD LVCMOS33} [get_ports {io_port_A[14]}]
set_property -dict {PACKAGE_PIN AA5 IOSTANDARD LVCMOS33} [get_ports {io_port_A[13]}]
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports {io_port_A[12]}]
set_property -dict {PACKAGE_PIN AB5 IOSTANDARD LVCMOS33} [get_ports {io_port_A[11]}]
set_property -dict {PACKAGE_PIN AB6 IOSTANDARD LVCMOS33} [get_ports {io_port_A[10]}]
set_property -dict {PACKAGE_PIN AA6 IOSTANDARD LVCMOS33} [get_ports {io_port_A[9]}]
set_property -dict {PACKAGE_PIN Y6 IOSTANDARD LVCMOS33} [get_ports {io_port_A[8]}]
set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS33} [get_ports {io_port_A[7]}]
set_property -dict {PACKAGE_PIN AB8 IOSTANDARD LVCMOS33} [get_ports {io_port_A[6]}]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS33} [get_ports {io_port_A[5]}]
set_property -dict {PACKAGE_PIN AA8 IOSTANDARD LVCMOS33} [get_ports {io_port_A[4]}]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports {io_port_A[3]}]
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports {io_port_A[2]}]
set_property -dict {PACKAGE_PIN V9 IOSTANDARD LVCMOS33} [get_ports {io_port_A[1]}]
set_property -dict {PACKAGE_PIN W9 IOSTANDARD LVCMOS33} [get_ports {io_port_A[0]}]


# Set IO standard voltage and pins for PC104 Connector Port B
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS33} [get_ports {io_port_B[31]}]
set_property -dict {PACKAGE_PIN A1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[30]}]
set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[29]}]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports {io_port_B[28]}]
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[27]}]
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[26]}]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[25]}]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[24]}]
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports {io_port_B[23]}]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports {io_port_B[22]}]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports {io_port_B[21]}]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {io_port_B[20]}]
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[19]}]
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[18]}]
set_property -dict {PACKAGE_PIN L1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[17]}]
set_property -dict {PACKAGE_PIN M1 IOSTANDARD LVCMOS33} [get_ports {io_port_B[16]}]
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports {io_port_B[15]}]
set_property -dict {PACKAGE_PIN L3 IOSTANDARD LVCMOS33} [get_ports {io_port_B[14]}]
set_property -dict {PACKAGE_PIN H3 IOSTANDARD LVCMOS33} [get_ports {io_port_B[13]}]
set_property -dict {PACKAGE_PIN K3 IOSTANDARD LVCMOS33} [get_ports {io_port_B[12]}]
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[11]}]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[10]}]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[9]}]
set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[8]}]
set_property -dict {PACKAGE_PIN AA4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[7]}]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports {io_port_B[6]}]
set_property -dict {PACKAGE_PIN Y4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[5]}]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[4]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports {io_port_B[3]}]
set_property -dict {PACKAGE_PIN K4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[2]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[1]}]
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[0]}]


# Set IO standard voltage and pins for PC104 Connector Port C
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports {io_port_C[5]}]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {io_port_C[4]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {io_port_C[3]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {io_port_C[2]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {io_port_C[1]}]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {io_port_C[0]}]

# Set IO standard voltage and pins for the MSP430 SPI Port
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {io_msp430_spi[3]}]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {io_msp430_spi[2]}]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {io_msp430_spi[1]}]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports {io_msp430_spi[0]}]


# Set IO standard voltage and pins for NOR FLASH chips
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports o_mem_00_sclk]
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports o_mem_00_cs]
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports o_mem_00_d0]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports i_mem_00_d1]

set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports o_mem_01_sclk]
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS33} [get_ports o_mem_01_cs]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVCMOS33} [get_ports o_mem_01_d0]
set_property -dict {PACKAGE_PIN N22 IOSTANDARD LVCMOS33} [get_ports i_mem_01_d1]

set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS33} [get_ports o_mem_02_sclk]
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS33} [get_ports o_mem_02_cs]
set_property -dict {PACKAGE_PIN L21 IOSTANDARD LVCMOS33} [get_ports o_mem_02_d0]
set_property -dict {PACKAGE_PIN J22 IOSTANDARD LVCMOS33} [get_ports i_mem_02_d1]

set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports o_mem_03_sclk]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports o_mem_03_cs]
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS33} [get_ports o_mem_03_d0]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports i_mem_03_d1]


##--------------------------------------------------------------------------------------------------------------------------------------
##  FLOORPLANNING
##--------------------------------------------------------------------------------------------------------------------------------------

# Create PBLOCK for Hardware Accelerator
create_pblock hwa_pblock_00

# Assign Hardware Accelerator netlist to Hardware Accelerator PBLOCK
add_cells_to_pblock [get_pblocks hwa_pblock_00] [get_cells -quiet [list GENERATE_HWA.HW_ACCEL_01/HWA_00]]

# Assign FPGA Resources to PBLOCK
resize_pblock [get_pblocks hwa_pblock_00] -add {SLICE_X84Y100:SLICE_X163Y149 \
                                                DSP48_X5Y40:DSP48_X8Y59 \
                                                RAMB18_X5Y40:RAMB18_X8Y59 \
                                                RAMB36_X5Y20:RAMB36_X8Y29 \
}

# Set the PBLOCK to snapping mode
set_property SNAPPING_MODE ON [get_pblocks hwa_pblock_00]

# Enable Reset Upon Reconfigure
set_property RESET_AFTER_RECONFIG TRUE [get_pblocks hwa_pblock_00]


##--------------------------------------------------------------------------------------------------------------------------------------
##  END OF CODE, ANY LINES BEYOND THIS POINT ARE AUTO-GENERATED AND SHOULD BE CHECKED BEFORE USE
##--------------------------------------------------------------------------------------------------------------------------------------