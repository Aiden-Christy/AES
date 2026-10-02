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
create_clock -period 6.000 -name sys_clk_pin -waveform {0.000 3.000} -add [get_ports i_clk]

# No multicycle path needed: this core only stores the raw cipher key on key_load
# (key_reg -> dut/key_store is a direct register-to-register copy, no key expansion).


##--------------------------------------------------------------------------------------------------------------------------------------
##  DEVICE PINOUT
##--------------------------------------------------------------------------------------------------------------------------------------

# Set IO standard voltage and pins for PC104 Connector Port A
#set_property -dict {PACKAGE_PIN R2  IOSTANDARD LVCMOS33} [get_ports {io_port_A[31]}]
#set_property -dict {PACKAGE_PIN R3  IOSTANDARD LVCMOS33} [get_ports {io_port_A[30]}]
#set_property -dict {PACKAGE_PIN T1  IOSTANDARD LVCMOS33} [get_ports {io_port_A[29]}]
#set_property -dict {PACKAGE_PIN T3  IOSTANDARD LVCMOS33} [get_ports {io_port_A[28]}]
#set_property -dict {PACKAGE_PIN U1  IOSTANDARD LVCMOS33} [get_ports {io_port_A[27]}]
#set_property -dict {PACKAGE_PIN U2  IOSTANDARD LVCMOS33} [get_ports {io_port_A[26]}]
#set_property -dict {PACKAGE_PIN V2  IOSTANDARD LVCMOS33} [get_ports {io_port_A[25]}]
#set_property -dict {PACKAGE_PIN U3  IOSTANDARD LVCMOS33} [get_ports {io_port_A[24]}]
#set_property -dict {PACKAGE_PIN W1  IOSTANDARD LVCMOS33} [get_ports {io_port_A[23]}]
#set_property -dict {PACKAGE_PIN W2  IOSTANDARD LVCMOS33} [get_ports {io_port_A[22]}]
#set_property -dict {PACKAGE_PIN Y2  IOSTANDARD LVCMOS33} [get_ports {io_port_A[21]}]
#set_property -dict {PACKAGE_PIN Y1  IOSTANDARD LVCMOS33} [get_ports {io_port_A[20]}]
#set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVCMOS33} [get_ports {io_port_A[19]}]
#set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVCMOS33} [get_ports {io_port_A[18]}]
#set_property -dict {PACKAGE_PIN Y3  IOSTANDARD LVCMOS33} [get_ports {io_port_A[17]}]
#set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVCMOS33} [get_ports {io_port_A[16]}]
#set_property -dict {PACKAGE_PIN AA3 IOSTANDARD LVCMOS33} [get_ports {io_port_A[15]}]
#set_property -dict {PACKAGE_PIN AB3 IOSTANDARD LVCMOS33} [get_ports {io_port_A[14]}]
#set_property -dict {PACKAGE_PIN AA5 IOSTANDARD LVCMOS33} [get_ports {io_port_A[13]}]
#set_property -dict {PACKAGE_PIN W5  IOSTANDARD LVCMOS33} [get_ports {io_port_A[12]}]
#set_property -dict {PACKAGE_PIN AB5 IOSTANDARD LVCMOS33} [get_ports {io_port_A[11]}]
#set_property -dict {PACKAGE_PIN AB6 IOSTANDARD LVCMOS33} [get_ports {io_port_A[10]}]
#set_property -dict {PACKAGE_PIN AA6 IOSTANDARD LVCMOS33} [get_ports {io_port_A[9]}]
#set_property -dict {PACKAGE_PIN Y6  IOSTANDARD LVCMOS33} [get_ports {io_port_A[8]}]
#set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS33} [get_ports {io_port_A[7]}]
#set_property -dict {PACKAGE_PIN AB8 IOSTANDARD LVCMOS33} [get_ports {io_port_A[6]}]
#set_property -dict {PACKAGE_PIN Y7  IOSTANDARD LVCMOS33} [get_ports {io_port_A[5]}]
#set_property -dict {PACKAGE_PIN AA8 IOSTANDARD LVCMOS33} [get_ports {io_port_A[4]}]
#set_property -dict {PACKAGE_PIN V8  IOSTANDARD LVCMOS33} [get_ports {io_port_A[3]}]
#set_property -dict {PACKAGE_PIN Y9  IOSTANDARD LVCMOS33} [get_ports {io_port_A[2]}]
#set_property -dict {PACKAGE_PIN V9  IOSTANDARD LVCMOS33} [get_ports {io_port_A[1]}]
#set_property -dict {PACKAGE_PIN W9  IOSTANDARD LVCMOS33} [get_ports {io_port_A[0]}]
#
#
## Set IO standard voltage and pins for PC104 Connector Port B
#set_property -dict {PACKAGE_PIN B2  IOSTANDARD LVCMOS33} [get_ports {io_port_B[31]}]
#set_property -dict {PACKAGE_PIN A1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[30]}]
#set_property -dict {PACKAGE_PIN B1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[29]}]
#set_property -dict {PACKAGE_PIN C2  IOSTANDARD LVCMOS33} [get_ports {io_port_B[28]}]
#set_property -dict {PACKAGE_PIN D1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[27]}]
#set_property -dict {PACKAGE_PIN G1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[26]}]
#set_property -dict {PACKAGE_PIN E1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[25]}]
#set_property -dict {PACKAGE_PIN F1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[24]}]
#set_property -dict {PACKAGE_PIN D2  IOSTANDARD LVCMOS33} [get_ports {io_port_B[23]}]
#set_property -dict {PACKAGE_PIN E2  IOSTANDARD LVCMOS33} [get_ports {io_port_B[22]}]
#set_property -dict {PACKAGE_PIN H2  IOSTANDARD LVCMOS33} [get_ports {io_port_B[21]}]
#set_property -dict {PACKAGE_PIN G2  IOSTANDARD LVCMOS33} [get_ports {io_port_B[20]}]
#set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[19]}]
#set_property -dict {PACKAGE_PIN K1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[18]}]
#set_property -dict {PACKAGE_PIN L1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[17]}]
#set_property -dict {PACKAGE_PIN M1  IOSTANDARD LVCMOS33} [get_ports {io_port_B[16]}]
#set_property -dict {PACKAGE_PIN G3  IOSTANDARD LVCMOS33} [get_ports {io_port_B[15]}]
#set_property -dict {PACKAGE_PIN L3  IOSTANDARD LVCMOS33} [get_ports {io_port_B[14]}]
#set_property -dict {PACKAGE_PIN H3  IOSTANDARD LVCMOS33} [get_ports {io_port_B[13]}]
#set_property -dict {PACKAGE_PIN K3  IOSTANDARD LVCMOS33} [get_ports {io_port_B[12]}]
#set_property -dict {PACKAGE_PIN R4  IOSTANDARD LVCMOS33} [get_ports {io_port_B[11]}]
#set_property -dict {PACKAGE_PIN T4  IOSTANDARD LVCMOS33} [get_ports {io_port_B[10]}]
#set_property -dict {PACKAGE_PIN V4  IOSTANDARD LVCMOS33} [get_ports {io_port_B[9]}]
#set_property -dict {PACKAGE_PIN W4  IOSTANDARD LVCMOS33} [get_ports {io_port_B[8]}]
#set_property -dict {PACKAGE_PIN AA4 IOSTANDARD LVCMOS33} [get_ports {io_port_B[7]}]
#set_property -dict {PACKAGE_PIN U5  IOSTANDARD LVCMOS33} [get_ports {io_port_B[6]}]
#set_property -dict {PACKAGE_PIN Y4  IOSTANDARD LVCMOS33} [get_ports {io_port_B[5]}]
#set_property -dict {PACKAGE_PIN G4  IOSTANDARD LVCMOS33} [get_ports {io_port_B[4]}]
#set_property -dict {PACKAGE_PIN T5  IOSTANDARD LVCMOS33} [get_ports {io_port_B[3]}]
#set_property -dict {PACKAGE_PIN K4  IOSTANDARD LVCMOS33} [get_ports {io_port_B[2]}]
#set_property -dict {PACKAGE_PIN J4  IOSTANDARD LVCMOS33} [get_ports {io_port_B[1]}]
#set_property -dict {PACKAGE_PIN H4  IOSTANDARD LVCMOS33} [get_ports {io_port_B[0]}]
#
#
## Set IO standard voltage and pins for PC104 Connector Port C
#set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports {io_port_C[5]}]
#set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {io_port_C[4]}]
#set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {io_port_C[3]}]
#set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {io_port_C[2]}]
#set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {io_port_C[1]}]
#set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {io_port_C[0]}]
#
## Set IO standard voltage and pins for the MSP430 SPI Port
#set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {io_msp430_spi[3]}]
#set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {io_msp430_spi[2]}]
#set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {io_msp430_spi[1]}]
#set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports {io_msp430_spi[0]}]
#
#
## Set IO standard voltage and pins for NOR FLASH chips
#set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports {o_mem_00_sclk}]
#set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports {o_mem_00_cs}]
#set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports {o_mem_00_d0}]
#set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports {i_mem_00_d1}]
#
#set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports {o_mem_01_sclk}]
#set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS33} [get_ports {o_mem_01_cs}]
#set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVCMOS33} [get_ports {o_mem_01_d0}]
#set_property -dict {PACKAGE_PIN N22 IOSTANDARD LVCMOS33} [get_ports {i_mem_01_d1}]
#
#set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS33} [get_ports {o_mem_02_sclk}]
#set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS33} [get_ports {o_mem_02_cs}]
#set_property -dict {PACKAGE_PIN L21 IOSTANDARD LVCMOS33} [get_ports {o_mem_02_d0}]
#set_property -dict {PACKAGE_PIN J22 IOSTANDARD LVCMOS33} [get_ports {i_mem_02_d1}]
#
#set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports {o_mem_03_sclk}]
#set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports {o_mem_03_cs}]
#set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS33} [get_ports {o_mem_03_d0}]
#set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {i_mem_03_d1}]
#

##--------------------------------------------------------------------------------------------------------------------------------------
##  END OF CODE, ANY LINES BEYOND THIS POINT ARE AUTO-GENERATED AND SHOULD BE CHECKED BEFORE USE
##--------------------------------------------------------------------------------------------------------------------------------------



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_clk_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 2 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {key_idx[0]} {key_idx[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 128 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {ciphertext[0]} {ciphertext[1]} {ciphertext[2]} {ciphertext[3]} {ciphertext[4]} {ciphertext[5]} {ciphertext[6]} {ciphertext[7]} {ciphertext[8]} {ciphertext[9]} {ciphertext[10]} {ciphertext[11]} {ciphertext[12]} {ciphertext[13]} {ciphertext[14]} {ciphertext[15]} {ciphertext[16]} {ciphertext[17]} {ciphertext[18]} {ciphertext[19]} {ciphertext[20]} {ciphertext[21]} {ciphertext[22]} {ciphertext[23]} {ciphertext[24]} {ciphertext[25]} {ciphertext[26]} {ciphertext[27]} {ciphertext[28]} {ciphertext[29]} {ciphertext[30]} {ciphertext[31]} {ciphertext[32]} {ciphertext[33]} {ciphertext[34]} {ciphertext[35]} {ciphertext[36]} {ciphertext[37]} {ciphertext[38]} {ciphertext[39]} {ciphertext[40]} {ciphertext[41]} {ciphertext[42]} {ciphertext[43]} {ciphertext[44]} {ciphertext[45]} {ciphertext[46]} {ciphertext[47]} {ciphertext[48]} {ciphertext[49]} {ciphertext[50]} {ciphertext[51]} {ciphertext[52]} {ciphertext[53]} {ciphertext[54]} {ciphertext[55]} {ciphertext[56]} {ciphertext[57]} {ciphertext[58]} {ciphertext[59]} {ciphertext[60]} {ciphertext[61]} {ciphertext[62]} {ciphertext[63]} {ciphertext[64]} {ciphertext[65]} {ciphertext[66]} {ciphertext[67]} {ciphertext[68]} {ciphertext[69]} {ciphertext[70]} {ciphertext[71]} {ciphertext[72]} {ciphertext[73]} {ciphertext[74]} {ciphertext[75]} {ciphertext[76]} {ciphertext[77]} {ciphertext[78]} {ciphertext[79]} {ciphertext[80]} {ciphertext[81]} {ciphertext[82]} {ciphertext[83]} {ciphertext[84]} {ciphertext[85]} {ciphertext[86]} {ciphertext[87]} {ciphertext[88]} {ciphertext[89]} {ciphertext[90]} {ciphertext[91]} {ciphertext[92]} {ciphertext[93]} {ciphertext[94]} {ciphertext[95]} {ciphertext[96]} {ciphertext[97]} {ciphertext[98]} {ciphertext[99]} {ciphertext[100]} {ciphertext[101]} {ciphertext[102]} {ciphertext[103]} {ciphertext[104]} {ciphertext[105]} {ciphertext[106]} {ciphertext[107]} {ciphertext[108]} {ciphertext[109]} {ciphertext[110]} {ciphertext[111]} {ciphertext[112]} {ciphertext[113]} {ciphertext[114]} {ciphertext[115]} {ciphertext[116]} {ciphertext[117]} {ciphertext[118]} {ciphertext[119]} {ciphertext[120]} {ciphertext[121]} {ciphertext[122]} {ciphertext[123]} {ciphertext[124]} {ciphertext[125]} {ciphertext[126]} {ciphertext[127]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 3 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {pt_idx[0]} {pt_idx[1]} {pt_idx[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list in_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list key_load]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list key_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list out_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets i_clk_IBUF_BUFG]
