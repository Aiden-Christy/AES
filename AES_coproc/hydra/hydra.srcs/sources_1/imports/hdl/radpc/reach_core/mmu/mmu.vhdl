----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	REACH PROCESSOR CORE
--  MEMORY MANAGEMENT UNIT (MMU)
--
--	Created by Chris Major
--	Resilient Computing
-- 	12/2/2022
--
--!	@file
--!	@brief A component for mapping memory devices and peripherals by specifying address ranges and managing read/write access.
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
-- LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	-- IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;

	-- IEEE Numeric Standard Library
	use IEEE.NUMERIC_STD.ALL;


	-- RadPC Reach Core Package
	use WORK.REACH_CORE_PKG.all;


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity mmu is
generic (
	g_CLK_RATE                	: integer           := 100_000_000;							-- RadPC Expected Clock rate
    g_OBFUSCATION_OFFSET        : integer           := 0;									-- Obfuscation Offset Constant
	g_CORRUPTION				: integer			:= 0									-- Memory Corruption Value
);
port(
	i_clk						: in	std_logic;			                                -- Input Clock
	i_reset_n					: in	std_logic;			                                -- Active Low Reset
	
	i_pc						: in 	std_logic_vector(31 downto 0);						-- Program Counter
	i_addr						: in 	std_logic_vector(31 downto 0);						-- Address
	i_rw_en						: in	std_logic;											-- Read/Write Enable
	i_data_wr					: in 	std_logic_vector(31 downto 0);						-- Memory Input Data
	i_load_size					: in	std_logic_vector(2 downto 0);						-- Memory Size Specification

	i_imem_scrb_addr			: in 	std_logic_vector(31 downto 0);						-- IMEM Scrubber Address
	i_imem_scrb_rw_en			: in	std_logic;											-- IMEM Scrubber Read/Write Enable
	i_imem_scrb_data			: in 	std_logic_vector(31 downto 0);						-- IMEM Scrubber Memory Input Data
	o_imem_scrb_data			: out	std_logic_vector(31 downto 0);						-- IMEM Scrubber Memory Output Data

	i_dmem_scrb_addr			: in 	std_logic_vector(31 downto 0);						-- DMEM Scrubber Address
	i_dmem_scrb_rw_en			: in	std_logic;											-- DMEM Scrubber Read/Write Enable
	i_dmem_scrb_data			: in 	std_logic_vector(31 downto 0);						-- DMEM Scrubber Memory Input Data
	o_dmem_scrb_data			: out	std_logic_vector(31 downto 0);						-- DMEM Scrubber Memory Output Data

	o_instr					    : out	std_logic_vector(31 downto 0);						-- Instruction
	o_data_rd					: out	std_logic_vector(31 downto 0);						-- Memory Output Data
	o_illegal_pc				: out	std_logic;											-- Illegal Program Count Flag

	o_port_A_sel                : out   std_logic_vector(31 downto 0);                     	-- Port A Select
	o_port_B_sel                : out   std_logic_vector(31 downto 0);                     	-- Port B Select
	o_port_C_sel                : out   std_logic_vector(31 downto 0);                     	-- Port C Select

	i_gpio_00_in				: in 	std_logic_vector(31 downto 0);						-- GPIO Input Pins 00
	o_gpio_00_out				: out 	std_logic_vector(31 downto 0);						-- GPIO Output Pins 00
	o_gpio_00_dir				: out 	std_logic_vector(31 downto 0);						-- GPIO Direction 00
	o_gpio_00_irq				: out	std_logic;											-- GPIO Interrupt Request Signal 00

	i_gpio_01_in				: in 	std_logic_vector(31 downto 0);						-- GPIO Input Pins 01
	o_gpio_01_out				: out 	std_logic_vector(31 downto 0);						-- GPIO Output Pins 01
	o_gpio_01_dir				: out 	std_logic_vector(31 downto 0);						-- GPIO Direction 01
	o_gpio_01_irq				: out	std_logic;											-- GPIO Interrupt Request Signal 01

	i_gpio_02_in				: in 	std_logic_vector(31 downto 0);						-- GPIO Input Pins 02
	o_gpio_02_out				: out 	std_logic_vector(31 downto 0);						-- GPIO Output Pins 02
	o_gpio_02_dir				: out 	std_logic_vector(31 downto 0);						-- GPIO Direction 02
	o_gpio_02_irq				: out	std_logic;											-- GPIO Interrupt Request Signal 02

	i_uart_00_rx				: in	std_logic;			                                -- UART 00 RX
	o_uart_00_tx				: out	std_logic;			                                -- UART 00 TX
	o_uart_00_en                : out	std_logic;			                                -- UART 00 Enable
	o_uart_00_irq				: out	std_logic;											-- UART 00 Interrupt Request Signal

	i_uart_01_rx				: in	std_logic;			                               	-- UART 01 RX
	o_uart_01_tx				: out	std_logic;			                               	-- UART 01 TX
	o_uart_01_en                : out	std_logic;			                                -- UART 01 Enable
	o_uart_01_irq				: out	std_logic;											-- UART 01 Interrupt Request Signal

	i_uart_02_rx				: in	std_logic;			                                -- UART 02 RX
	o_uart_02_tx				: out	std_logic;			                                -- UART 02 TX
	o_uart_02_en                : out	std_logic;			                                -- UART 02 Enable
	o_uart_02_irq				: out	std_logic;											-- UART 02 Interrupt Request Signal

	i_uart_03_rx				: in	std_logic;			                               	-- UART 03 RX
	o_uart_03_tx				: out	std_logic;			                               	-- UART 03 TX
	o_uart_03_en                : out	std_logic;			                                -- UART 03 Enable
	o_uart_03_irq				: out	std_logic;											-- UART 03 Interrupt Request Signal

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
	o_spi_irq_00				: out	std_logic;											-- SPI 00 Interrupt Request Signal

	i_miso_01					: in	std_logic;											-- SPI 01 Input Master In Slave Out (MISO)
	o_miso_01					: out	std_logic;											-- SPI 01 Output Master In Slave Out (MISO)
	i_mosi_01					: in	std_logic;											-- SPI 01 Input Master Out Slave In (MOSI)
	o_mosi_01					: out	std_logic;											-- SPI 01 Output Master Out Slave In (MOSI)
	i_sclk_01					: in	std_logic;											-- SPI 01 Incoming Serial Clock (SCLK)
	o_sclk_01					: out	std_logic;											-- SPI 01 Outgoing Serial Clock (SCLK)
	i_cs_01						: in	std_logic;											-- SPI 01 Incoming Serial Data (CS)
	o_cs_01						: out	std_logic;											-- SPI 01 Outgoing Serial Data (CS)
	o_spi_mode_01				: out	std_logic;											-- SPI 01 Mode
	o_spi_irq_01				: out	std_logic;											-- SPI 01 Interrupt Request Signal

	i_miso_02					: in	std_logic;											-- SPI 02 Input Master In Slave Out (MISO)
	o_miso_02					: out	std_logic;											-- SPI 02 Output Master In Slave Out (MISO)
	i_mosi_02					: in	std_logic;											-- SPI 02 Input Master Out Slave In (MOSI)
	o_mosi_02					: out	std_logic;											-- SPI 02 Output Master Out Slave In (MOSI)
	i_sclk_02					: in	std_logic;											-- SPI 02 Incoming Serial Clock (SCLK)
	o_sclk_02					: out	std_logic;											-- SPI 02 Outgoing Serial Clock (SCLK)
	i_cs_02						: in	std_logic;											-- SPI 02 Incoming Serial Data (CS)
	o_cs_02						: out	std_logic;											-- SPI 02 Outgoing Serial Data (CS)
	o_spi_mode_02				: out	std_logic;											-- SPI 02 Mode
	o_spi_irq_02				: out	std_logic;											-- SPI 02 Interrupt Request Signal

	i_miso_03					: in	std_logic;											-- SPI 03 Input Master In Slave Out (MISO)
	o_miso_03					: out	std_logic;											-- SPI 03 Output Master In Slave Out (MISO)
	i_mosi_03					: in	std_logic;											-- SPI 03 Input Master Out Slave In (MOSI)
	o_mosi_03					: out	std_logic;											-- SPI 03 Output Master Out Slave In (MOSI)
	i_sclk_03					: in	std_logic;											-- SPI 03 Incoming Serial Clock (SCLK)
	o_sclk_03					: out	std_logic;											-- SPI 03 Outgoing Serial Clock (SCLK)
	i_cs_03						: in	std_logic;											-- SPI 03 Incoming Serial Data (CS)
	o_cs_03						: out	std_logic;											-- SPI 03 Outgoing Serial Data (CS)
	o_spi_mode_03				: out	std_logic;											-- SPI 03 Mode
	o_spi_irq_03				: out	std_logic;											-- SPI 03 Interrupt Request Signal

	i_miso_flash				: in	std_logic;											-- NOR Flash Master In Slave Out (MISO)
	o_mosi_flash				: out	std_logic;											-- NOR Flash Master Out Slave In (MOSI)
	o_sclk_flash				: out	std_logic;											-- NOR Flash Serial Clock (SCLK)
	o_cs_flash 					: out	std_logic;											-- NOR Flash Serial Data (CS)

	i_scl_00					: in	std_logic;                                  		-- I2C 00 Incoming Serial Clock Line (SCL)
	i_sda_00					: in	std_logic;                                   		-- I2C 00 Incoming Serial Data Line (SDA)
	o_scl_00					: out	std_logic;                                  		-- I2C 00 Outgoing Serial Clock Line (SCL)
	o_sda_00					: out	std_logic;                                   		-- I2C 00 Outgoing Serial Data Line (SDA)
	o_I2C_mode_00				: out	std_logic_vector(1 downto 0);						-- I2C 00 INOUT Mode Control
	o_i2c_irq_00				: out	std_logic;											-- I2C 00 Interrupt Signal

	i_scl_01					: in	std_logic;                                  		-- I2C 01 Incoming Serial Clock Line (SCL)
	i_sda_01					: in	std_logic;                                   		-- I2C 01 Incoming Serial Data Line (SDA)
	o_scl_01					: out	std_logic;                                  		-- I2C 01 Outgoing Serial Clock Line (SCL)
	o_sda_01					: out	std_logic;                                   		-- I2C 01 Outgoing Serial Data Line (SDA)
	o_I2C_mode_01				: out	std_logic_vector(1 downto 0);						-- I2C 01 INOUT Mode Control
	o_i2c_irq_01				: out	std_logic;											-- I2C 01 Interrupt Signal

	i_adc_data_read				: in	std_logic_vector(15 downto 0);						-- ADC Data Read
	i_adc_channel				: in	std_logic_vector(4 downto 0);						-- ADC Channel
	o_adc_addr					: out	std_logic_vector(6 downto 0);						-- ADC Address

	i_sem_stat					: in 	std_logic_vector(7 downto 0);						-- SEM Status Register
	i_arbiter_stat				: in 	std_logic_vector(7 downto 0);						-- Arbiter Status Register
	i_monitor_stat				: in 	std_logic_vector(7 downto 0);						-- Monitor Status Register
	i_imem_stat					: in 	std_logic_vector(7 downto 0);						-- DMEM Scrubber Status Register
	i_dmem_stat					: in 	std_logic_vector(7 downto 0);						-- DMEM Scrubber Status Register
	i_bootrom_stat				: in 	std_logic_vector(7 downto 0);						-- BOOTROM Scrubber Status Register

	o_index						: out	std_logic_vector(7 downto 0);						-- Event Index
	i_event						: in	std_logic_vector(31 downto 0);						-- Event Data (Read)

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

	o_pr_decouple				: out	std_logic;											-- Partial Reconfiguration Decoupling Enable

	o_timer_00_irq				: out	std_logic;											-- TIMER 00 Interrupt Request Signal 00
	o_timer_01_irq				: out	std_logic											-- TIMER 01 Interrupt Request Signal 00
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture mmu_arch of mmu is

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------
	
	-- Declare the Bootload Read Only Memory (BOOTROM) component
	component bootrom is
	port (
		i_clk						: in	std_logic;												-- Clock
		i_reset_n					: in	std_logic;			                                	-- Active Low Reset
		
		i_pc						: in	std_logic_vector(31 downto 0);						    -- Program Counter
		o_instr						: out	std_logic_vector(31 downto 0);							-- Current Instruction

		i_scrb_addr					: in 	std_logic_vector(31 downto 0);							-- Scrubber Address
		i_scrb_rw					: in	std_logic;												-- Scrubber Read/Write (RW))
		i_scrb_wr					: in 	std_logic_vector(31 downto 0);							-- Scrubber Memory Write (WR)
		o_scrb_rd					: out	std_logic_vector(31 downto 0)							-- Scrubber Memory Read (RD)
	);
	end component;


	-- Declare the Instruction Memory (IMEM) component
	component imem is
	generic(
		g_OBFUSCATION_OFFSET        : integer           := 0
	);
	port (
		i_clk						: in	std_logic;												-- Clock
		i_reset_n					: in	std_logic;			                                	-- Active Low Reset
		
		i_pc						: in	std_logic_vector(31 downto 0);						    -- Program Counter
		o_instr						: out	std_logic_vector(31 downto 0);							-- Current Instruction

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
		i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
		i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
		o_cpu_rd					: out	std_logic_vector(31 downto 0)							-- CPU Memory Read (RD)
	);
	end component;


	-- Declare the Data Memory (DMEM) component
	component dmem is
		generic(
			g_FLIP_BITS					: std_logic							:= '0';						-- Enable Flipped Bits
			g_FLIP_ADDR					: integer							:= 0;						-- Address To Flip
			g_FLIP_MASK					: std_logic_vector(7 downto 0)		:= x"00"					-- Bit Mask To Flip
		);
		port(
			i_clk						: in	std_logic;												-- Clock

			i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
			i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
			i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
			i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
			o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

			i_scrb_addr					: in 	std_logic_vector(31 downto 0);							-- Scrubber Address
			i_scrb_rw					: in	std_logic;												-- Scrubber Read/Write (RW))
			i_scrb_wr					: in 	std_logic_vector(31 downto 0);							-- Scrubber Memory Write (WR)
			o_scrb_rd					: out	std_logic_vector(31 downto 0)							-- Scrubber Memory Read (RD)
		);
	end component;


	-- Declare the Port Function Controller (PFC) component
	component mem_pfc is
	port(
		i_clk						: in	std_logic;												-- Clock
		i_reset_n					: in	std_logic;												-- Active Low Reset

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
		i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
		i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
		o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

		o_port_A_sel                : out   std_logic_vector(31 downto 0);                     		-- Port A Select
		o_port_B_sel                : out   std_logic_vector(31 downto 0);                     		-- Port B Select
		o_port_C_sel                : out   std_logic_vector(31 downto 0)                     		-- Port C Select
	);
	end component;


	-- Declare the General Purpose Input/Output (GPIO) component
	component mem_gpio is
	port(
		i_clk						: in	std_logic;												-- Clock
		i_reset_n					: in	std_logic;												-- Active Low Reset

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
		i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
		i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
		o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

		i_gpio_in					: in 	std_logic_vector(31 downto 0);							-- GPIO Input Pins
		o_gpio_out					: out 	std_logic_vector(31 downto 0);							-- GPIO Output Pins
		o_gpio_dir					: out 	std_logic_vector(31 downto 0);							-- GPIO Direction

		o_gpio_irq					: out	std_logic												-- GPIO Interrupt Request Signal
	);
	end component;


	-- Declare the UART component (NEW)
	component mem_uart is
	generic (
		g_CLK_RATE                  : integer           := 100_000_000                             	-- Clock Rate [MHz]
	);
	port(
		i_clk						: in	std_logic;												-- Clock
		i_reset_n					: in	std_logic;												-- Active Low Reset

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
		i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
		i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
		o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

		i_uart_rx					: in	std_logic;			                                    -- UART RX
		o_uart_tx					: out	std_logic;			                                    -- UART TX
		o_uart_en					: out	std_logic;												-- UART EN
		o_uart_irq					: out	std_logic												-- UART Interrupt Request Signal
	);
	end component;	


	-- Declare the SPI component
	component mem_spi is
	generic (
		g_CLK_RATE                  : integer           := 100_000_000                             	--! Clock Rate [MHz]
	);
	port(
		i_clk						: in	std_logic;												-- Clock
		i_reset_n					: in	std_logic;												-- Reset (Active Low)

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
		i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
		i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
		o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

		i_miso						: in	std_logic;												-- SPI Input Master In Slave Out (MISO)
		o_miso						: out	std_logic;												-- SPI Output Master In Slave Out (MISO)
		i_mosi						: in	std_logic;												-- SPI Input Master Out Slave In (MOSI)
		o_mosi						: out	std_logic;												-- SPI Output Master Out Slave In (MOSI)
		i_sclk						: in	std_logic;												-- SPI Incoming Serial Clock (SCLK)
		o_sclk						: out	std_logic;												-- SPI Outgoing Serial Clock (SCLK)
		i_cs						: in	std_logic;												-- SPI Incoming Serial Data (CS)
		o_cs						: out	std_logic;												-- SPI Outgoing Serial Data (CS)

		o_spi_mode					: out	std_logic;												-- SPI Mode

		o_spi_irq					: out	std_logic												-- SPI Interrupt Request Signal
	);
	end component;


	-- Declare the I2C component
	component mem_i2c is
	port(
		i_clk						: in	std_logic;												--! Clock
		i_reset_n					: in	std_logic;												--! Actvece Low Reset

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
		i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
		i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
		o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

		i_scl						: in	std_logic;												--! I2C Incoming Serial Clock
		i_sda						: in	std_logic;												--! I2C Incoming Serial Data
		o_scl						: out	std_logic;												--! I2C Outgoing Serial Clock
		o_sda						: out	std_logic;												--! I2C Outgoing Serial Data
		o_I2C_mode					: out	std_logic_vector(1 downto 0);							--! I2C Transceiver INOUT Signal

		o_i2c_irq					: out	std_logic												--! I2C Interrupt Request Signal
	);
	end component;


	-- Declare the ADC component
	component mem_adc is
	port(
		i_clk						: in	std_logic;												--! Clock
		i_reset_n					: in	std_logic;												--! Active Low Reset

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
		i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
		i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
		o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

		i_adc_data_read				: in	std_logic_vector(15 downto 0);							--! ADC Data Read
		i_adc_channel				: in	std_logic_vector(4 downto 0);							--! ADC Channel
		o_adc_addr					: out	std_logic_vector(6 downto 0)							--! ADC Address
	);
	end component;


	-- Declare the Hardware Accelerator Interface
	component mem_hwa is
	port(
		i_clk						: in	std_logic;
		i_reset_n					: in	std_logic;

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    
		i_cpu_dw					: in	std_logic_vector(2 downto 0);
		i_cpu_rw					: in	std_logic;
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);
		o_cpu_rd					: out	std_logic_vector(31 downto 0);

		i_hwa_id					: in	std_logic_vector(7 downto 0);

		i_hwa_read_00				: in 	std_logic_vector(31 downto 0);
		i_hwa_read_01				: in 	std_logic_vector(31 downto 0);
		i_hwa_read_02				: in 	std_logic_vector(31 downto 0);
		i_hwa_read_03				: in 	std_logic_vector(31 downto 0);
		i_hwa_read_04				: in 	std_logic_vector(31 downto 0);
		i_hwa_read_05				: in 	std_logic_vector(31 downto 0);
		i_hwa_read_06				: in 	std_logic_vector(31 downto 0);
		i_hwa_read_07				: in 	std_logic_vector(31 downto 0);

		o_hwa_write_00				: out 	std_logic_vector(31 downto 0);
		o_hwa_write_01				: out 	std_logic_vector(31 downto 0);
		o_hwa_write_02				: out 	std_logic_vector(31 downto 0);
		o_hwa_write_03				: out 	std_logic_vector(31 downto 0);
		o_hwa_write_04				: out 	std_logic_vector(31 downto 0);
		o_hwa_write_05				: out 	std_logic_vector(31 downto 0);
		o_hwa_write_06				: out 	std_logic_vector(31 downto 0);
		o_hwa_write_07				: out 	std_logic_vector(31 downto 0);

		o_hwa_ctrl					: out	std_logic_vector(7 downto 0);
		i_hwa_stat					: in	std_logic_vector(15 downto 0);

		o_pr_decouple				: out	std_logic
	);
	end component;


	-- Declare the TIMER component
	component mem_timer is
	port(
		i_clk						: in	std_logic;												--! Clock
		i_reset_n					: in	std_logic;												--! Active Low Reset

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
		i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
		i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
		o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

		o_timer_irq					: out	std_logic												--! Timer Interrupt Request Signal
	);
	end component;

	-- Declare the Fault Recovery Mechanism (FRM) component
	component mem_frm is
		port(
			i_clk						: in	std_logic;												-- Input Clock
			i_reset_n					: in	std_logic;												-- Active Low Reset

			i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
			i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
			i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
			i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
			o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

			i_sem_stat					: in 	std_logic_vector(7 downto 0);							-- SEM Status Register
			i_arbiter_stat				: in 	std_logic_vector(7 downto 0);							-- Arbiter Status Register
			i_monitor_stat				: in 	std_logic_vector(7 downto 0);							-- Monitor Status Register
			i_imem_scrubber_stat		: in 	std_logic_vector(7 downto 0);							-- IMEM Scrubber Status Register
			i_dmem_scrubber_stat		: in 	std_logic_vector(7 downto 0);							-- DMEM Scrubber Status Register
			i_bootrom_stat				: in 	std_logic_vector(7 downto 0);							-- BOOTROM Scrubber Status Register

			o_index						: out	std_logic_vector(7 downto 0);							-- Event Index
			i_event						: in	std_logic_vector(31 downto 0)							-- Event Data (Read)
		);
	end component;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_addr					: unsigned(31 downto 0)											-- Global Address (Unsigned)
									:= x"00000000";

	signal r_pc						: unsigned(31 downto 0)											-- Global Program Count (Unsigned)
									:= c_IMEM_START;					

	signal r_imem_pc				: std_logic_vector(31 downto 0);								-- IMEM Local Program Count
	signal r_bootrom_pc				: std_logic_vector(31 downto 0);								-- BOOTROM Local Program Count

	signal w_imem_pc_valid			: std_logic;													-- IMEM Program Count Valid Flag
	signal w_bootrom_pc_valid		: std_logic;													-- BOOTROM Program Count Valid Flag

	signal r_imem_instr				: std_logic_vector(31 downto 0);								-- IMEM Instruction
	signal r_bootrom_instr			: std_logic_vector(31 downto 0);								-- BOOTROM Instruction	


	signal r_imem_addr				: std_logic_vector(31 downto 0);								-- IMEM Address (Local)
	signal r_dmem_addr				: std_logic_vector(31 downto 0);								-- DMEM Address (Local)
	signal r_boot_addr				: std_logic_vector(31 downto 0);								-- BOOT Address (Local)
	signal r_pfc_addr				: std_logic_vector(31 downto 0);								-- PFC Address (Local)
	signal r_gpio_00_addr			: std_logic_vector(31 downto 0);								-- GPIO 00 Address (Local)
	signal r_gpio_01_addr			: std_logic_vector(31 downto 0);								-- GPIO 01 Address (Local)
	signal r_gpio_02_addr			: std_logic_vector(31 downto 0);								-- GPIO 02 Address (Local)
	signal r_spi_00_addr			: std_logic_vector(31 downto 0);								-- SPI 00 Address (Local)
	signal r_spi_01_addr			: std_logic_vector(31 downto 0);								-- SPI 01 Address (Local)
	signal r_spi_02_addr			: std_logic_vector(31 downto 0);								-- SPI 02 Address (Local)
	signal r_spi_03_addr			: std_logic_vector(31 downto 0);								-- SPI 03 Address (Local)
	signal r_flash_addr				: std_logic_vector(31 downto 0);								-- NOR Flash Address (Local)
	signal r_uart_00_addr			: std_logic_vector(31 downto 0);								-- UART 00 Address (Local)
	signal r_uart_01_addr			: std_logic_vector(31 downto 0);								-- UART 01 Address (Local)
	signal r_uart_02_addr			: std_logic_vector(31 downto 0);								-- UART 02 Address (Local)
	signal r_uart_03_addr			: std_logic_vector(31 downto 0);								-- UART 03 Address (Local)
	signal r_i2c_00_addr			: std_logic_vector(31 downto 0);								-- I2C 00 Address (Local)
	signal r_i2c_01_addr			: std_logic_vector(31 downto 0);								-- I2C 01 Address (Local)
	signal r_adc_addr				: std_logic_vector(31 downto 0);								-- ADC Address (Local)
	signal r_timer_00_addr			: std_logic_vector(31 downto 0);								-- TIMER 00 Address (Local)
	signal r_timer_01_addr			: std_logic_vector(31 downto 0);								-- TIMER 01 Address (Local)
	signal r_hwa_addr				: std_logic_vector(31 downto 0);								-- HWA Address (Local)
	signal r_frm_addr				: std_logic_vector(31 downto 0);								-- FRM Address (Local)

	signal r_imem_rd				: std_logic_vector(31 downto 0);								-- IMEM Read Data
	signal r_dmem_rd				: std_logic_vector(31 downto 0);								-- DMEM Read Data
	signal r_boot_rd				: std_logic_vector(31 downto 0);								-- BOOT Read Data
	signal r_pfc_rd					: std_logic_vector(31 downto 0);								-- PFC Read Data
	signal r_gpio_00_rd				: std_logic_vector(31 downto 0);								-- GPIO 00 Read Data
	signal r_gpio_01_rd				: std_logic_vector(31 downto 0);								-- GPIO 01 Read Data
	signal r_gpio_02_rd				: std_logic_vector(31 downto 0);								-- GPIO 02 Read Data
	signal r_spi_00_rd				: std_logic_vector(31 downto 0);								-- SPI 00 Read Data
	signal r_spi_01_rd				: std_logic_vector(31 downto 0);								-- SPI 01 Read Data
	signal r_spi_02_rd				: std_logic_vector(31 downto 0);								-- SPI 02 Read Data
	signal r_spi_03_rd				: std_logic_vector(31 downto 0);								-- SPI 03 Read Data
	signal r_flash_rd				: std_logic_vector(31 downto 0);								-- NOR Flash Read Data
	signal r_uart_00_rd				: std_logic_vector(31 downto 0);								-- UART 00 Read Data
	signal r_uart_01_rd				: std_logic_vector(31 downto 0);								-- UART 01 Read Data
	signal r_uart_02_rd				: std_logic_vector(31 downto 0);								-- UART 02 Read Data
	signal r_uart_03_rd				: std_logic_vector(31 downto 0);								-- UART 03 Read Data
	signal r_i2c_00_rd				: std_logic_vector(31 downto 0);								-- I2C 00 Read Data
	signal r_i2c_01_rd				: std_logic_vector(31 downto 0);								-- I2C 01 Read Data
	signal r_adc_rd					: std_logic_vector(31 downto 0);								-- ADC Read Data
	signal r_timer_00_rd			: std_logic_vector(31 downto 0);								-- TIMER 00 Read Data
	signal r_timer_01_rd			: std_logic_vector(31 downto 0);								-- TIMER 01 Read Data
	signal r_hwa_rd					: std_logic_vector(31 downto 0);								-- HWA Read Data
	signal r_frm_rd					: std_logic_vector(31 downto 0);								-- FRM Read Data


	signal w_imem_rw				: std_logic;													-- IMEM Read/Write (RW)
	signal w_dmem_rw				: std_logic;													-- DMEM Read/Write (RW)
	signal w_boot_rw				: std_logic;													-- BOOT Read/Write (RW)
	signal w_pfc_rw					: std_logic;													-- PFC Read/Write (RW)
	signal w_gpio_00_rw				: std_logic;													-- GPIO 00 Read/Write (RW)
	signal w_gpio_01_rw				: std_logic;													-- GPIO 01 Read/Write (RW)
	signal w_gpio_02_rw				: std_logic;													-- GPIO 02 Read/Write (RW)
	signal w_spi_00_rw				: std_logic;													-- SPI 00 Read/Write (RW)
	signal w_spi_01_rw				: std_logic;													-- SPI 01 Read/Write (RW)
	signal w_spi_02_rw				: std_logic;													-- SPI 02 Read/Write (RW)
	signal w_spi_03_rw				: std_logic;													-- SPI 03 Read/Write (RW)
	signal w_flash_rw				: std_logic;													-- NOR Flash Read/Write (RW)
	signal w_uart_00_rw				: std_logic;													-- UART 00 Read/Write (RW)
	signal w_uart_01_rw				: std_logic;													-- UART 01 Read/Write (RW)
	signal w_uart_02_rw				: std_logic;													-- UART 02 Read/Write (RW)
	signal w_uart_03_rw				: std_logic;													-- UART 03 Read/Write (RW)
	signal w_i2c_00_rw				: std_logic;													-- I2C 00 Read/Write (RW)
	signal w_i2c_01_rw				: std_logic;													-- I2C 01 Read/Write (RW)
	signal w_adc_rw					: std_logic;													-- ADC Read/Write (RW)
	signal w_timer_00_rw			: std_logic;													-- TIMER 00 Read/Write (RW)
	signal w_timer_01_rw			: std_logic;													-- TIMER 01 Read/Write (RW)
	signal w_hwa_rw					: std_logic;													-- HWA Read/Write (RW)
	signal w_frm_rw					: std_logic;													-- FRM Read/Write (RW)

	signal w_imem_addr_valid		: std_logic;													-- IMEM Address Valid Flag
	signal w_dmem_addr_valid		: std_logic;													-- DMEM Address Valid Flag
	signal w_boot_addr_valid		: std_logic;													-- BOOT Address Valid Flag
	signal w_pfc_addr_valid			: std_logic;													-- PFC Address Valid Flag
	signal w_gpio_00_addr_valid		: std_logic;													-- GPIO 00 Address Valid Flag
	signal w_gpio_01_addr_valid		: std_logic;													-- GPIO 01 Address Valid Flag
	signal w_gpio_02_addr_valid		: std_logic;													-- GPIO 02 Address Valid Flag
	signal w_spi_00_addr_valid		: std_logic;													-- SPI 00 Address Valid Flag	
	signal w_spi_01_addr_valid		: std_logic;													-- SPI 01 Address Valid Flag	
	signal w_spi_02_addr_valid		: std_logic;													-- SPI 02 Address Valid Flag	
	signal w_spi_03_addr_valid		: std_logic;													-- SPI 03 Address Valid Flag
	signal w_flash_addr_valid		: std_logic;													-- NOR Flash Address Valid Flag	
	signal w_uart_00_addr_valid		: std_logic;													-- UART 00 Address Valid Flag
	signal w_uart_01_addr_valid		: std_logic;													-- UART 01 Address Valid Flag
	signal w_uart_02_addr_valid		: std_logic;													-- UART 02 Address Valid Flag
	signal w_uart_03_addr_valid		: std_logic;													-- UART 03 Address Valid Flag
	signal w_i2c_00_addr_valid		: std_logic;													-- I2C 00 Address Valid Flag
	signal w_i2c_01_addr_valid		: std_logic;													-- I2C 01 Address Valid Flag
	signal w_adc_addr_valid			: std_logic;													-- ADC Address Valid Flag
	signal w_timer_00_addr_valid	: std_logic;													-- TIMER 00 Address Valid Flag
	signal w_timer_01_addr_valid	: std_logic;													-- TIMER 01 Address Valid Flag
	signal w_hwa_addr_valid			: std_logic;													-- HWA Address Valid Flag
	signal w_frm_addr_valid			: std_logic;													-- FRM Address Valid Flag


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	BOOTLOAD READ ONLY MEMORY (BOOTROM) INSTANTIATION
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the BOOTROM component
	BOOTROM_00 : bootrom
	port map (
		i_clk						=> i_clk,
		i_reset_n					=> i_reset_n,
		
		i_pc						=> r_bootrom_pc,
		o_instr						=> r_bootrom_instr,

		i_scrb_addr					=> i_imem_scrb_addr,
		i_scrb_rw					=> i_imem_scrb_rw_en,
		i_scrb_wr					=> i_imem_scrb_data,
		o_scrb_rd					=> o_imem_scrb_data
	);

	-- Assign BOOTROM Local Program Count
	r_bootrom_pc		<= 	std_logic_vector( r_pc - c_BOOTROM_START )	when( r_pc >= c_BOOTROM_START) and ( r_pc < (c_BOOTROM_START + to_unsigned(c_BOOTROM_SIZE, 32)) ) 	else
							(others => '0');


	-- Assign BOOTROM Program Count Valid Flag
	w_bootrom_pc_valid	<= 	'1'											when( r_pc >= c_BOOTROM_START) and ( r_pc < (c_BOOTROM_START + to_unsigned(c_BOOTROM_SIZE, 32)) ) 	else
	 						'0';


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	INSTRUCTION MEMORY (IMEM) INSTANTIATION
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate Data Memory (IMEM) 
	IMEM_00 : imem
	generic map (
		g_OBFUSCATION_OFFSET        => g_OBFUSCATION_OFFSET
	)
	port map (
		i_clk						=> i_clk,
		i_reset_n					=> i_reset_n,

		i_pc						=> r_imem_pc,
		o_instr						=> r_imem_instr, --o_instr,

		i_cpu_addr					=> r_imem_addr,
		i_cpu_dw					=> i_load_size,
		i_cpu_rw					=> w_imem_rw,
		i_cpu_wr					=> i_data_wr,
		o_cpu_rd					=> r_imem_rd
	);


	-- Assign IMEM address only if it is properly bound-checked
	r_imem_addr 		<= 	std_logic_vector( r_addr - c_IMEM_START )	when( r_addr >= c_IMEM_START) and ( r_addr < c_IMEM_MAX ) 	else
							(others => '0');

	-- Assign IMEM Read/Write only if it is properly bound-checked
	w_imem_rw			<= 	i_rw_en										when( r_addr >= c_IMEM_START) and ( r_addr < c_IMEM_MAX ) 	else
							'0';

	-- Assign IMEM valid flag only if it is properly bound-checked
	w_imem_addr_valid	<= 	'1'											when( r_addr >= c_IMEM_START) and ( r_addr < c_IMEM_MAX ) 	else
							'0';


	-- Assign IMEM Local Program Count
	r_imem_pc			<= 	std_logic_vector( r_pc - c_IMEM_START )		when( r_pc >= c_IMEM_START) and ( r_pc < c_IMEM_MAX ) 		else
							(others => '0');

	-- Assign BOOTROM Program Count Valid Flag
	w_imem_pc_valid		<= 	'1'											when( r_pc >= c_IMEM_START) and ( r_pc < c_IMEM_MAX ) 		else
	 						'0';


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	DATA MEMORY (DMEM) INSTANTIATION
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate Data Memory (DMEM)
	DMEM_00 : dmem
	generic map(
		g_FLIP_BITS					=> '1',
		g_FLIP_ADDR					=> 255,
		g_FLIP_MASK					=> x"10"
	)
	port map (
		i_clk						=> i_clk,

		i_cpu_addr					=> r_dmem_addr,
		i_cpu_dw					=> i_load_size,
		i_cpu_rw					=> w_dmem_rw,
		i_cpu_wr					=> i_data_wr,
		o_cpu_rd					=> r_dmem_rd,

		i_scrb_addr					=> i_dmem_scrb_addr,
		i_scrb_rw					=> i_dmem_scrb_rw_en,
		i_scrb_wr					=> i_dmem_scrb_data,
		o_scrb_rd					=> o_dmem_scrb_data
	);


	-- Assign DMEM address only if it is properly bound-checked
	r_dmem_addr 		<= 	std_logic_vector( r_addr - c_DMEM_START )	when( r_addr >= c_DMEM_START) and ( r_addr < c_DMEM_MAX ) 	else
							(others => '0');

	-- Assign DMEM Read/Write only if it is properly bound-checked
	w_dmem_rw			<= 	i_rw_en										when( r_addr >= c_DMEM_START) and ( r_addr < c_DMEM_MAX ) 	else
							'0';


	-- Assign DMEM valid flag only if it is properly bound-checked
	w_dmem_addr_valid	<= 	'1'											when( r_addr >= c_DMEM_START) and ( r_addr < c_DMEM_MAX ) 	else
							'0';


	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS - BOOTLOAD SPI
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the bootload SPI (BOOT SPI)
	BOOT_SPI_00 : mem_spi
	generic map(
		g_CLK_RATE                  => g_CLK_RATE
	)
	port map(
		i_clk						=> i_clk,
		i_reset_n					=> i_reset_n,
		
		i_cpu_addr					=> r_boot_addr,
		i_cpu_dw					=> i_load_size,
		i_cpu_rw					=> w_boot_rw,
		i_cpu_wr					=> i_data_wr,
		o_cpu_rd					=> r_boot_rd,
	
		i_miso						=> i_miso_boot,
		o_miso						=> o_miso_boot,
		i_mosi						=> i_mosi_boot,
		o_mosi						=> o_mosi_boot,
		i_sclk						=> i_sclk_boot,
		o_sclk						=> o_sclk_boot,
		i_cs						=> i_cs_boot,
		o_cs						=> o_cs_boot,

		o_spi_mode					=> o_boot_mode,

		o_spi_irq					=> open
	);


	-- Assign UART 00 address only if it is properly bound-checked
	r_boot_addr 		<= 	std_logic_vector( r_addr - c_BOOT_SPI_START )	when( r_addr >= c_BOOT_SPI_START) and ( r_addr < c_BOOT_SPI_MEM_MAX ) 	else
							(others => '0');

	-- Assign UART 00 Read/Write only if it is properly bound-checked
	w_boot_rw			<= 	i_rw_en											when( r_addr >= c_BOOT_SPI_START) and ( r_addr < c_BOOT_SPI_MEM_MAX ) 	else
							'0';

	-- Assign DMEM valid flag only if it is properly bound-checked
	w_boot_addr_valid	<= 	'1'												when( r_addr >= c_BOOT_SPI_START) and ( r_addr < c_BOOT_SPI_MEM_MAX )	else
							'0';


	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS - PORT FUNCTION CONTROLLER
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the Port Function Controller (PFC)
	PFC_00 : mem_pfc
	port map(
		i_clk						=> i_clk,
		i_reset_n					=> i_reset_n,

		i_cpu_addr					=> r_pfc_addr,
		i_cpu_dw					=> i_load_size,
		i_cpu_rw					=> w_pfc_rw,
		i_cpu_wr					=> i_data_wr,
		o_cpu_rd					=> r_pfc_rd,

		o_port_A_sel                => o_port_A_sel,
		o_port_B_sel				=> o_port_B_sel,
		o_port_C_sel				=> o_port_C_sel
	);


	-- Assign PFC address only if it is properly bound-checked
	r_pfc_addr 			<= 	std_logic_vector( r_addr - c_PFC_MEM_START )	when( r_addr >= c_PFC_MEM_START) and ( r_addr < c_PFC_MEM_MAX ) 	else
							(others => '0');

	-- Assign PFC Read/Write only if it is properly bound-checked
	w_pfc_rw			<= 	i_rw_en											when( r_addr >= c_PFC_MEM_START) and ( r_addr < c_PFC_MEM_MAX )		else
							'0';

	-- Assign PFC valid flag only if it is properly bound-checked
	w_pfc_addr_valid	<= 	'1'												when( r_addr >= c_PFC_MEM_START) and ( r_addr < c_PFC_MEM_MAX )		else
							'0';


	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS - GPIO
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate GPIO 00 if generation flag is true
	GENERATE_GPIO_00: if ( c_GPIO_00_MEM_GENERATE = true ) generate

		-- Instantiate General Purpose Input/Output (GPIO) Device 00
		GPIO_00 : mem_gpio
		port map (
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_gpio_00_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_gpio_00_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_gpio_00_rd,

			i_gpio_in					=> i_gpio_00_in,
			o_gpio_out					=> o_gpio_00_out,
			o_gpio_dir					=> o_gpio_00_dir,
			
			o_gpio_irq					=> o_gpio_00_irq
		);


		-- Assign GPIO 00 address only if it is properly bound-checked
		r_gpio_00_addr 			<= 	std_logic_vector( r_addr - c_GPIO_00_MEM_START )	when( r_addr >= c_GPIO_00_MEM_START) and ( r_addr < c_GPIO_00_MEM_MAX ) 	else
									(others => '0');

		-- Assign GPIO 00 Read/Write only if it is properly bound-checked
		w_gpio_00_rw			<= 	i_rw_en												when( r_addr >= c_GPIO_00_MEM_START) and ( r_addr < c_GPIO_00_MEM_MAX ) 	else
									'0';

		-- Assign GPIO 00 valid flag only if it is properly bound-checked
		w_gpio_00_addr_valid	<= 	'1'													when( r_addr >= c_GPIO_00_MEM_START) and ( r_addr < c_GPIO_00_MEM_MAX )		else
									'0';

	end generate;


	-- Tie off GPIO 00 signals if generation flag is false
	IGNORE_GPIO_00: if ( c_GPIO_00_MEM_GENERATE = false ) generate

		r_gpio_00_addr			<= (others => '0');
		w_gpio_00_rw			<= '0';
		w_gpio_00_addr_valid 	<= '0';

		r_gpio_00_rd 			<= (others => '0');

		o_gpio_00_out			<= (others => '0');
		o_gpio_00_dir			<= (others => '0');
		o_gpio_00_irq			<= '0';

	end generate;


	-- Generate GPIO 01 if generation flag is true
	GENERATE_GPIO_01: if ( c_GPIO_01_MEM_GENERATE = true ) generate

		-- Instantiate General Purpose Input/Output (GPIO) Device 01
		GPIO_01 : mem_gpio
		port map (
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_gpio_01_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_gpio_01_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_gpio_01_rd,

			i_gpio_in					=> i_gpio_01_in,
			o_gpio_out					=> o_gpio_01_out,
			o_gpio_dir					=> o_gpio_01_dir,
			
			o_gpio_irq					=> o_gpio_01_irq
		);


		-- Assign GPIO 01 address only if it is properly bound-checked
		r_gpio_01_addr 			<= 	std_logic_vector( r_addr - c_GPIO_01_MEM_START )	when( r_addr >= c_GPIO_01_MEM_START) and ( r_addr < c_GPIO_01_MEM_MAX ) 	else
									(others => '0');

		-- Assign GPIO 01 Read/Write only if it is properly bound-checked
		w_gpio_01_rw			<= 	i_rw_en												when( r_addr >= c_GPIO_01_MEM_START) and ( r_addr < c_GPIO_01_MEM_MAX ) 	else
									'0';

		-- Assign GPIO 01 valid flag only if it is properly bound-checked
		w_gpio_01_addr_valid	<= 	'1'													when( r_addr >= c_GPIO_01_MEM_START) and ( r_addr < c_GPIO_01_MEM_MAX )		else
									'0';

	end generate;


	-- Tie off GPIO 01 signals if generation flag is false
	IGNORE_GPIO_01: if ( c_GPIO_01_MEM_GENERATE = false ) generate

		r_gpio_01_addr			<= (others => '0');
		w_gpio_01_rw			<= '0';
		w_gpio_01_addr_valid 	<= '0';

		r_gpio_01_rd 			<= (others => '0');

		o_gpio_01_out			<= (others => '0');
		o_gpio_01_dir			<= (others => '0');
		o_gpio_01_irq			<= '0';

	end generate;


	-- Generate GPIO 02 if generation flag is true
	GENERATE_GPIO_02: if ( c_GPIO_02_MEM_GENERATE = true ) generate

		-- Instantiate General Purpose Input/Output (GPIO) Device 01
		GPIO_02 : mem_gpio
		port map (
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_gpio_02_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_gpio_02_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_gpio_02_rd,

			i_gpio_in					=> i_gpio_02_in,
			o_gpio_out					=> o_gpio_02_out,
			o_gpio_dir					=> o_gpio_02_dir,
			
			o_gpio_irq					=> o_gpio_02_irq
		);


		-- Assign GPIO 021 address only if it is properly bound-checked
		r_gpio_02_addr 			<= 	std_logic_vector( r_addr - c_GPIO_02_MEM_START )	when( r_addr >= c_GPIO_02_MEM_START) and ( r_addr < c_GPIO_02_MEM_MAX ) 	else
									(others => '0');

		-- Assign GPIO 02 Read/Write only if it is properly bound-checked
		w_gpio_02_rw			<= 	i_rw_en												when( r_addr >= c_GPIO_02_MEM_START) and ( r_addr < c_GPIO_02_MEM_MAX ) 	else
									'0';

		-- Assign GPIO 02 valid flag only if it is properly bound-checked
		w_gpio_02_addr_valid	<= 	'1'													when( r_addr >= c_GPIO_02_MEM_START) and ( r_addr < c_GPIO_02_MEM_MAX )		else
									'0';

	end generate;


	-- Tie off GPIO 02 signals if generation flag is false
	IGNORE_GPIO_02: if ( c_GPIO_01_MEM_GENERATE = false ) generate

		r_gpio_02_addr			<= (others => '0');
		w_gpio_02_rw			<= '0';
		w_gpio_02_addr_valid 	<= '0';

		r_gpio_02_rd 			<= (others => '0');

		o_gpio_02_out			<= (others => '0');
		o_gpio_02_dir			<= (others => '0');
		o_gpio_02_irq			<= '0';

	end generate;


	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS - UART
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate UART 00 if generation flag is true
	GENERATE_UART_00: if ( c_UART_00_MEM_GENERATE = true ) generate

		UART_00 : mem_uart
		generic map (
			g_CLK_RATE                	=> g_CLK_RATE
		)
		port map (
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,

			i_cpu_addr					=> r_uart_00_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_uart_00_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_uart_00_rd,
		
			i_uart_rx					=> i_uart_00_rx,
			o_uart_tx					=> o_uart_00_tx,
			o_uart_en					=> o_uart_00_en,
			o_uart_irq					=> o_uart_00_irq
		);


		-- Assign UART 00 address only if it is properly bound-checked
		r_uart_00_addr 			<= 	std_logic_vector( r_addr - c_UART_00_MEM_START )	when( r_addr >= c_UART_00_MEM_START) and ( r_addr < c_UART_00_MEM_MAX ) 	else
									(others => '0');

		-- Assign UART 00 Read/Write only if it is properly bound-checked
		w_uart_00_rw			<= 	i_rw_en												when( r_addr >= c_UART_00_MEM_START) and ( r_addr < c_UART_00_MEM_MAX ) 	else
									'0';

		-- Assign UART 00 valid flag only if it is properly bound-checked
		w_uart_00_addr_valid	<= 	'1'													when( r_addr >= c_UART_00_MEM_START) and ( r_addr < c_UART_00_MEM_MAX )		else
									'0';

	end generate;


	-- Tie off UART 00 signals if generation flag is false
	IGNORE_UART_00: if ( c_UART_00_MEM_GENERATE = false ) generate

		r_uart_00_addr			<= (others => '0');
		w_uart_00_rw			<= '0';
		w_uart_00_addr_valid 	<= '0';

		r_uart_00_rd 			<= (others => '0');

		o_uart_00_tx			<= '0';
		o_uart_00_en			<= '0';
		o_uart_00_irq			<= '0';

	end generate;


	-- Generate UART 01 if generation flag is true
	GENERATE_UART_01: if ( c_UART_01_MEM_GENERATE = true ) generate

		UART_01 : mem_uart
		generic map (
			g_CLK_RATE                	=> g_CLK_RATE
		)
		port map (
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,

			i_cpu_addr					=> r_uart_01_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_uart_01_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_uart_01_rd,

			i_uart_rx					=> i_uart_01_rx,
			o_uart_tx					=> o_uart_01_tx,
			o_uart_en					=> o_uart_01_en,
			o_uart_irq					=> o_uart_01_irq
		);

		-- Assign UART 01 address only if it is properly bound-checked
		r_uart_01_addr 			<= 	std_logic_vector( r_addr - c_UART_01_MEM_START )	when( r_addr >= c_UART_01_MEM_START) and ( r_addr < c_UART_01_MEM_MAX ) 	else
									(others => '0');

		-- Assign UART 01 Read/Write only if it is properly bound-checked
		w_uart_01_rw			<= 	i_rw_en												when( r_addr >= c_UART_01_MEM_START) and ( r_addr < c_UART_01_MEM_MAX ) 	else
									'0';

		-- Assign UART 01 valid flag only if it is properly bound-checked
		w_uart_01_addr_valid	<= 	'1'													when( r_addr >= c_UART_01_MEM_START) and ( r_addr < c_UART_01_MEM_MAX )		else
									'0';

	end generate;


	-- Tie off UART 01 signals if generation flag is false
	IGNORE_UART_01: if ( c_UART_01_MEM_GENERATE = false ) generate

		r_uart_01_addr			<= (others => '0');
		w_uart_01_rw			<= '0';
		w_uart_01_addr_valid 	<= '0';

		r_uart_01_rd 			<= (others => '0');

		o_uart_01_tx			<= '0';
		o_uart_01_en			<= '0';
		o_uart_01_irq			<= '0';

	end generate;


	-- Generate UART 02 if generation flag is true
	GENERATE_UART_02: if ( c_UART_02_MEM_GENERATE = true ) generate

		UART_02 : mem_uart
		generic map (
			g_CLK_RATE                	=> g_CLK_RATE
		)
		port map (
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,

			i_cpu_addr					=> r_uart_02_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_uart_02_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_uart_02_rd,

			i_uart_rx					=> i_uart_02_rx,
			o_uart_tx					=> o_uart_02_tx,
			o_uart_en					=> o_uart_02_en,
			o_uart_irq					=> o_uart_02_irq
		);

		-- Assign UART 02 address only if it is properly bound-checked
		r_uart_02_addr 			<= 	std_logic_vector( r_addr - c_UART_02_MEM_START )	when( r_addr >= c_UART_02_MEM_START) and ( r_addr < c_UART_02_MEM_MAX ) 	else
									(others => '0');

		-- Assign UART 02 Read/Write only if it is properly bound-checked
		w_uart_02_rw			<= 	i_rw_en												when( r_addr >= c_UART_02_MEM_START) and ( r_addr < c_UART_02_MEM_MAX ) 	else
									'0';

		-- Assign UART 02 valid flag only if it is properly bound-checked
		w_uart_02_addr_valid	<= 	'1'													when( r_addr >= c_UART_02_MEM_START) and ( r_addr < c_UART_02_MEM_MAX )		else
									'0';

	end generate;


	-- Tie off UART 02 signals if generation flag is false
	IGNORE_UART_02: if ( c_UART_02_MEM_GENERATE = false ) generate

		r_uart_02_addr			<= (others => '0');
		w_uart_02_rw			<= '0';
		w_uart_02_addr_valid 	<= '0';

		r_uart_02_rd 			<= (others => '0');

		o_uart_02_tx			<= '0';
		o_uart_02_en			<= '0';
		o_uart_02_irq			<= '0';

	end generate;


	-- Generate UART 03 if generation flag is true
	GENERATE_UART_03: if ( c_UART_03_MEM_GENERATE = true ) generate

		UART_03 : mem_uart
		generic map (
			g_CLK_RATE                	=> g_CLK_RATE
		)
		port map (
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,

			i_cpu_addr					=> r_uart_03_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_uart_03_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_uart_03_rd,

			i_uart_rx					=> i_uart_03_rx,
			o_uart_tx					=> o_uart_03_tx,
			o_uart_en					=> o_uart_03_en,
			o_uart_irq					=> o_uart_03_irq
		);

		-- Assign UART 03 address only if it is properly bound-checked
		r_uart_03_addr 			<= 	std_logic_vector( r_addr - c_UART_03_MEM_START )	when( r_addr >= c_UART_03_MEM_START) and ( r_addr < c_UART_03_MEM_MAX ) 	else
									(others => '0');

		-- Assign UART 03 Read/Write only if it is properly bound-checked
		w_uart_03_rw			<= 	i_rw_en												when( r_addr >= c_UART_03_MEM_START) and ( r_addr < c_UART_03_MEM_MAX ) 	else
									'0';

		-- Assign UART 02 valid flag only if it is properly bound-checked
		w_uart_03_addr_valid	<= 	'1'													when( r_addr >= c_UART_03_MEM_START) and ( r_addr < c_UART_03_MEM_MAX )		else
									'0';

	end generate;


	-- Tie off UART 03 signals if generation flag is false
	IGNORE_UART_03: if ( c_UART_03_MEM_GENERATE = false ) generate

		r_uart_03_addr			<= (others => '0');
		w_uart_03_rw			<= '0';
		w_uart_03_addr_valid 	<= '0';

		r_uart_03_rd 			<= (others => '0');

		o_uart_03_tx			<= '0';
		o_uart_03_en			<= '0';
		o_uart_03_irq			<= '0';

	end generate;


	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS - SPI
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate SPI 00 if generation flag is true
	GENERATE_SPI_00: if ( c_SPI_00_MEM_GENERATE = true ) generate

		SPI_00 : mem_spi
		generic map(
			g_CLK_RATE                  => g_CLK_RATE
		)
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_spi_00_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_spi_00_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_spi_00_rd,
		
			i_miso						=> i_miso_00,
			o_miso						=> o_miso_00,
			i_mosi						=> i_mosi_00,
			o_mosi						=> o_mosi_00,
			i_sclk						=> i_sclk_00,
			o_sclk						=> o_sclk_00,
			i_cs						=> i_cs_00,
			o_cs						=> o_cs_00,

			o_spi_mode					=> o_spi_mode_00,

			o_spi_irq					=> o_spi_irq_00
		);


		-- Assign SPI 00 address only if it is properly bound-checked
		r_spi_00_addr 			<= 	std_logic_vector( r_addr - c_SPI_00_MEM_START )		when( r_addr >= c_SPI_00_MEM_START) and ( r_addr < c_SPI_00_MEM_MAX ) 	else
									(others => '0');

		-- Assign SPI 00 Read/Write only if it is properly bound-checked
		w_spi_00_rw				<= 	i_rw_en												when( r_addr >= c_SPI_00_MEM_START) and ( r_addr < c_SPI_00_MEM_MAX ) 	else
									'0';

		-- Assign SPI 00 valid flag only if it is properly bound-checked
		w_spi_00_addr_valid		<= 	'1'													when( r_addr >= c_SPI_00_MEM_START) and ( r_addr < c_SPI_00_MEM_MAX )	else
									'0';

	end generate;


	-- Tie off SPI 00 signals if generation flag is false
	IGNORE_SPI_00: if ( c_SPI_00_MEM_GENERATE = false ) generate

		r_spi_00_addr			<= (others => '0');
		w_spi_00_rw				<= '0';
		w_spi_00_addr_valid 	<= '0';

		r_spi_00_rd 			<= (others => '0');

		o_miso_00				<= '0';
		o_mosi_00				<= '0';
		o_sclk_00				<= '0';
		o_cs_00					<= '0';

		o_spi_mode_00			<= '0';

		o_spi_irq_00			<= '0';

	end generate;


	-- Generate SPI 01 if generation flag is true
	GENERATE_SPI_01: if ( c_SPI_01_MEM_GENERATE = true ) generate

		SPI_01 : mem_spi
		generic map(
			g_CLK_RATE                  => g_CLK_RATE
		)
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_spi_01_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_spi_01_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_spi_01_rd,
		
			i_miso						=> i_miso_01,
			o_miso						=> o_miso_01,
			i_mosi						=> i_mosi_01,
			o_mosi						=> o_mosi_01,
			i_sclk						=> i_sclk_01,
			o_sclk						=> o_sclk_01,
			i_cs						=> i_cs_01,
			o_cs						=> o_cs_01,

			o_spi_mode					=> o_spi_mode_01,

			o_spi_irq					=> o_spi_irq_01
		);


		-- Assign SPI 01 address only if it is properly bound-checked
		r_spi_01_addr 			<= 	std_logic_vector( r_addr - c_SPI_01_MEM_START )		when( r_addr >= c_SPI_01_MEM_START) and ( r_addr < c_SPI_01_MEM_MAX ) 	else
									(others => '0');

		-- Assign SPI 01 Read/Write only if it is properly bound-checked
		w_spi_01_rw				<= 	i_rw_en												when( r_addr >= c_SPI_01_MEM_START) and ( r_addr < c_SPI_01_MEM_MAX ) 	else
									'0';

		-- Assign SPI 01 valid flag only if it is properly bound-checked
		w_spi_01_addr_valid		<= 	'1'													when( r_addr >= c_SPI_01_MEM_START) and ( r_addr < c_SPI_01_MEM_MAX )	else
									'0';

	end generate;


	-- Tie off SPI 01 signals if generation flag is false
	IGNORE_SPI_01: if ( c_SPI_01_MEM_GENERATE = false ) generate

		r_spi_01_addr			<= (others => '0');
		w_spi_01_rw				<= '0';
		w_spi_01_addr_valid 	<= '0';

		r_spi_01_rd 			<= (others => '0');

		o_miso_01				<= '0';
		o_mosi_01				<= '0';
		o_sclk_01				<= '0';
		o_cs_01					<= '0';

		o_spi_mode_01			<= '0';

		o_spi_irq_01			<= '0';

	end generate;


	-- Generate SPI 02 if generation flag is true
	GENERATE_SPI_02: if ( c_SPI_02_MEM_GENERATE = true ) generate

		SPI_02 : mem_spi
		generic map(
			g_CLK_RATE                  => g_CLK_RATE
		)
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_spi_02_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_spi_02_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_spi_02_rd,
		
			i_miso						=> i_miso_02,
			o_miso						=> o_miso_02,
			i_mosi						=> i_mosi_02,
			o_mosi						=> o_mosi_02,
			i_sclk						=> i_sclk_02,
			o_sclk						=> o_sclk_02,
			i_cs						=> i_cs_02,
			o_cs						=> o_cs_02,

			o_spi_mode					=> o_spi_mode_02,

			o_spi_irq					=> o_spi_irq_02
		);


		-- Assign SPI 02 address only if it is properly bound-checked
		r_spi_02_addr 			<= 	std_logic_vector( r_addr - c_SPI_02_MEM_START )		when( r_addr >= c_SPI_02_MEM_START) and ( r_addr < c_SPI_02_MEM_MAX ) 	else
									(others => '0');

		-- Assign SPI 02 Read/Write only if it is properly bound-checked
		w_spi_02_rw				<= 	i_rw_en												when( r_addr >= c_SPI_02_MEM_START) and ( r_addr < c_SPI_02_MEM_MAX ) 	else
									'0';

		-- Assign SPI 02 valid flag only if it is properly bound-checked
		w_spi_02_addr_valid		<= 	'1'													when( r_addr >= c_SPI_02_MEM_START) and ( r_addr < c_SPI_02_MEM_MAX )	else
									'0';

	end generate;


	-- Tie off SPI 02 signals if generation flag is false
	IGNORE_SPI_02: if ( c_SPI_02_MEM_GENERATE = false ) generate

		r_spi_02_addr			<= (others => '0');
		w_spi_02_rw				<= '0';
		w_spi_02_addr_valid 	<= '0';

		r_spi_02_rd 			<= (others => '0');

		o_miso_02				<= '0';
		o_mosi_02				<= '0';
		o_sclk_02				<= '0';
		o_cs_02					<= '0';

		o_spi_mode_02			<= '0';

		o_spi_irq_02			<= '0';

	end generate;


	-- Generate SPI 03 if generation flag is true
	GENERATE_SPI_03: if ( c_SPI_03_MEM_GENERATE = true ) generate

		SPI_03 : mem_spi
		generic map(
			g_CLK_RATE                  => g_CLK_RATE
		)
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_spi_03_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_spi_03_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_spi_03_rd,
		
			i_miso						=> i_miso_03,
			o_miso						=> o_miso_03,
			i_mosi						=> i_mosi_03,
			o_mosi						=> o_mosi_03,
			i_sclk						=> i_sclk_03,
			o_sclk						=> o_sclk_03,
			i_cs						=> i_cs_03,
			o_cs						=> o_cs_03,

			o_spi_mode					=> o_spi_mode_03,

			o_spi_irq					=> o_spi_irq_03
		);


		-- Assign SPI 03 address only if it is properly bound-checked
		r_spi_03_addr 			<= 	std_logic_vector( r_addr - c_SPI_03_MEM_START )		when( r_addr >= c_SPI_03_MEM_START) and ( r_addr < c_SPI_03_MEM_MAX ) 	else
									(others => '0');

		-- Assign SPI 03 Read/Write only if it is properly bound-checked
		w_spi_03_rw				<= 	i_rw_en												when( r_addr >= c_SPI_03_MEM_START) and ( r_addr < c_SPI_03_MEM_MAX ) 	else
									'0';

		-- Assign SPI 03 valid flag only if it is properly bound-checked
		w_spi_03_addr_valid		<= 	'1'													when( r_addr >= c_SPI_03_MEM_START) and ( r_addr < c_SPI_03_MEM_MAX )	else
									'0';

	end generate;


	-- Tie off SPI 03 signals if generation flag is false
	IGNORE_SPI_03: if ( c_SPI_03_MEM_GENERATE = false ) generate

		r_spi_03_addr			<= (others => '0');
		w_spi_03_rw				<= '0';
		w_spi_03_addr_valid 	<= '0';

		r_spi_03_rd 			<= (others => '0');

		o_miso_03				<= '0';
		o_mosi_03				<= '0';
		o_sclk_03				<= '0';
		o_cs_03					<= '0';

		o_spi_mode_03			<= '0';

		o_spi_irq_03			<= '0';

	end generate;


	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS - NOR FLASH SPI
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate NOR Flash if generation flag is true
	GENERATE_FLASH: if ( c_FLASH_MEM_GENERATE = true ) generate

		SPI_03 : mem_spi
		generic map(
			g_CLK_RATE                  => g_CLK_RATE
		)
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_flash_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_flash_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_flash_rd,
		
			i_miso						=> i_miso_flash,
			o_miso						=> open, --o_miso_flash,
			i_mosi						=> '0', --i_mosi_flash,
			o_mosi						=> o_mosi_flash,
			i_sclk						=> '0', --i_sclk_flash,
			o_sclk						=> o_sclk_flash,
			i_cs						=> '0', --i_cs_flash,
			o_cs						=> o_cs_flash,

			o_spi_mode					=> open,

			o_spi_irq					=> open
		);


		-- Assign NOR Flash address only if it is properly bound-checked
		r_flash_addr 			<= 	std_logic_vector( r_addr - c_FLASH_MEM_START )		when( r_addr >= c_FLASH_MEM_START) and ( r_addr < c_FLASH_MEM_MAX ) 	else
									(others => '0');

		-- Assign NOR Flash Read/Write only if it is properly bound-checked
		w_flash_rw				<= 	i_rw_en												when( r_addr >= c_FLASH_MEM_START) and ( r_addr < c_FLASH_MEM_MAX ) 	else
									'0';

		-- Assign NOR Flash valid flag only if it is properly bound-checked
		w_flash_addr_valid		<= 	'1'													when( r_addr >= c_FLASH_MEM_START) and ( r_addr < c_FLASH_MEM_MAX )		else
									'0';

	end generate;


	-- Tie off NOR Flash signals if generation flag is false
	IGNORE_FLASH: if ( c_FLASH_MEM_GENERATE = false ) generate

		r_flash_addr			<= (others => '0');
		w_flash_rw				<= '0';
		w_flash_addr_valid 		<= '0';

		r_flash_rd 				<= (others => '0');

		--o_miso_flash			<= '0';
		o_mosi_flash			<= '0';
		o_sclk_flash			<= '0';
		o_cs_flash				<= '0';

	end generate;


	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS - I2C
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate I2C 00 if generation flag is true
	GENERATE_I2C_00: if ( c_I2C_00_MEM_GENERATE = true ) generate

		I2C_00 : mem_i2c
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_i2c_00_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_i2c_00_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_i2c_00_rd,

			i_scl						=> i_scl_00,
			i_sda						=> i_sda_00,
			o_scl						=> o_scl_00,
			o_sda						=> o_sda_00,
			o_I2C_mode					=> o_I2C_mode_00,

			o_i2c_irq					=> o_i2c_irq_00
		);


		-- Assign I2C 00 address only if it is properly bound-checked
		r_i2c_00_addr 			<= 	std_logic_vector( r_addr - c_I2C_00_MEM_START )		when( r_addr >= c_I2C_00_MEM_START) and ( r_addr < c_I2C_00_MEM_MAX ) 	else
									(others => '0');

		-- Assign I2C 00 Read/Write only if it is properly bound-checked
		w_i2c_00_rw				<= 	i_rw_en												when( r_addr >= c_I2C_00_MEM_START) and ( r_addr < c_I2C_00_MEM_MAX ) 	else
									'0';

		-- Assign I2C 00 valid flag only if it is properly bound-checked
		w_i2c_00_addr_valid		<= 	'1'													when( r_addr >= c_I2C_00_MEM_START) and ( r_addr < c_I2C_00_MEM_MAX )	else
									'0';

	end generate;


	-- Tie off I2C 00 signals if generation flag is false
	IGNORE_I2C_00: if ( c_I2C_00_MEM_GENERATE = false ) generate

		r_i2c_00_addr			<= (others => '0');
		w_i2c_00_rw				<= '0';
		w_i2c_00_addr_valid 	<= '0';

		r_i2c_00_rd 			<= (others => '0');

		o_scl_00				<= '1';
		o_sda_00				<= '1';
		o_I2C_Mode_00			<= "11";
		o_i2c_irq_00			<= '0';

	end generate;


	-- Generate I2C 01 if generation flag is true
	GENERATE_I2C_01: if ( c_I2C_01_MEM_GENERATE = true ) generate

		I2C_01 : mem_i2c
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_i2c_01_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_i2c_01_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_i2c_01_rd,

			i_scl						=> i_scl_01,
			i_sda						=> i_sda_01,
			o_scl						=> o_scl_01,
			o_sda						=> o_sda_01,
			o_I2C_mode					=> o_I2C_mode_01,

			o_i2c_irq					=> o_i2c_irq_01
		);


		-- Assign I2C 01 address only if it is properly bound-checked
		r_i2c_01_addr 			<= 	std_logic_vector( r_addr - c_I2C_01_MEM_START )		when( r_addr >= c_I2C_01_MEM_START) and ( r_addr < c_I2C_01_MEM_MAX ) 	else
									(others => '0');

		-- Assign I2C 01 Read/Write only if it is properly bound-checked
		w_i2c_01_rw				<= 	i_rw_en												when( r_addr >= c_I2C_01_MEM_START) and ( r_addr < c_I2C_01_MEM_MAX ) 	else
									'0';

		-- Assign I2C 01 valid flag only if it is properly bound-checked
		w_i2c_01_addr_valid		<= 	'1'													when( r_addr >= c_I2C_01_MEM_START) and ( r_addr < c_I2C_01_MEM_MAX )	else
									'0';

	end generate;


	-- Tie off I2C 01 signals if generation flag is false
	IGNORE_I2C_01: if ( c_I2C_01_MEM_GENERATE = false ) generate

		r_i2c_01_addr			<= (others => '0');
		w_i2c_01_rw				<= '0';
		w_i2c_01_addr_valid 	<= '0';

		r_i2c_01_rd 			<= (others => '0');

		o_scl_01				<= '1';
		o_sda_01				<= '1';
		o_I2C_Mode_01			<= "11";
		o_i2c_irq_01			<= '0';

	end generate;


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT INSTANTIATIONS - ANALOG TO DIGITAL CONVERTER
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate ADC if generation flag is true
	GENERATE_ADC: if ( c_ADC_MEM_GENERATE = true ) generate

		ADC_00 : mem_adc
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,

			i_cpu_addr					=> r_adc_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_adc_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_adc_rd,

			i_adc_data_read				=> i_adc_data_read,
			i_adc_channel				=> i_adc_channel,
			o_adc_addr					=> o_adc_addr
		);

		-- Assign ADC address only if it is properly bound-checked
		r_adc_addr 				<= 	std_logic_vector( r_addr - c_ADC_MEM_START )		when( r_addr >= c_ADC_MEM_START) and ( r_addr < c_ADC_MEM_MAX ) 	else
									(others => '0');

		-- Assign ADC Read/Write only if it is properly bound-checked
		w_adc_rw				<= 	i_rw_en												when( r_addr >= c_ADC_MEM_START) and ( r_addr < c_ADC_MEM_MAX ) 	else
									'0';

		-- Assign ADC valid flag only if it is properly bound-checked
		w_adc_addr_valid		<= 	'1'													when( r_addr >= c_ADC_MEM_START) and ( r_addr < c_ADC_MEM_MAX )		else
									'0';

	end generate;


	-- Tie off ADC signals if generation flag is false
	IGNORE_ADC: if ( c_ADC_MEM_GENERATE = false ) generate

		r_adc_addr				<= (others => '0');
		w_adc_rw				<= '0';
		w_adc_addr_valid 		<= '0';

		r_adc_rd 				<= (others => '0');

		o_adc_addr				<= (others => '0');

	end generate;



	------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT INSTANTIATIONS - HARDWARE ACCELERATOR MEMORY INTERFACE
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate HWA if generation flag is true
	GENERATE_HWA : if ( c_HWA_MEM_GENERATE = true ) generate

		HWA_00 : mem_hwa
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,

			i_cpu_addr					=> r_hwa_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_hwa_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_hwa_rd,

			i_hwa_id					=> i_hwa_id,

			i_hwa_read_00				=> i_hwa_read_00,
			i_hwa_read_01				=> i_hwa_read_01,
			i_hwa_read_02				=> i_hwa_read_02,
			i_hwa_read_03				=> i_hwa_read_03,
			i_hwa_read_04				=> i_hwa_read_04,
			i_hwa_read_05				=> i_hwa_read_05,
			i_hwa_read_06				=> i_hwa_read_06,
			i_hwa_read_07				=> i_hwa_read_07,

			o_hwa_write_00				=> o_hwa_write_00,
			o_hwa_write_01				=> o_hwa_write_01,
			o_hwa_write_02				=> o_hwa_write_02,
			o_hwa_write_03				=> o_hwa_write_03,
			o_hwa_write_04				=> o_hwa_write_04,
			o_hwa_write_05				=> o_hwa_write_05,
			o_hwa_write_06				=> o_hwa_write_06,
			o_hwa_write_07				=> o_hwa_write_07,

			o_hwa_ctrl					=> o_hwa_ctrl,
			i_hwa_stat					=> i_hwa_stat,

			o_pr_decouple				=> o_pr_decouple
		);


		-- Assign HWA address only if it is properly bound-checked
		r_hwa_addr 			<= 	std_logic_vector( r_addr - c_HWA_MEM_START )	when( r_addr >= c_HWA_MEM_START) and ( r_addr < c_HWA_MEM_MAX ) 	else
								(others => '0');

		-- Assign HWA Read/Write only if it is properly bound-checked
		w_hwa_rw			<= 	i_rw_en											when( r_addr >= c_HWA_MEM_START) and ( r_addr < c_HWA_MEM_MAX ) 	else
								'0';

		-- Assign HWA valid flag only if it is properly bound-checked
		w_hwa_addr_valid	<= 	'1'												when( r_addr >= c_HWA_MEM_START) and ( r_addr < c_HWA_MEM_MAX ) 	else
								'0';


	end generate;


	-- Tie off HWAMI signals if generation flag is false
	IGNORE_HWAMI : if ( c_HWA_MEM_GENERATE = false ) generate

		r_hwa_addr 				<= (others => '0');
		w_hwa_rw				<= '0';
		w_hwa_addr_valid 		<= '0';

		r_hwa_rd				<= (others => '0');

		o_hwa_write_00			<= (others => '0');
		o_hwa_write_01			<= (others => '0');
		o_hwa_write_02			<= (others => '0');
		o_hwa_write_03			<= (others => '0');
		o_hwa_write_04			<= (others => '0');
		o_hwa_write_05			<= (others => '0');
		o_hwa_write_06			<= (others => '0');
		o_hwa_write_07			<= (others => '0');

		o_hwa_ctrl				<= (others => '0');

	end generate;

	
	------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT INSTANTIATIONS - TIMER
	------------------------------------------------------------------------------------------------------------------------------------

	-- Generate TIMER if generation flag is true
	GENERATE_TIMER_00 : if ( c_TIMER_00_GENERATE = true ) generate

		TIMER_00 : mem_timer
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,

			i_cpu_addr					=> r_timer_00_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_timer_00_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_timer_00_rd,

			o_timer_irq					=> o_timer_00_irq
		);


		-- Assign TIMER 00 address only if it is properly bound-checked
		r_timer_00_addr 		<= 	std_logic_vector( r_addr - c_TIMER_00_START )	when( r_addr >= c_TIMER_00_START) and ( r_addr < c_TIMER_00_MEM_MAX ) 	else
									(others => '0');

		-- Assign TIMER 00 Read/Write only if it is properly bound-checked
		w_timer_00_rw			<= 	i_rw_en											when( r_addr >= c_TIMER_00_START) and ( r_addr < c_TIMER_00_MEM_MAX ) 	else
									'0';

		-- Assign TIMER 00 valid flag only if it is properly bound-checked
		w_timer_00_addr_valid	<= 	'1'												when( r_addr >= c_TIMER_00_START) and ( r_addr < c_TIMER_00_MEM_MAX ) 	else
									'0';

	end generate;


	-- Tie off TIMER signals if generation flag is false
	IGNORE_TIMER_00 : if ( c_TIMER_00_GENERATE = false ) generate

		r_timer_00_addr			<= (others => '0');
		w_timer_00_rw			<= '0';
		w_timer_00_addr_valid 	<= '0';

		r_timer_00_rd 			<= (others => '0');

		o_timer_00_irq			<= '0';

	end generate;


	-- Generate GPIO 01 if generation flag is true
	GENERATE_TIMER_01: if ( c_TIMER_01_GENERATE = true ) generate

		-- Instantiate General Purpose Input/Output (GPIO) Device 01
		TIMER_01 : mem_timer
		port map (
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_timer_01_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_timer_01_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_timer_01_rd,

			o_timer_irq					=> o_timer_01_irq
		);

		-- Assign TIMER 01 address only if it is properly bound-checked
		r_timer_01_addr 		<= 	std_logic_vector( r_addr - c_TIMER_01_START )	when( r_addr >= c_TIMER_01_START) and ( r_addr < c_TIMER_01_MEM_MAX ) 	else
									(others => '0');

		-- Assign TIMER 01 Read/Write only if it is properly bound-checked
		w_timer_01_rw			<= 	i_rw_en											when( r_addr >= c_TIMER_01_START) and ( r_addr < c_TIMER_01_MEM_MAX ) 	else
									'0';

		-- Assign TIMER 01 valid flag only if it is properly bound-checked
		w_timer_01_addr_valid	<= 	'1'												when( r_addr >= c_TIMER_01_START) and ( r_addr < c_TIMER_01_MEM_MAX ) 	else
									'0';


	end generate;


	-- Tie off GPIO 01 signals if generation flag is false
	IGNORE_TIMER_01: if ( c_TIMER_01_GENERATE = false ) generate

		r_timer_01_addr			<= (others => '0');
		w_timer_01_rw			<= '0';
		w_timer_01_addr_valid 	<= '0';

		r_timer_01_rd 			<= (others => '0');

		o_timer_01_irq			<= '0';

	end generate;


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT INSTANTIATIONS - FAULT RECOVERY MECHANISM (FRM)
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the Fault Recovery Mechanism (FRM) component
	FRM_00 : mem_frm
		port map(
			i_clk						=> i_clk,
			i_reset_n					=> i_reset_n,
			
			i_cpu_addr					=> r_frm_addr,
			i_cpu_dw					=> i_load_size,
			i_cpu_rw					=> w_frm_rw,
			i_cpu_wr					=> i_data_wr,
			o_cpu_rd					=> r_frm_rd,

			i_sem_stat					=> i_sem_stat,
			i_arbiter_stat				=> i_arbiter_stat,
			i_monitor_stat				=> i_monitor_stat,
			i_imem_scrubber_stat		=> i_imem_stat,
			i_dmem_scrubber_stat		=> i_dmem_stat,
			i_bootrom_stat				=> i_bootrom_stat,

			o_index						=> o_index,
			i_event						=> i_event
		);


	-- Assign FRM address only if it is properly bound-checked
	r_frm_addr 			<= 	std_logic_vector( r_addr - c_FRM_START )	when( r_addr >= c_FRM_START) and ( r_addr < c_FRM_MEM_MAX ) 	else
							(others => '0');

	-- Assign FRM Read/Write only if it is properly bound-checked
	w_frm_rw			<= 	i_rw_en										when( r_addr >= c_FRM_START) and ( r_addr < c_FRM_MEM_MAX ) 	else
							'0';

	-- Assign FRM valid flag only if it is properly bound-checked
	w_frm_addr_valid	<= 	'1'											when( r_addr >= c_FRM_START) and ( r_addr < c_FRM_MEM_MAX ) 	else
							'0';



	------------------------------------------------------------------------------------------------------------------------------------
	--	GLOBAL ADDRESS ASSIGNMENT
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign global address to unsigned signal
	r_addr	<= unsigned( i_addr );
	r_pc	<= unsigned( i_pc );


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign instruction based on active memory component
	o_instr			<= 	r_imem_instr 		when( w_imem_pc_valid = '1' )			else
						r_bootrom_instr 	when( w_bootrom_pc_valid = '1' )		else
						(others => '0');
	

	-- Assign illegal Program Count when a bad program count is detected (out of range)
	o_illegal_pc	<= 	'1'		when( r_pc < c_BOOTROM_START) or ( r_pc >= (c_IMEM_START + to_unsigned(c_IMEM_SIZE, 32)) ) 		else
						'0';
	

	-- Route output data
	o_data_rd 	<= 	r_imem_rd 			when ( w_imem_addr_valid 		= '1') 		else
					r_dmem_rd 			when ( w_dmem_addr_valid 		= '1') 		else

					r_boot_rd 			when ( w_boot_addr_valid 		= '1') 		else

					r_pfc_rd			when ( w_pfc_addr_valid 		= '1') 		else

					r_gpio_00_rd 		when ( w_gpio_00_addr_valid 	= '1') 		else
					r_gpio_01_rd 		when ( w_gpio_01_addr_valid 	= '1') 		else
					r_gpio_02_rd 		when ( w_gpio_02_addr_valid 	= '1') 		else

					r_uart_00_rd 		when ( w_uart_00_addr_valid 	= '1') 		else
					r_uart_01_rd 		when ( w_uart_01_addr_valid 	= '1') 		else
					r_uart_02_rd 		when ( w_uart_02_addr_valid 	= '1') 		else
					r_uart_03_rd 		when ( w_uart_03_addr_valid 	= '1') 		else

					r_spi_00_rd 		when ( w_spi_00_addr_valid 		= '1') 		else
					r_spi_01_rd 		when ( w_spi_01_addr_valid 		= '1') 		else
					r_spi_02_rd 		when ( w_spi_02_addr_valid 		= '1') 		else
					r_spi_03_rd 		when ( w_spi_03_addr_valid 		= '1') 		else

					r_flash_rd 			when ( w_flash_addr_valid 		= '1') 		else

					r_i2c_00_rd 		when ( w_i2c_00_addr_valid 		= '1') 		else
					r_i2c_01_rd 		when ( w_i2c_01_addr_valid 		= '1') 		else

					r_adc_rd			when ( w_adc_addr_valid 		= '1') 		else

					r_timer_00_rd		when ( w_timer_00_addr_valid	= '1')		else
					r_timer_01_rd		when ( w_timer_01_addr_valid	= '1')		else

					r_hwa_rd			when ( w_hwa_addr_valid 		= '1') 		else

					r_frm_rd			when ( w_frm_addr_valid 		= '1') 		else

					(others => '0');	


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------