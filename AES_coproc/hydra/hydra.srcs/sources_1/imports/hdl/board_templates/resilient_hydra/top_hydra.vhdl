----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	
--	COMPONENT:			TOP_HYDRA
--	DESCRIPTION:		TOP-LEVEL IMPLEMENTATION FOR 4MR RADPC ON THE HYDRA BOARD (SBC-001)
--
--	DEVELOPERS:			CHRIS MAJOR, HEZEKIAH AUSTIN
--	COMPANY:			RESILIENT COMPUTING
--	DATE:				8/29/24
--
--	THIS FILE AND ITS CONTENTS ARE PROPRIETARY AND THE INTELLECTUAL PROPERTY OF RESILIENT COMPUTING
--	PATENT NO. US 12,050,688 B1
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
-- 	LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	--! IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;

	--! IEEE Numeric Standard Library
	use IEEE.NUMERIC_STD.ALL;


	-- RadPC Reach Core Package
	use WORK.REACH_CORE_PKG.all;


-- UNISIM Standard Library
library UNISIM;

	-- Xilinx UNISIM Components Library
	use UNISIM.vcomponents.all;


----------------------------------------------------------------------------------------------------------------------------------------
-- 	ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity top_hydra is
port(
	i_clk							: in 	std_logic;							-- Input Clock (16 MHz)
	i_reset_n						: in	std_logic;							-- Active Low Reset

	io_port_A						: inout	std_logic_vector(31 downto 0);		-- PC104 Port A
	io_port_B						: inout	std_logic_vector(31 downto 0);		-- PC104 Port B
	io_port_C						: inout	std_logic_vector(5 downto 0);		-- PC104 Port C

	io_msp430_spi					: inout std_logic_vector(3 downto 0);		-- MSP430 SPI Port

	o_mem_00_sclk					: out 	std_logic;							--! Memory Clock (FPGA MEM 00)
	o_mem_00_cs						: out 	std_logic;							--! Memory Chip Select (FPGA External Memory 00)	
	o_mem_00_d0						: out 	std_logic;							--! Memory Serial I/O (FPGA External Memory 00)		
	i_mem_00_d1						: in 	std_logic;							--! Memory Serial I/O (FPGA External Memory 00)

	o_mem_01_sclk					: out 	std_logic;							--! Memory Clock (FPGA MEM 01)
	o_mem_01_cs						: out 	std_logic;							--! Memory Chip Select (FPGA External Memory 01)	
	o_mem_01_d0						: out 	std_logic;							--! Memory Serial I/O (FPGA External Memory 01)		
	i_mem_01_d1						: in 	std_logic;							--! Memory Serial I/O (FPGA External Memory 01)

	o_mem_02_sclk					: out 	std_logic;							--! Memory Clock (FPGA MEM 00)
	o_mem_02_cs						: out 	std_logic;							--! Memory Chip Select (FPGA External Memory 02)	
	o_mem_02_d0						: out 	std_logic;							--! Memory Serial I/O (FPGA External Memory 02)		
	i_mem_02_d1						: in 	std_logic;							--! Memory Serial I/O (FPGA External Memory 02)

	o_mem_03_sclk					: out 	std_logic;							--! Memory Clock (FPGA MEM 03)
	o_mem_03_cs						: out 	std_logic;							--! Memory Chip Select (FPGA External Memory 03)	
	o_mem_03_d0						: out 	std_logic;							--! Memory Serial I/O (FPGA External Memory 03)		
	i_mem_03_d1						: in 	std_logic							--! Memory Serial I/O (FPGA External Memory 03)
);
end top_hydra;


----------------------------------------------------------------------------------------------------------------------------------------
--	ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture top_hydra_arch of top_hydra is


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the RadPC component
	component radpc_core is
	generic (
		g_CLK_RATE                	: integer           := 100_000_000							-- Clock rate [Hz]
	);
	port (
		i_clk						: in	std_logic;			                               	-- Clock
		i_reset_n					: in	std_logic;			                               	-- Reset (Active Low)

		i_bootload_en               : in    std_logic;                                          -- Bootload Enable
		o_radpc_active              : out   std_logic;                                          -- RadPC Active Flag
		o_illegal_opcode			: out	std_logic;								            -- Illegal Opcode Flag
		o_runtime_stat              : out   std_logic_vector(31 downto 0);                     	-- Runtime Status
		o_pc                        : out   std_logic_vector(31 downto 0);                      -- Program Count (PC)
		o_instr                     : out   std_logic_vector(31 downto 0);                      -- Instruction

		o_monitor_stat				: out	std_logic_vector(7 downto 0);						-- Monitor Status Flags
		o_arbiter_stat				: out	std_logic_vector(7 downto 0);						-- Arbiter Status Flags
		o_imem_scrub_stat			: out	std_logic_vector(7 downto 0);						-- IMEM Scrubber Status Flags
		o_dmem_scrub_stat			: out	std_logic_vector(7 downto 0);						-- DMEM Scrubber Status Flags

		i_sem_status                : in    std_logic_vector(7 downto 0);                       -- SEM Controller Status

		o_port_A_sel                : out   std_logic_vector(31 downto 0);                     	-- Port A Select
		o_port_B_sel                : out   std_logic_vector(31 downto 0);                     	-- Port B Select
		o_port_C_sel                : out   std_logic_vector(31 downto 0);                     	-- Port C Select

		i_gpio_00_in				: in 	std_logic_vector(31 downto 0);						-- GPIO Input Pins 00
		o_gpio_00_out				: out 	std_logic_vector(31 downto 0);						-- GPIO Output Pins 00
		o_gpio_00_dir				: out 	std_logic_vector(31 downto 0);						-- GPIO Direction 00

		i_gpio_01_in				: in 	std_logic_vector(31 downto 0);						-- GPIO Input Pins 01
		o_gpio_01_out				: out 	std_logic_vector(31 downto 0);						-- GPIO Output Pins 01
		o_gpio_01_dir				: out 	std_logic_vector(31 downto 0);						-- GPIO Direction 01

		i_gpio_02_in				: in 	std_logic_vector(31 downto 0);						-- GPIO Input Pins 02
		o_gpio_02_out				: out 	std_logic_vector(31 downto 0);						-- GPIO Output Pins 02
		o_gpio_02_dir				: out 	std_logic_vector(31 downto 0);						-- GPIO Direction 02

		i_uart_00_rx				: in	std_logic;			                                -- UART 00 RX
		o_uart_00_tx				: out	std_logic;			                                -- UART 00 TX
		o_uart_00_en                : out	std_logic;			                                -- UART 00 Enable

		i_uart_01_rx				: in	std_logic;			                                -- UART 01 RX
		o_uart_01_tx				: out	std_logic;			                                -- UART 01 TX
		o_uart_01_en                : out	std_logic;			                                -- UART 01 Enable

		i_uart_02_rx				: in	std_logic;			                                -- UART 02 RX
		o_uart_02_tx				: out	std_logic;			                                -- UART 02 TX
		o_uart_02_en                : out	std_logic;			                                -- UART 02 Enable

		i_uart_03_rx				: in	std_logic;			                                -- UART 03 RX
		o_uart_03_tx				: out	std_logic;			                                -- UART 03 TX
		o_uart_03_en                : out	std_logic;			                                -- UART 03 Enable

		i_miso_boot					: in	std_logic;											-- BOOT Input Master In Slave Out (MISO)
		o_miso_boot					: out	std_logic;											-- BOOT Output Master In Slave Out (MISO)
		i_mosi_boot					: in	std_logic;											-- BOOT Input Master Out Slave In (MOSI)
		o_mosi_boot					: out	std_logic;											-- BOOT Output Master Out Slave In (MOSI)
		i_sclk_boot					: in	std_logic;											-- BOOT Incoming Serial Clock (SCLK)
		o_sclk_boot					: out	std_logic;											-- BOOT Outgoing Serial Clock (SCLK)
		i_cs_boot 					: in	std_logic;											-- BOOT Incoming Serial Data (CS)
		o_cs_boot 					: out	std_logic;											-- BOOT Outgoing Serial Data (CS)
		o_boot_mode					: out	std_logic;											-- BOOT Mode

		i_miso_00					: in	std_logic;											-- SPI 00 Input Master In Slave Out (MISO)
		o_miso_00					: out	std_logic;											-- SPI 00 Output Master In Slave Out (MISO)
		i_mosi_00					: in	std_logic;											-- SPI 00 Input Master Out Slave In (MOSI)
		o_mosi_00					: out	std_logic;											-- SPI 00 Output Master Out Slave In (MOSI)
		i_sclk_00					: in	std_logic;											-- SPI 00 Incoming Serial Clock (SCLK)
		o_sclk_00					: out	std_logic;											-- SPI 00 Outgoing Serial Clock (SCLK)
		i_cs_00						: in	std_logic;											-- SPI 00 Incoming Serial Data (CS)
		o_cs_00						: out	std_logic;											-- SPI 00 Outgoing Serial Data (CS)
		o_spi_mode_00				: out	std_logic;											-- SPI 00 Mode

		i_miso_01					: in	std_logic;											-- SPI 01 Input Master In Slave Out (MISO)
		o_miso_01					: out	std_logic;											-- SPI 01 Output Master In Slave Out (MISO)
		i_mosi_01					: in	std_logic;											-- SPI 01 Input Master Out Slave In (MOSI)
		o_mosi_01					: out	std_logic;											-- SPI 01 Output Master Out Slave In (MOSI)
		i_sclk_01					: in	std_logic;											-- SPI 01 Incoming Serial Clock (SCLK)
		o_sclk_01					: out	std_logic;											-- SPI 01 Outgoing Serial Clock (SCLK)
		i_cs_01						: in	std_logic;											-- SPI 01 Incoming Serial Data (CS)
		o_cs_01						: out	std_logic;											-- SPI 01 Outgoing Serial Data (CS)
		o_spi_mode_01				: out	std_logic;											-- SPI 01 Mode

		i_miso_02					: in	std_logic;											-- SPI 02 Input Master In Slave Out (MISO)
		o_miso_02					: out	std_logic;											-- SPI 02 Output Master In Slave Out (MISO)
		i_mosi_02					: in	std_logic;											-- SPI 02 Input Master Out Slave In (MOSI)
		o_mosi_02					: out	std_logic;											-- SPI 02 Output Master Out Slave In (MOSI)
		i_sclk_02					: in	std_logic;											-- SPI 02 Incoming Serial Clock (SCLK)
		o_sclk_02					: out	std_logic;											-- SPI 02 Outgoing Serial Clock (SCLK)
		i_cs_02						: in	std_logic;											-- SPI 02 Incoming Serial Data (CS)
		o_cs_02						: out	std_logic;											-- SPI 02 Outgoing Serial Data (CS)
		o_spi_mode_02				: out	std_logic;											-- SPI 02 Mode

		i_miso_03					: in	std_logic;											-- SPI 03 Input Master In Slave Out (MISO)
		o_miso_03					: out	std_logic;											-- SPI 03 Output Master In Slave Out (MISO)
		i_mosi_03					: in	std_logic;											-- SPI 03 Input Master Out Slave In (MOSI)
		o_mosi_03					: out	std_logic;											-- SPI 03 Output Master Out Slave In (MOSI)
		i_sclk_03					: in	std_logic;											-- SPI 03 Incoming Serial Clock (SCLK)
		o_sclk_03					: out	std_logic;											-- SPI 03 Outgoing Serial Clock (SCLK)
		i_cs_03						: in	std_logic;											-- SPI 03 Incoming Serial Data (CS)
		o_cs_03						: out	std_logic;											-- SPI 03 Outgoing Serial Data (CS)
		o_spi_mode_03				: out	std_logic;											-- SPI 03 Mode

		i_miso_flash				: in	std_logic;											-- NOR Flash Master In Slave Out (MISO)
		o_mosi_flash				: out	std_logic;											-- NOR Flash Master Out Slave In (MOSI)
		o_sclk_flash				: out	std_logic;											-- NOR Flash Serial Clock (SCLK)
		o_cs_flash 					: out	std_logic;											-- NOR Flash Serial Data (CS)

		i_scl_00					: in	std_logic;											-- I2C 00 Incoming Serial Clock Line (SCL)
		i_sda_00					: in	std_logic;											-- I2C 00 Incoming Serial Data Line (SDA)
		o_scl_00					: out	std_logic;											-- I2C 00 Outgoing Serial Clock Line (SCL)
		o_sda_00					: out	std_logic;											-- I2C 00 Outgoing Serial Data Line (SDA)
		o_i2c_mode_00				: out	std_logic_vector(1 downto 0);						-- I2C 00 INOUT Mode Control
		
		i_scl_01					: in	std_logic;											-- I2C 01 Incoming Serial Clock Line (SCL)
		i_sda_01					: in	std_logic;											-- I2C 01 Incoming Serial Data Line (SDA)
		o_scl_01					: out	std_logic;											-- I2C 01 Outgoing Serial Clock Line (SCL)
		o_sda_01					: out	std_logic;											-- I2C 01 Outgoing Serial Data Line (SDA)
		o_i2c_mode_01				: out	std_logic_vector(1 downto 0);						-- I2C 01 INOUT Mode Control

		i_adc_data_read				: in	std_logic_vector(15 downto 0);						-- ADC Data Read
		i_adc_channel				: in	std_logic_vector(4 downto 0);						-- ADC Channel
		o_adc_addr					: out	std_logic_vector(6 downto 0);						-- ADC Address

		i_hwa_id					: in	std_logic_vector(7 downto 0);						-- Hardware Accelerator Identification (ID)

		i_hwa_read_00				: in 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Read Word 00
		i_hwa_read_01				: in 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Read Word 01
		i_hwa_read_02				: in 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Read Word 02
		i_hwa_read_03				: in 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Read Word 03
		i_hwa_read_04				: in 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Read Word 04
		i_hwa_read_05				: in 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Read Word 05
		i_hwa_read_06				: in 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Read Word 06
		i_hwa_read_07				: in 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Read Word 07

		o_hwa_write_00				: out 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Write Word 00
		o_hwa_write_01				: out 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Write Word 01
		o_hwa_write_02				: out 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Write Word 02
		o_hwa_write_03				: out 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Write Word 03
		o_hwa_write_04				: out 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Write Word 04
		o_hwa_write_05				: out 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Write Word 05
		o_hwa_write_06				: out 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Write Word 06
		o_hwa_write_07				: out 	std_logic_vector(31 downto 0);						-- Hardware Accelerator Write Word 07

		o_hwa_ctrl					: out	std_logic_vector(7 downto 0);						-- Hardware Accelerator Control (CTRL)
		i_hwa_stat					: in	std_logic_vector(15 downto 0);						-- Hardware Accelerator Status (STAT)

		o_pr_decouple				: out	std_logic											-- Partial Reconfiguration Decoupling Enable
	);
	end component;


	-- Declare the Hardware Accelerator Wrapper
	component hwa_core is
	port(
		i_clk						: in	std_logic;
		i_reset_n					: in	std_logic;

		i_pr_decouple				: in	std_logic;

		o_hwa_id                    : out  	std_logic_vector(7 downto 0);

		i_data_A					: in	std_logic_vector(31 downto 0);
		i_data_B					: in	std_logic_vector(31 downto 0);
		i_data_C					: in	std_logic_vector(31 downto 0);
		i_data_D					: in	std_logic_vector(31 downto 0);
		i_data_E					: in	std_logic_vector(31 downto 0);
		i_data_F					: in	std_logic_vector(31 downto 0);
		i_data_G					: in	std_logic_vector(31 downto 0);
		i_data_H					: in	std_logic_vector(31 downto 0);

		o_data_A					: out	std_logic_vector(31 downto 0);
		o_data_B					: out	std_logic_vector(31 downto 0);
		o_data_C					: out	std_logic_vector(31 downto 0);
		o_data_D					: out	std_logic_vector(31 downto 0);
		o_data_E					: out	std_logic_vector(31 downto 0);
		o_data_F					: out	std_logic_vector(31 downto 0);
		o_data_G					: out	std_logic_vector(31 downto 0);
		o_data_H					: out	std_logic_vector(31 downto 0);

		i_hwa_ctrl					: in	std_logic_vector(7 downto 0);
		o_hwa_stat					: out	std_logic_vector(15 downto 0);

		i_hwaio_in                  : in    std_logic_vector(31 downto 0);
		o_hwaio_out                 : out   std_logic_vector(31 downto 0);
		o_hwaio_dir                 : out   std_logic_vector(31 downto 0)
	);
	end component;


    ------------------------------------------------------------------------------------------------------------------------------------
	--	XILINX IP COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Clock wizard
	component clk_wiz_0 is
	port(
		i_clk						: in		std_logic;
		resetn						: in		std_logic;

		o_clk_00					: out		std_logic
	);
	end component;


	-- Declare the Xilinx Soft Error Mitigation (SEM) IP
	component sem_controller is
	port (
		i_clk                      	: in    	std_logic;                                      -- Input Clock
		
		i_inject_strobe             : in    	std_logic;                                      -- Command Injection Strobe
		i_inject_command            : in    	std_logic_vector( 39 downto 0 );                -- Command Injection 
		
		o_sem_status                : out   	std_logic_vector( 7 downto 0 );                 -- SEM Status Bits
		
		i_icap_to_sem              	: in    	std_logic_vector(31 downto 0);                  -- ICAP port output (SEM input)
		o_sem_to_icap              	: out   	std_logic_vector(31 downto 0);                  -- ICAP port input (SEM output)
		o_icap_csib                	: out   	std_logic;                                      -- ICAP Enable (Active Low)
		o_icap_rdwrb               	: out   	std_logic;                                      -- ICAP Read/Write
		i_icap_grant               	: in    	std_logic;                                      -- ICAP Access Grant
		
		i_fecc_crcerr              	: in    	std_logic;                                      -- Frame ECC CRC Flag
		i_fecc_eccerr              	: in    	std_logic;                                      -- Frame ECC ECC Flag
		i_fecc_eccerrsingle        	: in    	std_logic;                                      -- Frame ECC Single Error Flag
		i_fecc_syndromevalid       	: in    	std_logic;                                      -- Frame ECC Syndrome Valid Flag
		i_fecc_syndrome            	: in    	std_logic_vector(12 downto 0);                  -- Frame ECC Syndrome
		i_fecc_far                 	: in    	std_logic_vector(25 downto 0);                  -- Frame ECC FAR Register
		i_fecc_synbit              	: in    	std_logic_vector(4 downto 0);                   -- Frame ECC Syndrome Bit
		i_fecc_synword             	: in    	std_logic_vector(6 downto 0);                   -- Frame ECC Syndrome Word
		
		i_monitor_rx               	: in    	std_logic;                                      -- SEM UART RX
		o_monitor_tx               	: out   	std_logic                                       -- SEM UART TX
	);
	end component;


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal w_clk_00					: std_logic;												--! Clock 00 (16 MHz)

	signal w_radpc_active			: std_logic;												--! Program Count Active
	signal w_illegal_opcode			: std_logic;												--! Illegal Opcode Flag
	signal r_runtime_stat			: std_logic_vector(31 downto 0);							--! Runtime Status
	signal r_pc						: std_logic_vector(31 downto 0);							--! Program Count
	signal r_instr 					: std_logic_vector(31 downto 0);							--! Current Instruction

	signal r_monitor_status			: std_logic_vector(7 downto 0);								--! Monitor Status Flags
	signal r_arbiter_status			: std_logic_vector(7 downto 0);								--! Arbiter Status Flags
	signal r_imem_scrub_status		: std_logic_vector(7 downto 0);								--! IMEM Scrubber Status Flags
	signal r_dmem_scrub_status		: std_logic_vector(7 downto 0);								--! DMEM Scrubber Status Flags


	signal r_sem_status				: std_logic_vector(7 downto 0);								--! SEM Status


   	signal r_gpio_00_in             : std_logic_vector(31 downto 0);
    signal r_gpio_00_out            : std_logic_vector(31 downto 0);
    signal r_gpio_00_dir            : std_logic_vector(31 downto 0);
    
    signal r_gpio_01_in             : std_logic_vector(31 downto 0);
    signal r_gpio_01_out            : std_logic_vector(31 downto 0);
    signal r_gpio_01_dir            : std_logic_vector(31 downto 0);	

	signal r_gpio_02_in             : std_logic_vector(31 downto 0);
    signal r_gpio_02_out            : std_logic_vector(31 downto 0);
    signal r_gpio_02_dir            : std_logic_vector(31 downto 0);	


	signal w_uart_00_rx				: std_logic;												-- UART RX 00
	signal w_uart_01_rx				: std_logic;												-- UART RX 01
	signal w_uart_02_rx				: std_logic;												-- UART RX 02
	signal w_uart_03_rx				: std_logic;												-- UART RX 03

	signal w_uart_00_tx				: std_logic;												-- UART TX 00
	signal w_uart_01_tx				: std_logic;												-- UART TX 01
	signal w_uart_02_tx				: std_logic;												-- UART TX 02
	signal w_uart_03_tx				: std_logic;												-- UART TX 03

	signal w_uart_00_en				: std_logic;												-- UART EN 00
	signal w_uart_01_en				: std_logic;												-- UART EN 01
	signal w_uart_02_en				: std_logic;												-- UART EN 02
	signal w_uart_03_en				: std_logic;												-- UART EN 03

	signal w_uart_sem_rx			: std_logic;												-- UART RX (SEM)
	signal w_uart_sem_tx			: std_logic;												-- UART TX (SEM)


	signal w_miso_i_boot			: std_logic;
	signal w_miso_o_boot			: std_logic;
	signal w_mosi_i_boot			: std_logic;
	signal w_mosi_o_boot			: std_logic;
	signal w_sclk_i_boot			: std_logic;
	signal w_sclk_o_boot			: std_logic;
	signal w_cs_i_boot				: std_logic;
	signal w_cs_o_boot				: std_logic;
	signal w_boot_mode				: std_logic;

	signal w_miso_i_00				: std_logic;
	signal w_miso_o_00				: std_logic;
	signal w_mosi_i_00				: std_logic;
	signal w_mosi_o_00				: std_logic;
	signal w_sclk_i_00				: std_logic;
	signal w_sclk_o_00				: std_logic;
	signal w_cs_i_00				: std_logic;
	signal w_cs_o_00				: std_logic;
	signal w_spi_mode_00			: std_logic;

	signal w_miso_i_01				: std_logic;
	signal w_miso_o_01				: std_logic;
	signal w_mosi_i_01				: std_logic;
	signal w_mosi_o_01				: std_logic;
	signal w_sclk_i_01				: std_logic;
	signal w_sclk_o_01				: std_logic;
	signal w_cs_i_01				: std_logic;
	signal w_cs_o_01				: std_logic;
	signal w_spi_mode_01			: std_logic;  

	signal w_miso_i_02				: std_logic;
	signal w_miso_o_02				: std_logic;
	signal w_mosi_i_02				: std_logic;
	signal w_mosi_o_02				: std_logic;
	signal w_sclk_i_02				: std_logic;
	signal w_sclk_o_02				: std_logic;
	signal w_cs_i_02				: std_logic;
	signal w_cs_o_02				: std_logic;
	signal w_spi_mode_02			: std_logic;

	signal w_miso_i_03				: std_logic;
	signal w_miso_o_03				: std_logic;
	signal w_mosi_i_03				: std_logic;
	signal w_mosi_o_03				: std_logic;
	signal w_sclk_i_03				: std_logic;
	signal w_sclk_o_03				: std_logic;
	signal w_cs_i_03				: std_logic;
	signal w_cs_o_03				: std_logic;
	signal w_spi_mode_03			: std_logic;  


    signal w_scl_i_00				: std_logic;
	signal w_sda_i_00				: std_logic;
    signal w_scl_o_00               : std_logic;
    signal w_sda_o_00               : std_logic;
    signal w_i2c_mode_00			: std_logic_vector(1 downto 0);

	signal w_scl_i_01				: std_logic;
	signal w_sda_i_01				: std_logic;
    signal w_scl_o_01	            : std_logic;
    signal w_sda_o_01               : std_logic;
    signal w_i2c_mode_01			: std_logic_vector(1 downto 0);


	signal w_adc_13_p				: std_logic;												-- ADC Channel 13 (P-Pin)
	signal w_adc_13_n				: std_logic;												-- ADC Channel 13 (N-Pin)
	signal w_adc_12_p				: std_logic;												-- ADC Channel 12 (P-Pin)
	signal w_adc_12_n				: std_logic;												-- ADC Channel 12 (N-Pin)
	signal w_adc_5_p				: std_logic;												-- ADC Channel 5 (P-Pin)
	signal w_adc_5_n				: std_logic;												-- ADC Channel 5 (N-Pin)
	signal w_adc_4_p				: std_logic;												-- ADC Channel 4 (P-Pin)
	signal w_adc_4_n				: std_logic;												-- ADC Channel 4 (N-Pin)
	

	signal r_hwa_read_00			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Read 00
	signal r_hwa_read_01			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Read 01
	signal r_hwa_read_02			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Read 02
	signal r_hwa_read_03			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Read 03
	signal r_hwa_read_04			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Read 04
	signal r_hwa_read_05			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Read 05
	signal r_hwa_read_06			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Read 06
	signal r_hwa_read_07			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Read 07

	signal r_hwa_write_00			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Write 00
	signal r_hwa_write_01			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Write 01
	signal r_hwa_write_02			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Write 02
	signal r_hwa_write_03			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Write 03
	signal r_hwa_write_04			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Write 04
	signal r_hwa_write_05			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Write 05
	signal r_hwa_write_06			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Write 06
	signal r_hwa_write_07			: std_logic_vector(31 downto 0);							-- Hardware Accelerator Write 07

	signal r_hwa_id					: std_logic_vector(7 downto 0);								-- Hardware Accelerator Identification (ID)
	signal r_hwa_ctrl				: std_logic_vector(7 downto 0);								-- Hardware Accelerator Control (CTRL)
	signal r_hwa_stat				: std_logic_vector(15 downto 0);							-- Hardware Accelerator Status (STAT)


	signal w_mem_clk_00				: std_logic;												--! Memory Serial Clock 00
	signal w_mem_00_cs				: std_logic;												--! Memory Chip Select 00
	signal r_mem_00_d				: std_logic_vector(3 downto 0);								--! Memory Serial I/O 00
	
	signal w_mem_clk_01				: std_logic;												--! Memory Serial Clock 01
	signal w_mem_01_cs				: std_logic;												--! Memory Chip Select 01
	signal r_mem_01_d				: std_logic_vector(3 downto 0);								--! Memory Serial I/O 01
	
	signal w_mem_clk_02				: std_logic;												--! Memory Serial Clock 02
	signal w_mem_02_cs				: std_logic;												--! Memory Chip Select 02
	signal r_mem_02_d				: std_logic_vector(3 downto 0);								--! Memory Serial I/O 02
	
	signal w_mem_clk_03				: std_logic;												--! Memory Serial Clock 03
	signal w_mem_03_cs				: std_logic;												--! Memory Chip Select 03
	signal r_mem_03_d				: std_logic_vector(3 downto 0);								--! Memory Serial I/O 03


	signal r_adc_data_read			: std_logic_vector(15 downto 0);							--! ADC Data Read
	signal r_adc_channel			: std_logic_vector(4 downto 0);								--! ADC Channel
	signal r_adc_addr				: std_logic_vector(6 downto 0);								--! ADC Address

	signal r_icap_o					: std_logic_vector(31 downto 0);							--! ICAP 
	signal r_icap_i					: std_logic_vector(31 downto 0);							--! ICAP 

	signal w_icap_csib				: std_logic;												--! ICAP 
	signal w_icap_rdwrb				: std_logic;												--! ICAP 
	signal w_icap_clk				: std_logic;												--! ICAP 
	signal w_icap_request			: std_logic;												--! ICAP 
	signal w_icap_grant				: std_logic;												--! ICAP 
	
	signal r_fecc_flags				: std_logic_vector(3 downto 0);								--! FECC Flags

	signal w_fecc_crcerr			: std_logic;												--! FECC
	signal w_fecc_eccerr			: std_logic;												--! FECC
	signal w_fecc_eccerrsingle		: std_logic;												--! FECC
	signal w_fecc_syndromevalid		: std_logic;												--! FECC
	signal r_fecc_syndrome			: std_logic_vector(12 downto 0);							--! FECC
	signal r_fecc_far				: std_logic_vector(25 downto 0);							--! FECC
	signal r_fecc_synbit			: std_logic_vector(4 downto 0);								--! FECC
	signal r_fecc_synword			: std_logic_vector(6 downto 0);								--! FECC

	signal r_hwaio_in				: std_logic_vector(31 downto 0);							-- Hardware Accelerator I/O (Input)
	signal r_hwaio_out				: std_logic_vector(31 downto 0);							-- Hardware Accelerator I/O (Output)
	signal r_hwaio_dir				: std_logic_vector(31 downto 0);							-- Hardware Accelerator I/O (Direction)

	signal r_port_A_in				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank A (Input)
	signal r_port_A_out				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank A (Output)
	signal r_port_A_dir				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank A (Direction)
	signal r_port_A_sel				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank A (Select) 

	signal r_port_B_in				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank B (Input)
	signal r_port_B_out				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank B (Output)
	signal r_port_B_dir				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank B (Direction)
	signal r_port_B_sel				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank B (Select) 

	signal r_port_C_in				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank C (Input)
	signal r_port_C_out				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank C (Output)
	signal r_port_C_dir				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank C (Direction)
	signal r_port_C_sel				: std_logic_vector(31 downto 0);							-- PC104 I/O Bank C (Select) 

	signal w_pr_decouple			: std_logic;												-- PR Decouple Signal

	signal r_port_A_dir_n			: std_logic_vector(31 downto 0);							-- PC104 I/O Bank A (Inverted)
	signal r_port_B_dir_n			: std_logic_vector(31 downto 0);							-- PC104 I/O Bank B (Inverted)
	signal r_port_C_dir_n			: std_logic_vector(31 downto 0);							-- PC104 I/O Bank C (Inverted)


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the RadPC core
	RADPC_01 : radpc_core
	generic map(
		g_CLK_RATE                	=> c_CLK_RATE
	)
	port map(
		i_clk						=> w_clk_00,
		i_reset_n					=> i_reset_n,
		
		i_bootload_en               => c_ENABLE_BOOTLOAD,
		o_radpc_active				=> w_radpc_active,
		o_illegal_opcode			=> w_illegal_opcode,
		o_runtime_stat              => r_runtime_stat,
		o_pc                        => r_pc,
		o_instr                     => r_instr,

		o_monitor_stat				=> r_monitor_status,
		o_arbiter_stat				=> r_arbiter_status,
		o_imem_scrub_stat			=> r_imem_scrub_status,
		o_dmem_scrub_stat			=> r_dmem_scrub_status,

		i_sem_status                => r_sem_status,

		o_port_A_sel				=> r_port_A_sel,
		o_port_B_sel				=> r_port_B_sel,
		o_port_C_sel				=> r_port_C_sel,

		i_gpio_00_in				=> r_gpio_00_in,
		o_gpio_00_out				=> r_gpio_00_out,
        o_gpio_00_dir               => r_gpio_00_dir,
	
		i_gpio_01_in				=> r_gpio_01_in,
		o_gpio_01_out				=> r_gpio_01_out,
        o_gpio_01_dir               => r_gpio_01_dir,

		i_gpio_02_in				=> r_gpio_02_in,
		o_gpio_02_out				=> r_gpio_02_out,
        o_gpio_02_dir               => r_gpio_02_dir,

        i_uart_00_rx				=> w_uart_00_rx,
        o_uart_00_tx				=> w_uart_00_tx,
        o_uart_00_en               	=> w_uart_00_en,

        i_uart_01_rx				=> w_uart_01_rx,
        o_uart_01_tx				=> w_uart_01_tx,
        o_uart_01_en               	=> w_uart_01_en,

        i_uart_02_rx				=> w_uart_02_rx,
        o_uart_02_tx				=> w_uart_02_tx,
        o_uart_02_en               	=> w_uart_02_en,

        i_uart_03_rx				=> w_uart_03_rx,
        o_uart_03_tx				=> w_uart_03_tx,
        o_uart_03_en               	=> w_uart_03_en,

		i_miso_boot					=> w_miso_i_boot,
		o_miso_boot					=> w_miso_o_boot,
		i_mosi_boot					=> w_mosi_i_boot,
		o_mosi_boot					=> w_mosi_o_boot,
		i_sclk_boot					=> w_sclk_i_boot,
		o_sclk_boot					=> w_sclk_o_boot,
		i_cs_boot 					=> w_cs_i_boot,
		o_cs_boot 					=> w_cs_o_boot,
		o_boot_mode					=> w_boot_mode,

        i_miso_00					=> w_miso_i_00,
        o_miso_00					=> w_miso_o_00,
        i_mosi_00					=> w_mosi_i_00,
        o_mosi_00					=> w_mosi_o_00,
        i_sclk_00					=> w_sclk_i_00,
        o_sclk_00					=> w_sclk_o_00,
        i_cs_00						=> w_cs_i_00,
        o_cs_00						=> w_cs_o_00,
		o_spi_mode_00				=> w_spi_mode_00,

        i_miso_01					=> w_miso_i_01,
        o_miso_01					=> w_miso_o_01,
        i_mosi_01					=> w_mosi_i_01,
        o_mosi_01					=> w_mosi_o_01,
        i_sclk_01					=> w_sclk_i_01,
        o_sclk_01					=> w_sclk_o_01,
        i_cs_01						=> w_cs_i_01,
        o_cs_01						=> w_cs_o_01,
		o_spi_mode_01				=> w_spi_mode_01,

        i_miso_02					=> w_miso_i_02,
        o_miso_02					=> w_miso_o_02,
        i_mosi_02					=> w_mosi_i_02,
        o_mosi_02					=> w_mosi_o_02,
        i_sclk_02					=> w_sclk_i_02,
        o_sclk_02					=> w_sclk_o_02,
        i_cs_02						=> w_cs_i_02,
        o_cs_02						=> w_cs_o_02,
		o_spi_mode_02				=> w_spi_mode_02,

        i_miso_03					=> w_miso_i_03,
        o_miso_03					=> w_miso_o_03,
        i_mosi_03					=> w_mosi_i_03,
        o_mosi_03					=> w_mosi_o_03,
        i_sclk_03					=> w_sclk_i_03,
        o_sclk_03					=> w_sclk_o_03,
        i_cs_03						=> w_cs_i_03,
        o_cs_03						=> w_cs_o_03,
		o_spi_mode_03				=> w_spi_mode_03,

		i_miso_flash				=> i_mem_00_d1,
		o_mosi_flash				=> o_mem_00_d0,
		o_sclk_flash				=> o_mem_00_sclk,
		o_cs_flash 					=> o_mem_00_cs,

        i_scl_00					=> w_scl_i_00,
		i_sda_00					=> w_sda_i_00,
		o_scl_00					=> w_scl_o_00,
		o_sda_00					=> w_sda_o_00,
		o_i2c_mode_00				=> w_i2c_mode_00,

		i_scl_01					=> w_scl_i_01,
		i_sda_01					=> w_sda_i_01,
		o_scl_01					=> w_scl_o_01,
		o_sda_01					=> w_sda_o_01,
		o_i2c_mode_01				=> w_i2c_mode_01,

		i_adc_data_read				=> r_adc_data_read,
		i_adc_channel				=> r_adc_channel,
		o_adc_addr					=> r_adc_addr,

		i_hwa_id					=> r_hwa_id,

		i_hwa_read_00				=> r_hwa_read_00,
		i_hwa_read_01				=> r_hwa_read_01,
		i_hwa_read_02				=> r_hwa_read_02,
		i_hwa_read_03				=> r_hwa_read_03,
		i_hwa_read_04				=> r_hwa_read_04,
		i_hwa_read_05				=> r_hwa_read_05,
		i_hwa_read_06				=> r_hwa_read_06,
		i_hwa_read_07				=> r_hwa_read_07,

		o_hwa_write_00				=> r_hwa_write_00,
		o_hwa_write_01				=> r_hwa_write_01,
		o_hwa_write_02				=> r_hwa_write_02,
		o_hwa_write_03				=> r_hwa_write_03,
		o_hwa_write_04				=> r_hwa_write_04,
		o_hwa_write_05				=> r_hwa_write_05,
		o_hwa_write_06				=> r_hwa_write_06,
		o_hwa_write_07				=> r_hwa_write_07,

		o_hwa_ctrl					=> r_hwa_ctrl,
		i_hwa_stat					=> r_hwa_stat,

		o_pr_decouple				=> w_pr_decouple
	);


    ------------------------------------------------------------------------------------------------------------------------------------
	--	XILINX IP COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the clock divider
	CLK_00 : clk_wiz_0
	port map(
		i_clk						=> i_clk,
		resetn						=> i_reset_n,

		o_clk_00					=> w_clk_00
	);


	-- Instantiate the Xilinx Soft Error Mitigation (SEM) IP
	SEM_00 : sem_controller
	port map(
		i_clk                     	=> w_clk_00,
		
		i_inject_strobe             => '0',
		i_inject_command            => (others => '0'),
		
		o_sem_status                => r_sem_status,
		
		i_icap_to_sem               => r_icap_o,
		o_sem_to_icap               => r_icap_i,
		o_icap_csib                 => w_icap_csib,
		o_icap_rdwrb                => w_icap_rdwrb,
		i_icap_grant                => w_icap_grant,
		
		i_fecc_crcerr               => w_fecc_crcerr,
		i_fecc_eccerr               => w_fecc_eccerr,
		i_fecc_eccerrsingle         => w_fecc_eccerrsingle, 
		i_fecc_syndromevalid        => w_fecc_syndromevalid,
		i_fecc_syndrome             => r_fecc_syndrome, 
		i_fecc_far                  => r_fecc_far,
		i_fecc_synbit               => r_fecc_synbit,
		i_fecc_synword              => r_fecc_synword,
		
		i_monitor_rx                => w_uart_sem_rx,
		o_monitor_tx                => w_uart_sem_tx
	);


	-- Grant ICAP control to the SEM 
	-- This will need to be arbitrated for Partial Reconfiguration 
	w_icap_grant <= '1';


	-- Instantiate the FRAME_ECC Primitive
	-- Note that this component is a Xilinx primitive and does not need to be declared before instantiation
    FRAME_ECC_0 : FRAME_ECCE2
    generic map (
        FRAME_RBT_IN_FILENAME     	=> "NONE",
        FARSRC                    	=> "EFAR"
    )
    port map (
        CRCERROR                   	=> w_fecc_crcerr,
        ECCERROR                   	=> w_fecc_eccerr,
        ECCERRORSINGLE             	=> w_fecc_eccerrsingle,
        SYNWORD                    	=> r_fecc_synword,
        FAR                        	=> r_fecc_far,
        SYNBIT                     	=> r_fecc_synbit,
        SYNDROME                   	=> r_fecc_syndrome,
        SYNDROMEVALID              	=> w_fecc_syndromevalid
    );
    
	-- Assign FECC Flags to single signal for RadPC interfacing
	r_fecc_flags	<= w_fecc_crcerr & w_fecc_eccerr & w_fecc_eccerrsingle & w_fecc_syndromevalid;

    
    -- Instantiate the ICAP primitive
	-- Note that this component is a Xilinx primitive and does not need to be declared before instantiation
    ICAP_0 : ICAPE2
    generic map (
        SIM_CFG_FILE_NAME        	=> "NONE",
        DEVICE_ID                	=> x"3651093",
        ICAP_WIDTH               	=> "X32"
    )
    port map (
        CLK                         => w_clk_00,
        CSIB                        => w_icap_csib,
        RDWRB                       => w_icap_rdwrb,
        I                           => r_icap_i,
        O                           => r_icap_o
    );


	------------------------------------------------------------------------------------------------------------------------------------
	--	HARDWARE ACCELERATORS (HWA)
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate the Hardware Accelerator if enabled
	GENERATE_HWA : if( c_ENABLE_HWA = '1' ) generate

		-- Instantiate the Hardware Accelerator Wrapper
		-- This can be substituted for whatever Hardware Acclerator design is required for the current design
		HW_ACCEL_01 : hwa_core
		port map(
			i_clk						=> w_clk_00,
			i_reset_n					=> i_reset_n,

			i_pr_decouple				=> w_pr_decouple,

			o_hwa_id					=> r_hwa_id,

			i_data_A					=> r_hwa_write_00,
			i_data_B					=> r_hwa_write_01,
			i_data_C					=> r_hwa_write_02,
			i_data_D					=> r_hwa_write_03,
			i_data_E					=> r_hwa_write_04,
			i_data_F					=> r_hwa_write_05,
			i_data_G					=> r_hwa_write_06,
			i_data_H					=> r_hwa_write_07,

			o_data_A					=> r_hwa_read_00,
			o_data_B					=> r_hwa_read_01,
			o_data_C					=> r_hwa_read_02,
			o_data_D					=> r_hwa_read_03,
			o_data_E					=> r_hwa_read_04,
			o_data_F					=> r_hwa_read_05,
			o_data_G					=> r_hwa_read_06,
			o_data_H					=> r_hwa_read_07,

			i_hwaio_in                  => r_hwaio_in,
			o_hwaio_out                 => r_hwaio_out,
			o_hwaio_dir                 => r_hwaio_dir,

			i_hwa_ctrl					=> r_hwa_ctrl,
			o_hwa_stat					=> r_hwa_stat
		);

	end generate;


	-- Tie off HWA signals if disabled
	IGNORE_HWA : if ( c_ENABLE_HWA = '0' ) generate

		r_hwa_id 		<= (others => '0');

		r_hwa_read_00	<= (others => '0');
		r_hwa_read_01	<= (others => '0');
		r_hwa_read_02	<= (others => '0');
		r_hwa_read_03	<= (others => '0');
		r_hwa_read_04	<= (others => '0');
		r_hwa_read_05	<= (others => '0');
		r_hwa_read_06	<= (others => '0');
		r_hwa_read_07	<= (others => '0');

		r_hwaio_out		<= (others => '0');
		r_hwaio_dir		<= (others => '0');

		r_hwa_stat		<= (others => '0');

	end generate;


    ------------------------------------------------------------------------------------------------------------------------------------
	--	PC104 I/O PINS - PORT A
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate tri-state buffer for all input/output bits in the Port A pins peripheral
	PORT_A_TRI_STATE : for i in 31 downto 0 generate

		-- Instantiate a tri-state buffer for each Port A pin using a Xilinx primitive
		IOBUF_LSP34_PORT_A : IOBUF
		port map (
			O 	=> r_port_A_in(i),
			I 	=> r_port_A_out(i),
			IO 	=> io_port_A(i),
			T 	=> r_port_A_dir_n(i) --not r_port_A_dir(i)
		);

		-- Invert the port A Direction Pin
		r_port_A_dir_n(i)	<= not r_port_A_dir(i);


		-- Multiplex Port A Inputs
		r_hwaio_in(i) 	<= 	r_port_A_in(i)		when( r_port_A_sel(i) = '1' ) 	else
							'0';

		r_gpio_00_in(i)	<= 	r_port_A_in(i)		when( r_port_A_sel(i) = '0' ) 	else
							'0';


		-- Multiplex Port A Outputs
		r_port_A_out(i)	<= 	r_hwaio_out(i) 		when( r_port_A_sel(i) = '1' ) 	else
							r_gpio_00_out(i);


		-- Multiplex Port A Direction Controls
		r_port_A_dir(i)	<= 	r_hwaio_dir(i) 		when( r_port_A_sel(i) = '1' ) 	else
							r_gpio_00_dir(i);


	end generate;


    ------------------------------------------------------------------------------------------------------------------------------------
	--	PC104 I/O PINS - PORT B
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate tri-state buffer for all input/output bits in the Port B pins
	PORT_B_TRI_STATE : for i in 31 downto 0 generate

		-- Instantiate tri-state buffers for all Port B pins [0:23]
		TRI_STATE_BUFF_GEN : if( i < 24 ) generate

			-- Instantiate a tri-state buffer for each Port B pin using a Xilinx primitive
			IOBUF_LSP35_PORT_B : IOBUF
			port map (
				O 	=> r_port_B_in(i),
				I 	=> r_port_B_out(i),
				IO 	=> io_port_B(i),
				T 	=> r_port_B_dir_n(i) --not r_port_B_dir(i)
			);

		end generate;

		-- Invert the port A Direction Pin
		r_port_B_dir_n(i)	<= not r_port_B_dir(i);


		-- Connect ADC inputs to Port B pins [24:31]
		-- These pins are reserved and left floating temporarily
		w_adc_4_p 	<= io_port_B(29);
		w_adc_4_n 	<= io_port_B(30);
		w_adc_5_p 	<= io_port_B(25);
		w_adc_5_n 	<= io_port_B(27);
		w_adc_12_p 	<= io_port_B(28);
		w_adc_12_n 	<= io_port_B(31);
		w_adc_13_p 	<= io_port_B(26);
		w_adc_13_n 	<= io_port_B(24);


		-- Set the Port Select function for SPI 03 MOSI and GPIO_01
		SPI_03_MOSI : if( i = 23 ) generate

			-- Multiplex Port B Inputs
			w_mosi_i_03 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_mosi_o_03 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_03	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 03 MISO and GPIO_01
		SPI_03_MISO : if( i = 22 ) generate

			-- Multiplex Port B Inputs
			w_miso_i_03 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_miso_o_03 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	w_spi_mode_03		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 03 SCLK and GPIO_01
		SPI_03_SCLK : if( i = 21 ) generate

			-- Multiplex Port B Inputs
			w_sclk_i_03		<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_sclk_o_03 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_03	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 03 CS and GPIO_01
		SPI_03_CS : if( i = 20 ) generate

			-- Multiplex Port B Inputs
			w_cs_i_03 		<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_cs_o_03 			when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_03	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;


		-- Set the Port Select function for SPI 02 MISO and GPIO_01
		SPI_02_MISO : if( i = 19 ) generate

			-- Multiplex Port B Inputs
			w_miso_i_02 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_miso_o_02 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	w_spi_mode_02		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;


		-- Set the Port Select function for SPI 02 MOSI and GPIO_01
		SPI_02_MOSI : if( i = 18 ) generate

			-- Multiplex Port B Inputs
			w_mosi_i_02 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_mosi_o_02 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_02	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 02 SCLK and GPIO_01
		SPI_02_SCLK : if( i = 17 ) generate

			-- Multiplex Port B Inputs
			w_sclk_i_02 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_sclk_o_02 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_02	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 02 CS and GPIO_01
		SPI_02_CS : if( i = 16 ) generate

			-- Multiplex Port B Inputs
			w_cs_i_02 		<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_cs_o_02 			when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_02	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;


		-- Set the Port Select Function for UART 03/GPIO 01
		UART_03_TX : if( i = 15 ) generate

			-- Multiplex Port B Inputs
			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_uart_03_tx		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	w_uart_03_en 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i);

		end generate;

		-- Set the Port Select Function for UART 03/GPIO 01
		UART_03_RX : if( i = 14 ) generate

			-- Multiplex Port B Inputs
			w_uart_03_rx 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	'0' 				when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_uart_03_en	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select Function for UART 02/GPIO 01
		UART_02_TX : if( i = 13 ) generate

			-- Multiplex Port B Inputs
			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_uart_02_tx		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	w_uart_02_en 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i);

		end generate;

		-- Set the Port Select Function for UART 02/GPIO 01
		UART_02_RX : if( i = 12 ) generate

			-- Multiplex Port B Inputs
			w_uart_02_rx 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	'0' 				when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_uart_02_en	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;


		-- Set the Port Select function for SPI 01 MISO and GPIO_01
		SPI_01_MISO : if( i = 11 ) generate

			-- Multiplex Port B Inputs
			w_miso_i_01 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_miso_o_01 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	w_spi_mode_01		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 01 MOSI and GPIO_01
		SPI_01_MOSI : if( i = 10 ) generate

			-- Multiplex Port B Inputs
			w_mosi_i_01 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_mosi_o_01 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_01	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 01 SCLK and GPIO_01
		SPI_01_SCLK : if( i = 9 ) generate

			-- Multiplex Port B Inputs
			w_sclk_i_01 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_sclk_o_01 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_01	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 01 CS and GPIO_01
		SPI_01_CS : if( i = 8 ) generate

			-- Multiplex Port B Inputs
			w_cs_i_01 		<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_cs_o_01 			when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_01	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 00 MISO and GPIO_01
		SPI_00_MISO : if( i = 7 ) generate

			-- Multiplex Port B Inputs
			w_miso_i_00 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_miso_o_00 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	w_spi_mode_00		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;


		-- Set the Port Select function for SPI 00 MOSI and GPIO_01
		SPI_00_MOSI : if( i = 6 ) generate

			-- Multiplex Port B Inputs
			w_mosi_i_00 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_mosi_o_00 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_00	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 00 SCLK and GPIO_01
		SPI_00_SCLK : if( i = 5 ) generate

			-- Multiplex Port B Inputs
			w_sclk_i_00 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_sclk_o_00 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_00	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select function for SPI 00 CS and GPIO_01
		SPI_00_CS : if( i = 4 ) generate

			-- Multiplex Port B Inputs
			w_cs_i_00 		<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_cs_o_00 			when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_spi_mode_00	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select Function for UART 01/GPIO 01
		UART_01_TX : if( i = 3 ) generate

			-- Multiplex Port B Inputs
			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_uart_01_tx		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	w_uart_01_en 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i);

		end generate;

		-- Set the Port Select Function for UART 01/GPIO 01
		UART_01_RX : if( i = 2 ) generate

			-- Multiplex Port B Inputs
			w_uart_01_rx 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	'0' 				when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_uart_01_en	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

		-- Set the Port Select Function for UART 00/GPIO 01
		UART_00_TX : if( i = 1 ) generate

			-- Multiplex Port B Inputs
			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	w_uart_00_tx		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	w_uart_00_en 		when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i);

		end generate;

		-- Set the Port Select Function for UART 00/GPIO 01
		UART_00_RX : if( i = 0 ) generate

			-- Multiplex Port B Inputs
			w_uart_00_rx 	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '1' ) 	else
								'0';

			r_gpio_01_in(i)	<= 	r_port_B_in(i)		when( r_port_B_sel(i) = '0' ) 	else
								'0';

			-- Multiplex Port B Outputs
			r_port_B_out(i)	<= 	'0' 				when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_out(i);

			-- Multiplex Port B Direction Controls
			r_port_B_dir(i)	<= 	not w_uart_00_en	when( r_port_B_sel(i) = '1' ) 	else
								r_gpio_01_dir(i) ;

		end generate;

	end generate;


    ------------------------------------------------------------------------------------------------------------------------------------
	--	PC104 I/O PINS - PORT C
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate a tri-state buffer for the Port C GPIO [0] pin using a Xilinx primitive
	IOBUF_LSP35_PORT_C_0 : IOBUF
	port map (
		O 	=> r_port_C_in(0),
		I 	=> r_port_C_out(0),
		IO 	=> io_port_C(0),
		T 	=> r_port_C_dir_n(0) --not r_port_C_dir(0)
	);


	-- Instantiate a tri-state buffer for the Port C GPIO [5] pin using a Xilinx primitive
	IOBUF_LSP35_PORT_C_5 : IOBUF
	port map (
		O 	=> r_port_C_in(5),
		I 	=> r_port_C_out(5),
		IO 	=> io_port_C(5),
		T 	=> r_port_C_dir_n(5) --not r_port_C_dir(5)
	);

	-- Invert Port C Direction
	r_port_C_dir_n(5)	<= not r_port_C_dir(5);
	r_port_C_dir_n(0)	<= not r_port_C_dir(0);


	-- Multiplex Port C [0] Inputs
	r_gpio_02_in(0)	<= 	r_port_C_in(0)		when( r_port_C_sel(0) = '0' ) 	else
						'0';

	-- Multiplex Port C Outputs
	r_port_C_out(0)	<= 	'0' 				when( r_port_C_sel(0) = '1' ) 	else
						r_gpio_02_out(0);

	-- Multiplex Port C Direction Controls
	r_port_C_dir(0)	<= 	'0' 				when( r_port_C_sel(0) = '1' ) 	else
						r_gpio_02_dir(0);


	-- Multiplex Port C [5] Inputs
	r_gpio_02_in(5)	<= 	r_port_C_in(5)		when( r_port_C_sel(5) = '0' ) 	else
						'0';

	-- Multiplex Port C Outputs
	r_port_C_out(5)	<= 	'0' 				when( r_port_C_sel(5) = '1' ) 	else
						r_gpio_02_out(5);

	-- Multiplex Port C Direction Controls
	r_port_C_dir(5)	<= 	'0' 				when( r_port_C_sel(5) = '1' ) 	else
						r_gpio_02_dir(5);


	-- Set up I2C 00 ports to be high impedance when disabled; route to PC104 otherwise
	io_port_C(3)	<= 	'0' when w_i2c_mode_00(0) = '0' and w_scl_o_00 = '0' else
						'Z';

	io_port_C(4)	<=	'0' when w_i2c_mode_00(1) = '0' and w_sda_o_00 = '0' else
						'Z';

	w_scl_i_00		<= 	io_port_C(3);
	w_sda_i_00		<= 	io_port_C(4);


	-- Set up I2C 01 ports to be high impedance when disabled; route to PC104 otherwise
	io_port_C(1)	<= 	'0' when w_i2c_mode_01(0) = '0' and w_scl_o_01 = '0' else
						'Z';

	io_port_C(2)	<=	'0' when w_i2c_mode_01(1) = '0' and w_sda_o_01 = '0' else
						'Z';

	w_scl_i_01		<= 	io_port_C(1);
	w_sda_i_01		<= 	io_port_C(2);


    ------------------------------------------------------------------------------------------------------------------------------------
	--	SERIAL PERIPHERAL INTERFACE (SPI) PERIPHERAL - BOOTLOADING
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate a tri-state buffer for the BOOT SPI MISO pin using a Xilinx primitive
	IOBUF_BOOT_SPI_MISO : IOBUF
	port map (
		O 	=> w_miso_i_boot,
		I 	=> w_miso_o_boot,
		IO 	=> io_msp430_spi(2),
		T 	=> not w_boot_mode
	);


	-- Instantiate a tri-state buffer for the BOOT SPI MOSI pin using a Xilinx primitive
	IOBUF_BOOT_SPI_MOSI : IOBUF
	port map (
		O 	=> w_mosi_i_boot,
		I 	=> w_mosi_o_boot,
		IO 	=> io_msp430_spi(0),
		T 	=> w_boot_mode
	);


	-- Instantiate a tri-state buffer for the BOOT SPI SCLK pin using a Xilinx primitive
	IOBUF_BOOT_SPI_SCLK: IOBUF
	port map (
		O 	=> w_sclk_i_boot,
		I 	=> w_sclk_o_boot,
		IO 	=> io_msp430_spi(3),
		T 	=> w_boot_mode
	);


	-- Instantiate a tri-state buffer for the BOOT SPI CS pin using a Xilinx primitive
	IOBUF_BOOT_SPI_CS: IOBUF
	port map (
		O 	=> w_cs_i_boot,
		I 	=> w_cs_o_boot,
		IO 	=> io_msp430_spi(1),
		T 	=> w_boot_mode
	);


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------