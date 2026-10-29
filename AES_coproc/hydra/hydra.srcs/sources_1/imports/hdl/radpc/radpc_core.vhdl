----------------------------------------------------------------------------------------------------------------------------------------
--
--!	@file
--!	@brief The top-most RadPC entity and a wrapper for the RadPC RISCV "Reach" processing cores.
--
--	RADPC MULTI-PROCESSOR CORE
--
--	Created by Chris Major
--  Resilient Computing
-- 	12/7/2022
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
--  LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	-- IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;

	-- IEEE Numeric Standard Library
	use IEEE.NUMERIC_STD.ALL;

	-- IEEE Real-Value Math Library
	use IEEE.MATH_REAL.ALL;


	-- RadPC Reach Core Package
	use WORK.REACH_CORE_PKG.all;


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity radpc_core is
generic (
	g_CLK_RATE                	: integer           := 100_000_000							-- Clock rate [Hz]
);
port(
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
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture radpc_core_arch of radpc_core is

    ------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    --! RadPC RISCV "Reach" core
    component reach_core is
    generic (
        g_CORE_ID                  	: integer           := 0;
        g_CLK_RATE                	: integer           := 100_000_000;
        g_OBFUSCATION_OFFSET       	: integer           := 0;
		g_CORRUPTION				: integer			:= 0
    );
    port(
        i_clk						: in    std_logic;
		i_reset_n					: in    std_logic;

		i_error_detect              : in    std_logic;
		o_arbiter_en                : out   std_logic;
		o_scrubber_en               : out   std_logic;

		o_pc                        : out   std_logic_vector(31 downto 0);

		i_bootload_en               : in    std_logic;
		o_radpc_active              : out   std_logic;
		o_illegal_opcode            : out   std_logic;
		o_runtime_stat              : out   std_logic_vector(31 downto 0);
		o_instr						: out	std_logic_vector(31 downto 0);

		i_sem_status				: in 	std_logic_vector(7 downto 0);

		i_pc_repair_en              : in    std_logic;
		i_pc_repair                 : in    std_logic_vector(31 downto 0);

		o_reg_D_wr                  : out   std_logic_vector(31 downto 0);
		i_reg_D_wr                  : in    std_logic_vector(31 downto 0);
	
		o_reg_read				    : out	std_logic_vector(31 downto 0);
		i_reg_write					: in	std_logic_vector(31 downto 0);
		i_reg_addr					: in	std_logic_vector(4 downto 0);
		i_reg_rw					: in	std_logic;

		i_imem_scrb_addr			: in 	std_logic_vector(31 downto 0);
		i_imem_scrb_rw_en			: in	std_logic;
		i_imem_scrb_data			: in 	std_logic_vector(31 downto 0);
		o_imem_scrb_data			: out	std_logic_vector(31 downto 0);

		i_dmem_scrb_addr			: in 	std_logic_vector(31 downto 0);
		i_dmem_scrb_rw_en			: in	std_logic;
		i_dmem_scrb_data			: in 	std_logic_vector(31 downto 0);
		o_dmem_scrb_data			: out	std_logic_vector(31 downto 0);

		o_port_A_sel                : out   std_logic_vector(31 downto 0);
		o_port_B_sel                : out   std_logic_vector(31 downto 0);
		o_port_C_sel                : out   std_logic_vector(31 downto 0);

		i_gpio_00_in				: in 	std_logic_vector(31 downto 0);
		o_gpio_00_out				: out 	std_logic_vector(31 downto 0);
		o_gpio_00_dir				: out 	std_logic_vector(31 downto 0);

		i_gpio_01_in				: in 	std_logic_vector(31 downto 0);
		o_gpio_01_out				: out 	std_logic_vector(31 downto 0);
		o_gpio_01_dir				: out 	std_logic_vector(31 downto 0);

		i_gpio_02_in				: in 	std_logic_vector(31 downto 0);
		o_gpio_02_out				: out 	std_logic_vector(31 downto 0);
		o_gpio_02_dir				: out 	std_logic_vector(31 downto 0);

		i_uart_00_rx				: in	std_logic;
		o_uart_00_tx				: out	std_logic;
		o_uart_00_en                : out	std_logic;

		i_uart_01_rx				: in	std_logic;
		o_uart_01_tx				: out	std_logic;
		o_uart_01_en                : out	std_logic;
		
		i_uart_02_rx				: in	std_logic;
		o_uart_02_tx				: out	std_logic;
		o_uart_02_en                : out	std_logic;

		i_uart_03_rx				: in	std_logic;
		o_uart_03_tx				: out	std_logic;
		o_uart_03_en                : out	std_logic;

		i_miso_boot					: in	std_logic;
		o_miso_boot					: out	std_logic;
		i_mosi_boot					: in	std_logic;
		o_mosi_boot					: out	std_logic;
		i_sclk_boot					: in	std_logic;
		o_sclk_boot					: out	std_logic;
		i_cs_boot 					: in	std_logic;
		o_cs_boot 					: out	std_logic;
		o_boot_mode					: out	std_logic;

		i_miso_00					: in	std_logic;
		o_miso_00					: out	std_logic;
		i_mosi_00					: in	std_logic;
		o_mosi_00					: out	std_logic;
		i_sclk_00					: in	std_logic; 
		o_sclk_00					: out	std_logic; 
		i_cs_00						: in	std_logic; 
		o_cs_00						: out	std_logic; 
		o_spi_mode_00				: out	std_logic;

		i_miso_01					: in	std_logic;
		o_miso_01					: out	std_logic;
		i_mosi_01					: in	std_logic;
		o_mosi_01					: out	std_logic;
		i_sclk_01					: in	std_logic;
		o_sclk_01					: out	std_logic;
		i_cs_01						: in	std_logic;
		o_cs_01						: out	std_logic;
		o_spi_mode_01				: out	std_logic;

		i_miso_02					: in	std_logic;
		o_miso_02					: out	std_logic;
		i_mosi_02					: in	std_logic;
		o_mosi_02					: out	std_logic;
		i_sclk_02					: in	std_logic;
		o_sclk_02					: out	std_logic;
		i_cs_02						: in	std_logic;
		o_cs_02						: out	std_logic;
		o_spi_mode_02				: out	std_logic;

		i_miso_03					: in	std_logic;
		o_miso_03					: out	std_logic;
		i_mosi_03					: in	std_logic;
		o_mosi_03					: out	std_logic;
		i_sclk_03					: in	std_logic;
		o_sclk_03					: out	std_logic;
		i_cs_03						: in	std_logic;
		o_cs_03						: out	std_logic;
		o_spi_mode_03				: out	std_logic;

		i_miso_flash				: in	std_logic;
		o_mosi_flash				: out	std_logic;
		o_sclk_flash				: out	std_logic;
		o_cs_flash 					: out	std_logic;

		i_scl_00					: in	std_logic;
		i_sda_00					: in	std_logic;
		o_scl_00					: out	std_logic;
		o_sda_00					: out	std_logic;
		o_I2C_mode_00				: out	std_logic_vector(1 downto 0);
		
		i_scl_01					: in	std_logic;
		i_sda_01					: in	std_logic;
		o_scl_01					: out	std_logic;
		o_sda_01					: out	std_logic;
		o_I2C_mode_01				: out	std_logic_vector(1 downto 0);

		i_adc_data_read				: in	std_logic_vector(15 downto 0);
		i_adc_channel				: in	std_logic_vector(4 downto 0);
		o_adc_addr					: out	std_logic_vector(6 downto 0);

		i_sem_stat					: in 	std_logic_vector(7 downto 0);
		i_arbiter_stat				: in 	std_logic_vector(7 downto 0);
		i_monitor_stat				: in 	std_logic_vector(7 downto 0);
		i_imem_stat					: in 	std_logic_vector(7 downto 0);
		i_dmem_stat					: in 	std_logic_vector(7 downto 0);
		i_bootrom_stat				: in 	std_logic_vector(7 downto 0);

		o_index						: out	std_logic_vector(7 downto 0);
		i_event						: in	std_logic_vector(31 downto 0);

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


	--! Declare the Monitor component
	component monitor is
	port (
		i_clk						: in	std_logic;
		i_reset_n					: in	std_logic;

		i_radpc_active_00           : in    std_logic;
		i_radpc_active_01           : in    std_logic;
		i_radpc_active_02           : in    std_logic;
		i_radpc_active_03           : in    std_logic;

		i_pc_00                     : in    std_logic_vector(31 downto 0);
		i_pc_01                     : in    std_logic_vector(31 downto 0);
		i_pc_02                     : in    std_logic_vector(31 downto 0);
		i_pc_03                     : in    std_logic_vector(31 downto 0);

		i_illegal_opcode_00         : in    std_logic;
		i_illegal_opcode_01         : in    std_logic;
		i_illegal_opcode_02         : in    std_logic;
		i_illegal_opcode_03         : in    std_logic;

		i_runtime_stat_00          	: in    std_logic_vector(31 downto 0);
		i_runtime_stat_01          	: in    std_logic_vector(31 downto 0);
		i_runtime_stat_02          	: in    std_logic_vector(31 downto 0);
		i_runtime_stat_03          	: in    std_logic_vector(31 downto 0);

		i_instr_00				   	: in    std_logic_vector(31 downto 0);
		i_instr_01				   	: in    std_logic_vector(31 downto 0);
		i_instr_02				   	: in    std_logic_vector(31 downto 0);
		i_instr_03				   	: in    std_logic_vector(31 downto 0);

		o_radpc_active            	: out   std_logic;
		o_pc                      	: out   std_logic_vector(31 downto 0);
		o_illegal_opcode          	: out   std_logic;
		o_runtime_stat            	: out   std_logic_vector(31 downto 0);
		o_instr				      	: out   std_logic_vector(31 downto 0);

		o_monitor_stat           	: out   std_logic_vector(7 downto 0)
	);
	end component;


	--! Declare the Voter component
	component voter is
	generic(
		g_VOTE_SIZE                 : integer       := 8
	);
	port(
		i_val_00                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
		i_val_01                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
		i_val_02                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
		i_val_03                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
	
		o_result                    : out   std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
		o_syndrome                  : out   std_logic_vector( 3 downto 0 )
	);
    end component;


	--! Declare the Arbiter component
	component arbiter is
	port(
		i_clk						: in	std_logic;
		i_reset_n					: in	std_logic;

		i_en 						: in	std_logic;

		i_pc_00                   	: in    std_logic_vector(31 downto 0);
		i_pc_01                   	: in    std_logic_vector(31 downto 0);
		i_pc_02                   	: in    std_logic_vector(31 downto 0);
		i_pc_03                   	: in    std_logic_vector(31 downto 0);

		i_reg_read_00				: in	std_logic_vector(31 downto 0);
		i_reg_read_01				: in	std_logic_vector(31 downto 0);
		i_reg_read_02				: in	std_logic_vector(31 downto 0);
		i_reg_read_03				: in	std_logic_vector(31 downto 0);

		o_reg_write					: out	std_logic_vector(31 downto 0);
		o_reg_addr					: out	std_logic_vector(4 downto 0);
		o_reg_rw					: out	std_logic;

		o_pc_repair_en          	: out   std_logic;
		o_pc 						: out   std_logic_vector(31 downto 0);

		o_arbiter_stat            	: out   std_logic_vector(7 downto 0)
	);
	end component;


	-- Scrubber component
	component  scrubber is
		generic (
			g_CLK_RATE      : integer       := 100_000_000;										-- Expected Input Clock Rate
			g_DATA_WIDTH	: integer		:= 0;												-- Data Width
			g_ADDR_WIDTH	: integer		:= 0;												-- Address Width
			g_RAM_DEPTH		: integer		:= 0												-- Depth of RAM Array
		);
		port (
			i_clk			: in	std_logic;													-- Input Clock
			i_reset_n		: in 	std_logic;													-- Reset (Active Low)

			i_en 			: in 	std_logic;													-- Enable

			i_data_rd_00	: in	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Read Data 00
			i_data_rd_01	: in	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Read Data 01
			i_data_rd_02	: in	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Read Data 02
			i_data_rd_03	: in	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Read Data 03

			o_data_wr		: out	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Write Data
			o_addr			: out	std_logic_vector((g_ADDR_WIDTH - 1) downto 0);				-- Scrubbed Memory Address
			o_rw 			: out	std_logic;													-- Scrubbed Memory Read/Write

			o_error			: out	std_logic;													-- Error Flag
			o_event			: out	std_logic_vector(31 downto 0);								-- Error Event

			o_status 		: out 	std_logic_vector(7 downto 0)								-- Scrubber Status Register
		);
	end component;


	-- Event Logger component
	component error_logger is
		port (
			i_clk					: in	std_logic;													-- Input Clock
			i_reset_n				: in 	std_logic;													-- Reset (Active Low)

			i_dmem_scrb_event		: in 	std_logic_vector(31 downto 0);								-- DMEM Scrubber Error Flag
			i_dmem_scrb_error		: in 	std_logic;													-- DMEM Scrubber Error Adress

			i_index					: in	std_logic_vector(7 downto 0);								-- Event Index
			o_event					: out	std_logic_vector(31 downto 0)								-- Event Data (Read)
		);
	end component;


	------------------------------------------------------------------------------------------------------------------------------------
	-- CONSTANTS
	------------------------------------------------------------------------------------------------------------------------------------ 

	constant c_CORE_ID_00					: integer           := 0;							--! Reach Core Tile 00 ID
	constant c_CORE_ID_01					: integer           := 1;							--! Reach Core Tile 01 ID
	constant c_CORE_ID_02					: integer           := 2;							--! Reach Core Tile 02 ID
	constant c_CORE_ID_03					: integer           := 3;							--! Reach Core Tile 03 ID


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNALS
	------------------------------------------------------------------------------------------------------------------------------------ 

    signal w_radpc_active_00                : std_logic;										-- RadPC Active Flag (Tile 00)
	signal w_radpc_active_01                : std_logic;										-- RadPC Active Flag (Tile 01)
	signal w_radpc_active_02                : std_logic;										-- RadPC Active Flag (Tile 02)
	signal w_radpc_active_03                : std_logic;										-- RadPC Active Flag (Tile 03)
	signal w_radpc_active              		: std_logic;                                        -- RadPC Active Flag (Voted)

    signal w_illegal_opcode_00             	: std_logic;										-- Illegal Opcode Flag (Tile 00)
	signal w_illegal_opcode_01             	: std_logic;										-- Illegal Opcode Flag (Tile 01)
	signal w_illegal_opcode_02             	: std_logic;										-- Illegal Opcode Flag (Tile 02)
	signal w_illegal_opcode_03             	: std_logic;										-- Illegal Opcode Flag (Tile 03)
	signal w_illegal_opcode					: std_logic;								        -- Illegal Opcode Flag (Voted)

    signal r_runtime_stat_00               	: std_logic_vector(31 downto 0);					-- Runtime Status (Tile 00)
	signal r_runtime_stat_01               	: std_logic_vector(31 downto 0);					-- Runtime Status (Tile 01)
	signal r_runtime_stat_02               	: std_logic_vector(31 downto 0);					-- Runtime Status (Tile 02)
	signal r_runtime_stat_03               	: std_logic_vector(31 downto 0);					-- Runtime Status (Tile 03)
	signal r_runtime_stat              		: std_logic_vector(31 downto 0);                    -- Runtime Status (Voted)

	signal r_pc_00                          : std_logic_vector(31 downto 0); 					-- Program Count (Tile 00)
	signal r_pc_01                          : std_logic_vector(31 downto 0); 					-- Program Count (Tile 01)
	signal r_pc_02                          : std_logic_vector(31 downto 0); 					-- Program Count (Tile 02)
	signal r_pc_03                          : std_logic_vector(31 downto 0); 					-- Program Count (Tile 03)
	signal r_pc                        		: std_logic_vector(31 downto 0);                    -- Program Count (Voted)

	signal r_instr_00				    	: std_logic_vector(31 downto 0);					-- Current Instruction (Tile 00)
	signal r_instr_01				    	: std_logic_vector(31 downto 0);					-- Current Instruction (Tile 01)
	signal r_instr_02				    	: std_logic_vector(31 downto 0);					-- Current Instruction (Tile 02)
	signal r_instr_03				    	: std_logic_vector(31 downto 0);					-- Current Instruction (Tile 03)
	signal r_instr                     		: std_logic_vector(31 downto 0);                    -- Instruction (Voted)


	signal w_arbiter_en_00                	: std_logic;                                        -- Arbiter Enable Flag (Tile 00)
	signal w_arbiter_en_01                	: std_logic;                                        -- Arbiter Enable Flag (Tile 01)
	signal w_arbiter_en_02                	: std_logic;                                        -- Arbiter Enable Flag (Tile 02)
	signal w_arbiter_en_03                	: std_logic;                                        -- Arbiter Enable Flag (Tile 03)
	signal w_arbiter_en						: std_logic;										-- Arbiter Enable Flag (Voted)

	signal r_reg_read_00					: std_logic_vector(31 downto 0);					-- Arbiter Register Read 00
	signal r_reg_read_01					: std_logic_vector(31 downto 0);					-- Arbiter Register Read 01
	signal r_reg_read_02					: std_logic_vector(31 downto 0);					-- Arbiter Register Read 02
	signal r_reg_read_03					: std_logic_vector(31 downto 0);					-- Arbiter Register Read 03

	signal r_reg_write						: std_logic_vector(31 downto 0);					-- Arbiter Register Write
	signal r_reg_addr						: std_logic_vector(4 downto 0);						-- Arbiter Register Address
	signal w_reg_rw							: std_logic;										-- Arbiter Register Read/Write


	signal r_monitor_stat					: std_logic_vector(7 downto 0);						-- Monitor Status
	signal r_arbiter_stat					: std_logic_vector(7 downto 0);						-- Arbiter Status
	signal r_imem_scrub_status				: std_logic_vector(7 downto 0);						-- IMEM Scrubber Status
	signal r_dmem_scrub_status				: std_logic_vector(7 downto 0);						-- DMEM Scrubber Status

	signal w_repair_en                 		: std_logic;			                            -- Repair Enable
	signal r_pc_repair_en					: std_logic;										-- Arbiter PC Repair Enable

	signal r_reg_D_wr_00                	: std_logic_vector(31 downto 0);					-- Register D Write (Tile 00)
	signal r_reg_D_wr_01                	: std_logic_vector(31 downto 0);					-- Register D Write (Tile 01)
	signal r_reg_D_wr_02                	: std_logic_vector(31 downto 0);					-- Register D Write (Tile 02)
	signal r_reg_D_wr_03                	: std_logic_vector(31 downto 0);					-- Register D Write (Tile 03)
	signal r_reg_D_wr                 		: std_logic_vector(31 downto 0);					-- Register D Write (Voted) 

	signal w_scrubber_en_00					: std_logic;										-- Scrubber Enable (Tile 00)
	signal w_scrubber_en_01					: std_logic;										-- Scrubber Enable (Tile 01)
	signal w_scrubber_en_02					: std_logic;										-- Scrubber Enable (Tile 02)
	signal w_scrubber_en_03					: std_logic;										-- Scrubber Enable (Tile 03)
	signal w_scrubber_en					: std_logic;										-- Scrubber Enable (Voted) 


	signal r_imem_scrub_read_00             : std_logic_vector(31 downto 0);					-- IMEM Scrubber Data Read (Tile 00)
	signal r_imem_scrub_read_01             : std_logic_vector(31 downto 0);					-- IMEM Scrubber Data Read (Tile 01)
	signal r_imem_scrub_read_02             : std_logic_vector(31 downto 0);					-- IMEM Scrubber Data Read (Tile 02)
	signal r_imem_scrub_read_03             : std_logic_vector(31 downto 0);					-- IMEM Scrubber Data Read (Tile 03)

	signal r_imem_scrub_addr				: std_logic_vector(31 downto 0);					-- IMEM Scrubber Memory Address
	signal w_imem_scrub_rw_en				: std_logic;										-- IMEM Scrubber Read/Write Enable
	signal r_imem_scrub_data_write			: std_logic_vector(31 downto 0);					-- IMEM Scrubber Data Write

	signal w_imem_error						: std_logic;										-- IMEM Scrubber Error Flag
	signal r_imem_error_addr				: std_logic_vector(31 downto 0);					-- IMEM Scrubber Error Address


	signal r_dmem_scrub_read_00             : std_logic_vector(31 downto 0);					-- DMEM Scrubber Data Read (Tile 00)
	signal r_dmem_scrub_read_01             : std_logic_vector(31 downto 0);					-- DMEM Scrubber Data Read (Tile 01)
	signal r_dmem_scrub_read_02             : std_logic_vector(31 downto 0);					-- DMEM Scrubber Data Read (Tile 02)
	signal r_dmem_scrub_read_03             : std_logic_vector(31 downto 0);					-- DMEM Scrubber Data Read (Tile 03)

	signal r_dmem_scrub_addr				: std_logic_vector(31 downto 0);					-- DMEM Scrubber Memory Address
	signal w_dmem_scrub_rw_en				: std_logic;										-- DMEM Scrubber Read/Write Enable
	signal r_dmem_scrub_data_write			: std_logic_vector(31 downto 0);					-- DMEM Scrubber Data Write

	signal w_dmem_error						: std_logic;										-- DMEM Scrubber Error Flag
	signal r_dmem_error_addr				: std_logic_vector(31 downto 0);					-- DMEM Scrubber Error Address


	signal r_index_00						: std_logic_vector(7 downto 0);						-- Event Logger Index (Tile 00)
	signal r_index_01						: std_logic_vector(7 downto 0);						-- Event Logger Index (Tile 01)
	signal r_index_02						: std_logic_vector(7 downto 0);						-- Event Logger Index (Tile 02)
	signal r_index_03						: std_logic_vector(7 downto 0);						-- Event Logger Index (Tile 03)

	signal r_index							: std_logic_vector(7 downto 0);						-- Event Logger Index (Voted))

	signal r_event							: std_logic_vector(31 downto 0);					-- Event (Read)


	signal r_port_A_sel_00					: std_logic_vector(31 downto 0);					-- Port A Select (Tile 00)
	signal r_port_A_sel_01					: std_logic_vector(31 downto 0);					-- Port A Select (Tile 01)
	signal r_port_A_sel_02					: std_logic_vector(31 downto 0);					-- Port A Select (Tile 02)
	signal r_port_A_sel_03					: std_logic_vector(31 downto 0);					-- Port A Select (Tile 03)

	signal r_port_B_sel_00					: std_logic_vector(31 downto 0);					-- Port B Select (Tile 00)
	signal r_port_B_sel_01					: std_logic_vector(31 downto 0);					-- Port B Select (Tile 01)
	signal r_port_B_sel_02					: std_logic_vector(31 downto 0);					-- Port B Select (Tile 02)
	signal r_port_B_sel_03					: std_logic_vector(31 downto 0);					-- Port B Select (Tile 03)

	signal r_port_C_sel_00					: std_logic_vector(31 downto 0);					-- Port C Select (Tile 00)
	signal r_port_C_sel_01					: std_logic_vector(31 downto 0);					-- Port C Select (Tile 01)
	signal r_port_C_sel_02					: std_logic_vector(31 downto 0);					-- Port C Select (Tile 02)
	signal r_port_C_sel_03					: std_logic_vector(31 downto 0);					-- Port C Select (Tile 03)


	signal r_gpio_00_out_00					: std_logic_vector(31 downto 0);					-- GPIO 00 Output (Tile 00)
	signal r_gpio_00_out_01					: std_logic_vector(31 downto 0);					-- GPIO 00 Output (Tile 01)
	signal r_gpio_00_out_02					: std_logic_vector(31 downto 0);					-- GPIO 00 Output (Tile 02)
	signal r_gpio_00_out_03					: std_logic_vector(31 downto 0);					-- GPIO 00 Output (Tile 03)					

	signal r_gpio_01_out_00					: std_logic_vector(31 downto 0);					-- GPIO 01 Output (Tile 00)
	signal r_gpio_01_out_01					: std_logic_vector(31 downto 0);					-- GPIO 01 Output (Tile 01)
	signal r_gpio_01_out_02					: std_logic_vector(31 downto 0);					-- GPIO 01 Output (Tile 02)
	signal r_gpio_01_out_03					: std_logic_vector(31 downto 0);					-- GPIO 01 Output (Tile 03)

	signal r_gpio_02_out_00					: std_logic_vector(31 downto 0);					-- GPIO 02 Output (Tile 00)
	signal r_gpio_02_out_01					: std_logic_vector(31 downto 0);					-- GPIO 02 Output (Tile 01)
	signal r_gpio_02_out_02					: std_logic_vector(31 downto 0);					-- GPIO 02 Output (Tile 02)
	signal r_gpio_02_out_03					: std_logic_vector(31 downto 0);					-- GPIO 02 Output (Tile 03)

	signal r_gpio_00_dir_00					: std_logic_vector(31 downto 0);					-- GPIO 00 Direction (Tile 00)
	signal r_gpio_00_dir_01					: std_logic_vector(31 downto 0);					-- GPIO 00 Direction (Tile 01)
	signal r_gpio_00_dir_02					: std_logic_vector(31 downto 0);					-- GPIO 00 Direction (Tile 02)
	signal r_gpio_00_dir_03					: std_logic_vector(31 downto 0);					-- GPIO 00 Direction (Tile 03)					

	signal r_gpio_01_dir_00					: std_logic_vector(31 downto 0);					-- GPIO 01 Direction (Tile 00)
	signal r_gpio_01_dir_01					: std_logic_vector(31 downto 0);					-- GPIO 01 Direction (Tile 01)
	signal r_gpio_01_dir_02					: std_logic_vector(31 downto 0);					-- GPIO 01 Direction (Tile 02)
	signal r_gpio_01_dir_03					: std_logic_vector(31 downto 0);					-- GPIO 01 Direction (Tile 03)

	signal r_gpio_02_dir_00					: std_logic_vector(31 downto 0);					-- GPIO 02 Direction (Tile 00)
	signal r_gpio_02_dir_01					: std_logic_vector(31 downto 0);					-- GPIO 02 Direction (Tile 01)
	signal r_gpio_02_dir_02					: std_logic_vector(31 downto 0);					-- GPIO 02 Direction (Tile 02)
	signal r_gpio_02_dir_03					: std_logic_vector(31 downto 0);					-- GPIO 02 Direction (Tile 03)


	signal r_uart_00_tx_00					: std_logic;										-- UART 00 Transmit (Tile 00)
	signal r_uart_00_tx_01					: std_logic;										-- UART 00 Transmit (Tile 01)
	signal r_uart_00_tx_02					: std_logic;										-- UART 00 Transmit (Tile 02)
	signal r_uart_00_tx_03					: std_logic;										-- UART 00 Transmit (Tile 03)

	signal r_uart_01_tx_00					: std_logic;										-- UART 01 Transmit (Tile 00)
	signal r_uart_01_tx_01					: std_logic;										-- UART 01 Transmit (Tile 01)
	signal r_uart_01_tx_02					: std_logic;										-- UART 01 Transmit (Tile 02)
	signal r_uart_01_tx_03					: std_logic;										-- UART 01 Transmit (Tile 03)

	signal r_uart_02_tx_00					: std_logic;										-- UART 02 Transmit (Tile 00)
	signal r_uart_02_tx_01					: std_logic;										-- UART 02 Transmit (Tile 01)
	signal r_uart_02_tx_02					: std_logic;										-- UART 02 Transmit (Tile 02)
	signal r_uart_02_tx_03					: std_logic;										-- UART 02 Transmit (Tile 03)

	signal r_uart_03_tx_00					: std_logic;										-- UART 03 Transmit (Tile 00)
	signal r_uart_03_tx_01					: std_logic;										-- UART 03 Transmit (Tile 01)
	signal r_uart_03_tx_02					: std_logic;										-- UART 03 Transmit (Tile 02)
	signal r_uart_03_tx_03					: std_logic;										-- UART 03 Transmit (Tile 03)


	signal r_uart_00_en_00					: std_logic;										-- UART 00 Enable (Tile 00)
	signal r_uart_00_en_01					: std_logic;										-- UART 00 Enable (Tile 01)
	signal r_uart_00_en_02					: std_logic;										-- UART 00 Enable (Tile 02)
	signal r_uart_00_en_03					: std_logic;										-- UART 00 Enable (Tile 03)

	signal r_uart_01_en_00					: std_logic;										-- UART 01 Enable (Tile 00)
	signal r_uart_01_en_01					: std_logic;										-- UART 01 Enable (Tile 01)
	signal r_uart_01_en_02					: std_logic;										-- UART 01 Enable (Tile 02)
	signal r_uart_01_en_03					: std_logic;										-- UART 01 Enable (Tile 03)

	signal r_uart_02_en_00					: std_logic;										-- UART 02 Enable (Tile 00)
	signal r_uart_02_en_01					: std_logic;										-- UART 02 Enable (Tile 01)
	signal r_uart_02_en_02					: std_logic;										-- UART 02 Enable (Tile 02)
	signal r_uart_02_en_03					: std_logic;										-- UART 02 Enable (Tile 03)

	signal r_uart_03_en_00					: std_logic;										-- UART 03 Enable (Tile 00)
	signal r_uart_03_en_01					: std_logic;										-- UART 03 Enable (Tile 01)
	signal r_uart_03_en_02					: std_logic;										-- UART 03 Enable (Tile 02)
	signal r_uart_03_en_03					: std_logic;										-- UART 03 Enable (Tile 03)


    signal w_scl_00_o_00    	           	: std_logic;										-- I2C 00 Serial Clock (SCL) Output (Tile 00)
	signal w_scl_00_o_01    	           	: std_logic;										-- I2C 00 Serial Clock (SCL) Output (Tile 01)
	signal w_scl_00_o_02    	           	: std_logic;										-- I2C 00 Serial Clock (SCL) Output (Tile 02)
	signal w_scl_00_o_03    	           	: std_logic;										-- I2C 00 Serial Clock (SCL) Output (Tile 03)

    signal w_sda_00_o_00    	           	: std_logic;										-- I2C 00 Serial Data (SDA) Output (Tile 00)
	signal w_sda_00_o_01    	           	: std_logic;										-- I2C 00 Serial Data (SDA) Output (Tile 01)
	signal w_sda_00_o_02    	           	: std_logic;										-- I2C 00 Serial Data (SDA) Output (Tile 02)
	signal w_sda_00_o_03    	           	: std_logic;										-- I2C 00 Serial Data (SDA) Output (Tile 03)

    signal w_i2c_00_mode_00					: std_logic_vector(1 downto 0);						-- I2C 00 Master/Slave Mode Control (Tile 00)
	signal w_i2c_00_mode_01					: std_logic_vector(1 downto 0);						-- I2C 00 Master/Slave Mode Control (Tile 01)
	signal w_i2c_00_mode_02					: std_logic_vector(1 downto 0);						-- I2C 00 Master/Slave Mode Control (Tile 02)
	signal w_i2c_00_mode_03					: std_logic_vector(1 downto 0);						-- I2C 00 Master/Slave Mode Control (Tile 03)

	signal w_scl_01_o_00    	           	: std_logic;										-- I2C 01 Serial Clock (SCL) Output (Tile 00)
	signal w_scl_01_o_01    	           	: std_logic;										-- I2C 01 Serial Clock (SCL) Output (Tile 01)
	signal w_scl_01_o_02    	           	: std_logic;										-- I2C 01 Serial Clock (SCL) Output (Tile 02)
	signal w_scl_01_o_03    	           	: std_logic;										-- I2C 01 Serial Clock (SCL) Output (Tile 03)

	signal w_sda_01_o_00    	           	: std_logic;										-- I2C 01 Serial Data (SDA) Output (Tile 00)
	signal w_sda_01_o_01    	           	: std_logic;										-- I2C 01 Serial Data (SDA) Output (Tile 01)
	signal w_sda_01_o_02    	           	: std_logic;										-- I2C 01 Serial Data (SDA) Output (Tile 02)
	signal w_sda_01_o_03    	           	: std_logic;										-- I2C 01 Serial Data (SDA) Output (Tile 03)

	signal w_i2c_01_mode_00					: std_logic_vector(1 downto 0);						-- I2C 01 Master/Slave Mode Control (Tile 00)
	signal w_i2c_01_mode_01					: std_logic_vector(1 downto 0);						-- I2C 01 Master/Slave Mode Control (Tile 01)
	signal w_i2c_01_mode_02					: std_logic_vector(1 downto 0);						-- I2C 01 Master/Slave Mode Control (Tile 02)
	signal w_i2c_01_mode_03					: std_logic_vector(1 downto 0);						-- I2C 01 Master/Slave Mode Control (Tile 03)


    signal w_miso_boot_00					: std_logic;										-- BOOT MISO (Tile 00)
	signal w_miso_boot_01					: std_logic;										-- BOOT MISO (Tile 01)
	signal w_miso_boot_02					: std_logic;										-- BOOT MISO (Tile 02)
	signal w_miso_boot_03					: std_logic;										-- BOOT MISO (Tile 03)

    signal w_mosi_boot_00					: std_logic;										-- BOOT MOSI (Tile 00)
	signal w_mosi_boot_01					: std_logic;										-- BOOT MOSI (Tile 01)
	signal w_mosi_boot_02					: std_logic;										-- BOOT MOSI (Tile 02)
	signal w_mosi_boot_03					: std_logic;										-- BOOT MOSI (Tile 03)

    signal w_sclk_boot_00					: std_logic;										-- BOOT SCLK (Tile 00)
	signal w_sclk_boot_01					: std_logic;										-- BOOT SCLK (Tile 01)
	signal w_sclk_boot_02					: std_logic;										-- BOOT SCLK (Tile 02)
	signal w_sclk_boot_03					: std_logic;										-- BOOT SCLK (Tile 03)

    signal w_cs_boot_00						: std_logic;										-- BOOT CS (Tile 00)
	signal w_cs_boot_01						: std_logic;										-- BOOT CS (Tile 01)
	signal w_cs_boot_02						: std_logic;										-- BOOT CS (Tile 02)
	signal w_cs_boot_03						: std_logic;										-- BOOT CS (Tile 03)

    signal w_boot_mode_00					: std_logic;										-- BOOT Mode (Tile 00)
	signal w_boot_mode_01					: std_logic;										-- BOOT Mode (Tile 01)
	signal w_boot_mode_02					: std_logic;										-- BOOT Mode (Tile 02)
	signal w_boot_mode_03					: std_logic;										-- BOOT Mode (Tile 03)


    signal w_mosi_flash_00					: std_logic;										-- NOR Flash MOSI (Tile 00)
	signal w_mosi_flash_01					: std_logic;										-- NOR Flash MOSI (Tile 01)
	signal w_mosi_flash_02					: std_logic;										-- NOR Flash MOSI (Tile 02)
	signal w_mosi_flash_03					: std_logic;										-- NOR Flash MOSI (Tile 03)

    signal w_sclk_flash_00					: std_logic;										-- NOR Flash SCLK (Tile 00)
	signal w_sclk_flash_01					: std_logic;										-- NOR Flash SCLK (Tile 01)
	signal w_sclk_flash_02					: std_logic;										-- NOR Flash SCLK (Tile 02)
	signal w_sclk_flash_03					: std_logic;										-- NOR Flash SCLK (Tile 03)

    signal w_cs_flash_00					: std_logic;										-- NOR Flash CS (Tile 00)
	signal w_cs_flash_01					: std_logic;										-- NOR Flash CS (Tile 01)
	signal w_cs_flash_02					: std_logic;										-- NOR Flash CS (Tile 02)
	signal w_cs_flash_03					: std_logic;										-- NOR Flash CS (Tile 03)


	signal w_miso_00_o_00					: std_logic;										-- SPI 00 Master In Slave Out (MISO) (Tile 00)
	signal w_miso_00_o_01					: std_logic;										-- SPI 00 Master In Slave Out (MISO) (Tile 01)
	signal w_miso_00_o_02					: std_logic;										-- SPI 00 Master In Slave Out (MISO) (Tile 02)
	signal w_miso_00_o_03					: std_logic;										-- SPI 00 Master In Slave Out (MISO) (Tile 03)

	signal w_mosi_00_o_00					: std_logic;										-- SPI 00 Master Out Slave In (MOSI) (Tile 00)
	signal w_mosi_00_o_01					: std_logic;										-- SPI 00 Master Out Slave In (MOSI) (Tile 01)
	signal w_mosi_00_o_02					: std_logic;										-- SPI 00 Master Out Slave In (MOSI) (Tile 02)
	signal w_mosi_00_o_03					: std_logic;										-- SPI 00 Master Out Slave In (MOSI) (Tile 03)

	signal w_sclk_00_o_00					: std_logic;										-- SPI 00 Serial Clock (SCLK) (Tile 00)
	signal w_sclk_00_o_01					: std_logic;										-- SPI 00 Serial Clock (SCLK) (Tile 01)
	signal w_sclk_00_o_02					: std_logic;										-- SPI 00 Serial Clock (SCLK) (Tile 02)
	signal w_sclk_00_o_03					: std_logic;										-- SPI 00 Serial Clock (SCLK) (Tile 03)

	signal w_cs_00_o_00						: std_logic;										-- SPI 00 Chip Select (Tile 00)
	signal w_cs_00_o_01						: std_logic;										-- SPI 00 Chip Select (Tile 01)
	signal w_cs_00_o_02						: std_logic;										-- SPI 00 Chip Select (Tile 02)
	signal w_cs_00_o_03						: std_logic;										-- SPI 00 Chip Select (Tile 03)

	signal w_spi_00_mode_00                 : std_logic;										-- SPI 00 Mode Select (Tile 00)
	signal w_spi_00_mode_01                 : std_logic;										-- SPI 00 Mode Select (Tile 01)
	signal w_spi_00_mode_02                 : std_logic;										-- SPI 00 Mode Select (Tile 02)
	signal w_spi_00_mode_03                 : std_logic;										-- SPI 00 Mode Select (Tile 03)

	signal w_miso_01_o_00					: std_logic;										-- SPI 01 Master In Slave Out (MISO) (Tile 00)
	signal w_miso_01_o_01					: std_logic;										-- SPI 01 Master In Slave Out (MISO) (Tile 01)
	signal w_miso_01_o_02					: std_logic;										-- SPI 01 Master In Slave Out (MISO) (Tile 02)
	signal w_miso_01_o_03					: std_logic;										-- SPI 01 Master In Slave Out (MISO) (Tile 03)

	signal w_mosi_01_o_00					: std_logic;										-- SPI 01 Master Out Slave In (MOSI) (Tile 00)
	signal w_mosi_01_o_01					: std_logic;										-- SPI 01 Master Out Slave In (MOSI) (Tile 01)
	signal w_mosi_01_o_02					: std_logic;										-- SPI 01 Master Out Slave In (MOSI) (Tile 02)
	signal w_mosi_01_o_03					: std_logic;										-- SPI 01 Master Out Slave In (MOSI) (Tile 03)

	signal w_sclk_01_o_00					: std_logic;										-- SPI 01 Serial Clock (SCLK) (Tile 00)
	signal w_sclk_01_o_01					: std_logic;										-- SPI 01 Serial Clock (SCLK) (Tile 01)
	signal w_sclk_01_o_02					: std_logic;										-- SPI 01 Serial Clock (SCLK) (Tile 02)
	signal w_sclk_01_o_03					: std_logic;										-- SPI 01 Serial Clock (SCLK) (Tile 03)

	signal w_cs_01_o_00						: std_logic;										-- SPI 01 Chip Select (Tile 00)
	signal w_cs_01_o_01						: std_logic;										-- SPI 01 Chip Select (Tile 01)
	signal w_cs_01_o_02						: std_logic;										-- SPI 01 Chip Select (Tile 02)
	signal w_cs_01_o_03						: std_logic;										-- SPI 01 Chip Select (Tile 03)

	signal w_spi_01_mode_00                 : std_logic;										-- SPI 01 Mode Select (Tile 00)
	signal w_spi_01_mode_01                 : std_logic;										-- SPI 01 Mode Select (Tile 01)
	signal w_spi_01_mode_02                 : std_logic;										-- SPI 01 Mode Select (Tile 02)
	signal w_spi_01_mode_03                 : std_logic;										-- SPI 01 Mode Select (Tile 03)

	signal w_miso_02_o_00					: std_logic;										-- SPI 02 Master In Slave Out (MISO) (Tile 00)
	signal w_miso_02_o_01					: std_logic;										-- SPI 02 Master In Slave Out (MISO) (Tile 01)
	signal w_miso_02_o_02					: std_logic;										-- SPI 02 Master In Slave Out (MISO) (Tile 02)
	signal w_miso_02_o_03					: std_logic;										-- SPI 02 Master In Slave Out (MISO) (Tile 03)

	signal w_mosi_02_o_00					: std_logic;										-- SPI 02 Master Out Slave In (MOSI) (Tile 00)
	signal w_mosi_02_o_01					: std_logic;										-- SPI 02 Master Out Slave In (MOSI) (Tile 01)
	signal w_mosi_02_o_02					: std_logic;										-- SPI 02 Master Out Slave In (MOSI) (Tile 02)
	signal w_mosi_02_o_03					: std_logic;										-- SPI 02 Master Out Slave In (MOSI) (Tile 03)

	signal w_sclk_02_o_00					: std_logic;										-- SPI 02 Serial Clock (SCLK) (Tile 00)
	signal w_sclk_02_o_01					: std_logic;										-- SPI 02 Serial Clock (SCLK) (Tile 01)
	signal w_sclk_02_o_02					: std_logic;										-- SPI 02 Serial Clock (SCLK) (Tile 02)
	signal w_sclk_02_o_03					: std_logic;										-- SPI 02 Serial Clock (SCLK) (Tile 03)

	signal w_cs_02_o_00						: std_logic;										-- SPI 02 Chip Select (Tile 00)
	signal w_cs_02_o_01						: std_logic;										-- SPI 02 Chip Select (Tile 01)
	signal w_cs_02_o_02						: std_logic;										-- SPI 02 Chip Select (Tile 02)
	signal w_cs_02_o_03						: std_logic;										-- SPI 02 Chip Select (Tile 03)

	signal w_spi_02_mode_00                 : std_logic;										-- SPI 02 Mode Select (Tile 00)
	signal w_spi_02_mode_01                 : std_logic;										-- SPI 02 Mode Select (Tile 01)
	signal w_spi_02_mode_02                 : std_logic;										-- SPI 02 Mode Select (Tile 02)
	signal w_spi_02_mode_03                 : std_logic;										-- SPI 02 Mode Select (Tile 03)

	signal w_miso_03_o_00					: std_logic;										-- SPI 03 Master In Slave Out (MISO) (Tile 00)
	signal w_miso_03_o_01					: std_logic;										-- SPI 03 Master In Slave Out (MISO) (Tile 01)
	signal w_miso_03_o_02					: std_logic;										-- SPI 03 Master In Slave Out (MISO) (Tile 02)
	signal w_miso_03_o_03					: std_logic;										-- SPI 03 Master In Slave Out (MISO) (Tile 03)

	signal w_mosi_03_o_00					: std_logic;										-- SPI 03 Master Out Slave In (MOSI) (Tile 00)
	signal w_mosi_03_o_01					: std_logic;										-- SPI 03 Master Out Slave In (MOSI) (Tile 01)
	signal w_mosi_03_o_02					: std_logic;										-- SPI 03 Master Out Slave In (MOSI) (Tile 02)
	signal w_mosi_03_o_03					: std_logic;										-- SPI 03 Master Out Slave In (MOSI) (Tile 03)

	signal w_sclk_03_o_00					: std_logic;										-- SPI 03 Serial Clock (SCLK) (Tile 00)
	signal w_sclk_03_o_01					: std_logic;										-- SPI 03 Serial Clock (SCLK) (Tile 01)
	signal w_sclk_03_o_02					: std_logic;										-- SPI 03 Serial Clock (SCLK) (Tile 02)
	signal w_sclk_03_o_03					: std_logic;										-- SPI 03 Serial Clock (SCLK) (Tile 03)

	signal w_cs_03_o_00						: std_logic;										-- SPI 03 Chip Select (Tile 00)
	signal w_cs_03_o_01						: std_logic;										-- SPI 03 Chip Select (Tile 01)
	signal w_cs_03_o_02						: std_logic;										-- SPI 03 Chip Select (Tile 02)
	signal w_cs_03_o_03						: std_logic;										-- SPI 03 Chip Select (Tile 03)

	signal w_spi_03_mode_00                 : std_logic;										-- SPI 03 Mode Select (Tile 00)
	signal w_spi_03_mode_01                 : std_logic;										-- SPI 03 Mode Select (Tile 01)
	signal w_spi_03_mode_02                 : std_logic;										-- SPI 03 Mode Select (Tile 02)
	signal w_spi_03_mode_03                 : std_logic;										-- SPI 03 Mode Select (Tile 03)


	signal r_hwa_write_00_00				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 00)
	signal r_hwa_write_00_01				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 01)
	signal r_hwa_write_00_02				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 02)
	signal r_hwa_write_00_03				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 03)

	signal r_hwa_write_01_00				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 00)
	signal r_hwa_write_01_01				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 01)
	signal r_hwa_write_01_02				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 02)
	signal r_hwa_write_01_03				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 03)

	signal r_hwa_write_02_00				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 00)
	signal r_hwa_write_02_01				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 01)
	signal r_hwa_write_02_02				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 02)
	signal r_hwa_write_02_03				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 03)

	signal r_hwa_write_03_00				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 00)
	signal r_hwa_write_03_01				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 01)
	signal r_hwa_write_03_02				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 02)
	signal r_hwa_write_03_03				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 03)

	signal r_hwa_write_04_00				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 00)
	signal r_hwa_write_04_01				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 01)
	signal r_hwa_write_04_02				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 02)
	signal r_hwa_write_04_03				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 03)

	signal r_hwa_write_05_00				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 00)
	signal r_hwa_write_05_01				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 01)
	signal r_hwa_write_05_02				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 02)
	signal r_hwa_write_05_03				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 03)

	signal r_hwa_write_06_00				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 00)
	signal r_hwa_write_06_01				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 01)
	signal r_hwa_write_06_02				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 02)
	signal r_hwa_write_06_03				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 03)

	signal r_hwa_write_07_00				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 00)
	signal r_hwa_write_07_01				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 01)
	signal r_hwa_write_07_02				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 02)
	signal r_hwa_write_07_03				: std_logic_vector(31 downto 0);					-- Hardware Accelerator Write Register 00 (Tile 03)

	signal r_hwa_ctrl_00					: std_logic_vector(7 downto 0);						-- Hardware Accelerator Control (Tile 00)
	signal r_hwa_ctrl_01					: std_logic_vector(7 downto 0);						-- Hardware Accelerator Control (Tile 01)
	signal r_hwa_ctrl_02					: std_logic_vector(7 downto 0);						-- Hardware Accelerator Control (Tile 02)
	signal r_hwa_ctrl_03					: std_logic_vector(7 downto 0);						-- Hardware Accelerator Control (Tile 03)


	signal w_pr_decouple_00					: std_logic;										-- PR Decouple (Tile 00)
	signal w_pr_decouple_01					: std_logic;										-- PR Decouple (Tile 01)
	signal w_pr_decouple_02					: std_logic;										-- PR Decouple (Tile 02)
	signal w_pr_decouple_03					: std_logic;										-- PR Decouple (Tile 03)


	-- -- ADC
	-- signal r_adc_addr_00					: std_logic_vector(6 downto 0);
	-- signal r_adc_addr_01					: std_logic_vector(6 downto 0);
	-- signal r_adc_addr_02					: std_logic_vector(6 downto 0);
	-- signal r_adc_addr_03					: std_logic_vector(6 downto 0);	


begin
    
    ------------------------------------------------------------------------------------------------------------------------------------
	-- PROCESSOR CORE INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------
    
	--! Instantiated Reach Core 00
    REACH_00 : reach_core
	generic map(
		g_CORE_ID                   		=> c_CORE_ID_00,
		g_CLK_RATE                			=> g_CLK_RATE,
		g_OBFUSCATION_OFFSET				=> c_OBFUSCATION_00,
		g_CORRUPTION						=> 0
	)
    port map(
        i_clk						        => i_clk,
        i_reset_n					        => i_reset_n,

		i_error_detect                 		=> w_repair_en,
		o_arbiter_en                		=> w_arbiter_en_00,
		o_scrubber_en               		=> w_scrubber_en_00,

		o_pc                        		=> r_pc_00,

        i_bootload_en                       => i_bootload_en,
		o_radpc_active						=> w_radpc_active_00,
		o_illegal_opcode					=> w_illegal_opcode_00,
        o_instr                       		=> r_instr_00,
        o_runtime_stat                      => r_runtime_stat_00,

		i_sem_status						=> i_sem_status,

		i_pc_repair_en              		=> r_pc_repair_en,
		i_pc_repair                 		=> r_pc,

		o_reg_D_wr                  		=> r_reg_D_wr_00,
		i_reg_D_wr                  		=> r_reg_D_wr,

		o_reg_read				    		=> r_reg_read_00,
		i_reg_write							=> r_reg_write,
		i_reg_addr							=> r_reg_addr,
		i_reg_rw							=> w_reg_rw,

		i_imem_scrb_addr					=> r_imem_scrub_addr,
		i_imem_scrb_rw_en					=> w_imem_scrub_rw_en,
		i_imem_scrb_data					=> r_imem_scrub_data_write,
		o_imem_scrb_data					=> r_imem_scrub_read_00,

		i_dmem_scrb_addr					=> r_dmem_scrub_addr,
		i_dmem_scrb_rw_en					=> w_dmem_scrub_rw_en,
		i_dmem_scrb_data					=> r_dmem_scrub_data_write,
		o_dmem_scrb_data					=> r_dmem_scrub_read_00,

		o_port_A_sel						=> r_port_A_sel_00,
		o_port_B_sel						=> r_port_B_sel_00,
		o_port_C_sel						=> r_port_C_sel_00,

		i_gpio_00_in						=> i_gpio_00_in,
		o_gpio_00_out						=> r_gpio_00_out_00,
        o_gpio_00_dir                       => r_gpio_00_dir_00,
	
		i_gpio_01_in						=> i_gpio_01_in,
		o_gpio_01_out						=> r_gpio_01_out_00,
        o_gpio_01_dir                       => r_gpio_01_dir_00,

		i_gpio_02_in						=> i_gpio_02_in,
		o_gpio_02_out						=> r_gpio_02_out_00,
        o_gpio_02_dir                       => r_gpio_02_dir_00,

        i_uart_00_rx				        => i_uart_00_rx,    
        o_uart_00_tx				        => r_uart_00_tx_00,    
        o_uart_00_en                        => r_uart_00_en_00,    

        i_uart_01_rx				        => i_uart_01_rx,
        o_uart_01_tx				        => r_uart_01_tx_00,
        o_uart_01_en                        => r_uart_01_en_00,

        i_uart_02_rx				        => i_uart_02_rx,    
        o_uart_02_tx				        => r_uart_02_tx_00,    
        o_uart_02_en                        => r_uart_02_en_00,    

        i_uart_03_rx				        => i_uart_03_rx,
        o_uart_03_tx				        => r_uart_03_tx_00,
        o_uart_03_en                        => r_uart_03_en_00,

        i_miso_boot					        => i_miso_boot,
        o_miso_boot					        => w_miso_boot_00,
        i_mosi_boot					        => i_mosi_boot,
        o_mosi_boot					        => w_mosi_boot_00,
        i_sclk_boot					        => i_sclk_boot,
        o_sclk_boot					        => w_sclk_boot_00,
        i_cs_boot 					        => i_cs_boot,
        o_cs_boot 					        => w_cs_boot_00,
        o_boot_mode					        => w_boot_mode_00,

        i_miso_00					        => i_miso_00,
        o_miso_00					        => w_miso_00_o_00,
        i_mosi_00					        => i_mosi_00,
        o_mosi_00					        => w_mosi_00_o_00,
        i_sclk_00					        => i_sclk_00,
        o_sclk_00					        => w_sclk_00_o_00,
        i_cs_00						        => i_cs_00,
        o_cs_00						        => w_cs_00_o_00,
        o_spi_mode_00                       => w_spi_00_mode_00,

        i_miso_01					        => i_miso_01,
        o_miso_01					        => w_miso_01_o_00,
        i_mosi_01					        => i_mosi_01,
        o_mosi_01					        => w_mosi_01_o_00,
        i_sclk_01					        => i_sclk_01,
        o_sclk_01					        => w_sclk_01_o_00,
        i_cs_01						        => i_cs_01,
        o_cs_01						        => w_cs_01_o_00,
        o_spi_mode_01                       => w_spi_01_mode_00,

        i_miso_02					        => i_miso_02,
        o_miso_02					        => w_miso_02_o_00,
        i_mosi_02					        => i_mosi_02,
        o_mosi_02					        => w_mosi_02_o_00,
        i_sclk_02					        => i_sclk_02,
        o_sclk_02					        => w_sclk_02_o_00,
        i_cs_02						        => i_cs_02,
        o_cs_02						        => w_cs_02_o_00,
        o_spi_mode_02                       => w_spi_02_mode_00,

        i_miso_03					        => i_miso_03,
        o_miso_03					        => w_miso_03_o_00,
        i_mosi_03					        => i_mosi_03,
        o_mosi_03					        => w_mosi_03_o_00,
        i_sclk_03					        => i_sclk_03,
        o_sclk_03					        => w_sclk_03_o_00,
        i_cs_03						        => i_cs_03,
        o_cs_03						        => w_cs_03_o_00,
        o_spi_mode_03                       => w_spi_03_mode_00,

		i_miso_flash						=> i_miso_flash,
		o_mosi_flash						=> w_mosi_flash_00,
		o_sclk_flash						=> w_sclk_flash_00,
		o_cs_flash 							=> w_cs_flash_00,

        i_scl_00							=> i_scl_00,     
		i_sda_00							=> i_sda_00,     
		o_scl_00							=> w_scl_00_o_00,     
		o_sda_00							=> w_sda_00_o_00,     
		o_i2c_mode_00						=> w_i2c_00_mode_00,

		i_scl_01							=> i_scl_01,        
		i_sda_01							=> i_sda_01,        
		o_scl_01							=> w_scl_01_o_00,        
		o_sda_01							=> w_sda_01_o_00,        
		o_i2c_mode_01						=> w_i2c_01_mode_00,

		i_adc_data_read				        => (others => '0'),
		i_adc_channel				        => (others => '0'),
		o_adc_addr					        => open,

		i_sem_stat							=> i_sem_status,
		i_arbiter_stat						=> r_arbiter_stat,
		i_monitor_stat						=> r_monitor_stat,
		i_imem_stat							=> r_imem_scrub_status,
		i_dmem_stat							=> r_dmem_scrub_status,
		i_bootrom_stat						=> r_imem_scrub_status,

		o_index								=> r_index_00,
		i_event								=> r_event,

		i_hwa_id							=> i_hwa_id,

        i_hwa_read_00				        => i_hwa_read_00,
        i_hwa_read_01				        => i_hwa_read_01,
        i_hwa_read_02				        => i_hwa_read_02,
        i_hwa_read_03				        => i_hwa_read_03,
        i_hwa_read_04				        => i_hwa_read_04,
        i_hwa_read_05				        => i_hwa_read_05,
        i_hwa_read_06				        => i_hwa_read_06,
        i_hwa_read_07				        => i_hwa_read_07,

        o_hwa_write_00				        => r_hwa_write_00_00,
        o_hwa_write_01				        => r_hwa_write_01_00,
        o_hwa_write_02				        => r_hwa_write_02_00,
        o_hwa_write_03				        => r_hwa_write_03_00,
        o_hwa_write_04				        => r_hwa_write_04_00,
        o_hwa_write_05				        => r_hwa_write_05_00,
        o_hwa_write_06				        => r_hwa_write_06_00,
        o_hwa_write_07				        => r_hwa_write_07_00,

		i_hwa_stat							=> i_hwa_stat,
		o_hwa_ctrl							=> r_hwa_ctrl_00,

		o_pr_decouple						=> w_pr_decouple_00
    );


	--! Instantiate Reach Core 01
    REACH_01 : reach_core
	generic map(
		g_CORE_ID                   		=> c_CORE_ID_01,
		g_CLK_RATE                			=> g_CLK_RATE,
		g_OBFUSCATION_OFFSET				=> c_OBFUSCATION_01,
		g_CORRUPTION						=> 0
	)
    port map(
        i_clk						        => i_clk,
        i_reset_n					        => i_reset_n,

		i_error_detect                 		=> w_repair_en,
		o_arbiter_en                		=> w_arbiter_en_01,
		o_scrubber_en               		=> w_scrubber_en_01,

		o_pc                        		=> r_pc_01,

        i_bootload_en                       => i_bootload_en,
		o_radpc_active						=> w_radpc_active_01,
		o_illegal_opcode					=> w_illegal_opcode_01,
        o_instr                       		=> r_instr_01,
        o_runtime_stat                      => r_runtime_stat_01,

		i_sem_status						=> i_sem_status,

		i_pc_repair_en              		=> r_pc_repair_en,
		i_pc_repair                 		=> r_pc,

		o_reg_D_wr                  		=> r_reg_D_wr_01,
		i_reg_D_wr                  		=> r_reg_D_wr,

		o_reg_read				    		=> r_reg_read_01,
		i_reg_write							=> r_reg_write,
		i_reg_addr							=> r_reg_addr,
		i_reg_rw							=> w_reg_rw,

		i_imem_scrb_addr					=> r_imem_scrub_addr,
		i_imem_scrb_rw_en					=> w_imem_scrub_rw_en,
		i_imem_scrb_data					=> r_imem_scrub_data_write,
		o_imem_scrb_data					=> r_imem_scrub_read_01,

		i_dmem_scrb_addr					=> r_dmem_scrub_addr,
		i_dmem_scrb_rw_en					=> w_dmem_scrub_rw_en,
		i_dmem_scrb_data					=> r_dmem_scrub_data_write,
		o_dmem_scrb_data					=> r_dmem_scrub_read_01,

		o_port_A_sel						=> r_port_A_sel_01,
		o_port_B_sel						=> r_port_B_sel_01,
		o_port_C_sel						=> r_port_C_sel_01,

		i_gpio_00_in						=> i_gpio_00_in,
		o_gpio_00_out						=> r_gpio_00_out_01,
        o_gpio_00_dir                       => r_gpio_00_dir_01,
	
		i_gpio_01_in						=> i_gpio_01_in,
		o_gpio_01_out						=> r_gpio_01_out_01,
        o_gpio_01_dir                       => r_gpio_01_dir_01,

		i_gpio_02_in						=> i_gpio_02_in,
		o_gpio_02_out						=> r_gpio_02_out_01,
        o_gpio_02_dir                       => r_gpio_02_dir_01,

        i_uart_00_rx				        => i_uart_00_rx,    
        o_uart_00_tx				        => r_uart_00_tx_01,    
        o_uart_00_en                        => r_uart_00_en_01,   

        i_uart_01_rx				        => i_uart_01_rx,
        o_uart_01_tx				        => r_uart_01_tx_01,
        o_uart_01_en                        => r_uart_01_en_01,

        i_uart_02_rx				        => i_uart_02_rx,    
        o_uart_02_tx				        => r_uart_02_tx_01,    
        o_uart_02_en                        => r_uart_02_en_01,   

        i_uart_03_rx				        => i_uart_03_rx,
        o_uart_03_tx				        => r_uart_03_tx_01,
        o_uart_03_en                        => r_uart_03_en_01,

        i_miso_boot					        => i_miso_boot,
        o_miso_boot					        => w_miso_boot_01,
        i_mosi_boot					        => i_mosi_boot,
        o_mosi_boot					        => w_mosi_boot_01,
        i_sclk_boot					        => i_sclk_boot,
        o_sclk_boot					        => w_sclk_boot_01,
        i_cs_boot 					        => i_cs_boot,
        o_cs_boot 					        => w_cs_boot_01,
        o_boot_mode					        => w_boot_mode_01,

        i_miso_00					        => i_miso_00,
        o_miso_00					        => w_miso_00_o_01,
        i_mosi_00					        => i_mosi_00,
        o_mosi_00					        => w_mosi_00_o_01,
        i_sclk_00					        => i_sclk_00,
        o_sclk_00					        => w_sclk_00_o_01,
        i_cs_00						        => i_cs_00,
        o_cs_00						        => w_cs_00_o_01,
        o_spi_mode_00                       => w_spi_00_mode_01,

        i_miso_01					        => i_miso_01,
        o_miso_01					        => w_miso_01_o_01,
        i_mosi_01					        => i_mosi_01,
        o_mosi_01					        => w_mosi_01_o_01,
        i_sclk_01					        => i_sclk_01,
        o_sclk_01					        => w_sclk_01_o_01,
        i_cs_01						        => i_cs_01,
        o_cs_01						        => w_cs_01_o_01,
        o_spi_mode_01                       => w_spi_01_mode_01,

        i_miso_02					        => i_miso_02,
        o_miso_02					        => w_miso_02_o_01,
        i_mosi_02					        => i_mosi_02,
        o_mosi_02					        => w_mosi_02_o_01,
        i_sclk_02					        => i_sclk_02,
        o_sclk_02					        => w_sclk_02_o_01,
        i_cs_02						        => i_cs_02,
        o_cs_02						        => w_cs_02_o_01,
        o_spi_mode_02                       => w_spi_02_mode_01,

        i_miso_03					        => i_miso_03,
        o_miso_03					        => w_miso_03_o_01,
        i_mosi_03					        => i_mosi_03,
        o_mosi_03					        => w_mosi_03_o_01,
        i_sclk_03					        => i_sclk_03,
        o_sclk_03					        => w_sclk_03_o_01,
        i_cs_03						        => i_cs_03,
        o_cs_03						        => w_cs_03_o_01,
        o_spi_mode_03                       => w_spi_03_mode_01,

		i_miso_flash						=> i_miso_flash,
		o_mosi_flash						=> w_mosi_flash_01,
		o_sclk_flash						=> w_sclk_flash_01,
		o_cs_flash 							=> w_cs_flash_01,

        i_scl_00							=> i_scl_00,     
		i_sda_00							=> i_sda_00,     
		o_scl_00							=> w_scl_00_o_01,     
		o_sda_00							=> w_sda_00_o_01,     
		o_i2c_mode_00						=> w_i2c_00_mode_01,

        i_scl_01							=> i_scl_01,     
		i_sda_01							=> i_sda_01,       
		o_scl_01							=> w_scl_01_o_01,        
		o_sda_01							=> w_sda_01_o_01,        
		o_i2c_mode_01						=> w_i2c_01_mode_01,

		i_adc_data_read				        => (others => '0'),
		i_adc_channel				        => (others => '0'),
		o_adc_addr					        => open,

		i_sem_stat							=> i_sem_status,
		i_arbiter_stat						=> r_arbiter_stat,
		i_monitor_stat						=> r_monitor_stat,
		i_imem_stat							=> r_imem_scrub_status,
		i_dmem_stat							=> r_dmem_scrub_status,
		i_bootrom_stat						=> r_imem_scrub_status,

		o_index								=> r_index_01,
		i_event								=> r_event,

		i_hwa_id							=> i_hwa_id,

        i_hwa_read_00				        => i_hwa_read_00,
        i_hwa_read_01				        => i_hwa_read_01,
        i_hwa_read_02				        => i_hwa_read_02,
        i_hwa_read_03				        => i_hwa_read_03,
        i_hwa_read_04				        => i_hwa_read_04,
        i_hwa_read_05				        => i_hwa_read_05,
        i_hwa_read_06				        => i_hwa_read_06,
        i_hwa_read_07				        => i_hwa_read_07,

        o_hwa_write_00				        => r_hwa_write_00_01,
        o_hwa_write_01				        => r_hwa_write_01_01,
        o_hwa_write_02				        => r_hwa_write_02_01,
        o_hwa_write_03				        => r_hwa_write_03_01,
        o_hwa_write_04				        => r_hwa_write_04_01,
        o_hwa_write_05				        => r_hwa_write_05_01,
        o_hwa_write_06				        => r_hwa_write_06_01,
        o_hwa_write_07				        => r_hwa_write_07_01,

		i_hwa_stat							=> i_hwa_stat,
		o_hwa_ctrl							=> r_hwa_ctrl_01,

		o_pr_decouple						=> w_pr_decouple_01
    );


	--! Instantiate Reach Core 02
    REACH_02 : reach_core
	generic map(
		g_CORE_ID                   		=> c_CORE_ID_02,
		g_CLK_RATE                			=> g_CLK_RATE,
		g_OBFUSCATION_OFFSET				=> c_OBFUSCATION_02,
		g_CORRUPTION						=> 0
	)
    port map(
        i_clk						        => i_clk,
        i_reset_n					        => i_reset_n,

		i_error_detect                 		=> w_repair_en,
		o_arbiter_en                		=> w_arbiter_en_02,
		o_scrubber_en               		=> w_scrubber_en_02,

		o_pc                        		=> r_pc_02,

        i_bootload_en                       => i_bootload_en,
		o_radpc_active						=> w_radpc_active_02,
		o_illegal_opcode					=> w_illegal_opcode_02,
        o_instr                       		=> r_instr_02,
        o_runtime_stat                      => r_runtime_stat_02,

		i_sem_status						=> i_sem_status,

		i_pc_repair_en              		=> r_pc_repair_en,
		i_pc_repair                 		=> r_pc,

		o_reg_D_wr                  		=> r_reg_D_wr_02,
		i_reg_D_wr                  		=> r_reg_D_wr,

		o_reg_read				    		=> r_reg_read_02,
		i_reg_write							=> r_reg_write,
		i_reg_addr							=> r_reg_addr,
		i_reg_rw							=> w_reg_rw,

		i_imem_scrb_addr					=> r_imem_scrub_addr,
		i_imem_scrb_rw_en					=> w_imem_scrub_rw_en,
		i_imem_scrb_data					=> r_imem_scrub_data_write,
		o_imem_scrb_data					=> r_imem_scrub_read_02,

		i_dmem_scrb_addr					=> r_dmem_scrub_addr,
		i_dmem_scrb_rw_en					=> w_dmem_scrub_rw_en,
		i_dmem_scrb_data					=> r_dmem_scrub_data_write,
		o_dmem_scrb_data					=> r_dmem_scrub_read_02,

		o_port_A_sel						=> r_port_A_sel_02,
		o_port_B_sel						=> r_port_B_sel_02,
		o_port_C_sel						=> r_port_C_sel_02,

		i_gpio_00_in						=> i_gpio_00_in,
		o_gpio_00_out						=> r_gpio_00_out_02,
        o_gpio_00_dir                       => r_gpio_00_dir_02,
	
		i_gpio_01_in						=> i_gpio_01_in,
		o_gpio_01_out						=> r_gpio_01_out_02,
        o_gpio_01_dir                       => r_gpio_01_dir_02,

		i_gpio_02_in						=> i_gpio_02_in,
		o_gpio_02_out						=> r_gpio_02_out_02,
        o_gpio_02_dir                       => r_gpio_02_dir_02,

        i_uart_00_rx				        => i_uart_00_rx,    
        o_uart_00_tx				        => r_uart_00_tx_02,    
        o_uart_00_en                        => r_uart_00_en_02,    

        i_uart_01_rx				        => i_uart_01_rx,
        o_uart_01_tx				        => r_uart_01_tx_02,
        o_uart_01_en                        => r_uart_01_en_02,

        i_uart_02_rx				        => i_uart_02_rx,    
        o_uart_02_tx				        => r_uart_02_tx_02,    
        o_uart_02_en                        => r_uart_02_en_02,    

        i_uart_03_rx				        => i_uart_03_rx,
        o_uart_03_tx				        => r_uart_03_tx_02,
        o_uart_03_en                        => r_uart_03_en_02,

        i_miso_boot					        => i_miso_boot,
        o_miso_boot					        => w_miso_boot_02,
        i_mosi_boot					        => i_mosi_boot,
        o_mosi_boot					        => w_mosi_boot_02,
        i_sclk_boot					        => i_sclk_boot,
        o_sclk_boot					        => w_sclk_boot_02,
        i_cs_boot 					        => i_cs_boot,
        o_cs_boot 					        => w_cs_boot_02,
        o_boot_mode					        => w_boot_mode_02,

        i_miso_00					        => i_miso_00,
        o_miso_00					        => w_miso_00_o_02,
        i_mosi_00					        => i_mosi_00,
        o_mosi_00					        => w_mosi_00_o_02,
        i_sclk_00					        => i_sclk_00,
        o_sclk_00					        => w_sclk_00_o_02,
        i_cs_00						        => i_cs_00,
        o_cs_00						        => w_cs_00_o_02,
        o_spi_mode_00                       => w_spi_00_mode_02,

        i_miso_01					        => i_miso_01,
        o_miso_01					        => w_miso_01_o_02,
        i_mosi_01					        => i_mosi_01,
        o_mosi_01					        => w_mosi_01_o_02,
        i_sclk_01					        => i_sclk_01,
        o_sclk_01					        => w_sclk_01_o_02,
        i_cs_01						        => i_cs_01,
        o_cs_01						        => w_cs_01_o_02,
        o_spi_mode_01                       => w_spi_01_mode_02,

        i_miso_02					        => i_miso_02,
        o_miso_02					        => w_miso_02_o_02,
        i_mosi_02					        => i_mosi_02,
        o_mosi_02					        => w_mosi_02_o_02,
        i_sclk_02					        => i_sclk_02,
        o_sclk_02					        => w_sclk_02_o_02,
        i_cs_02						        => i_cs_02,
        o_cs_02						        => w_cs_02_o_02,
        o_spi_mode_02                       => w_spi_02_mode_02,

        i_miso_03					        => i_miso_03,
        o_miso_03					        => w_miso_03_o_02,
        i_mosi_03					        => i_mosi_03,
        o_mosi_03					        => w_mosi_03_o_02,
        i_sclk_03					        => i_sclk_03,
        o_sclk_03					        => w_sclk_03_o_02,
        i_cs_03						        => i_cs_03,
        o_cs_03						        => w_cs_03_o_02,
        o_spi_mode_03                       => w_spi_03_mode_02,

		i_miso_flash						=> i_miso_flash,
		o_mosi_flash						=> w_mosi_flash_02,
		o_sclk_flash						=> w_sclk_flash_02,
		o_cs_flash 							=> w_cs_flash_02,

        i_scl_00							=> i_scl_00,     
		i_sda_00							=> i_sda_00,  
		o_scl_00							=> w_scl_00_o_02,     
		o_sda_00							=> w_sda_00_o_02,     
		o_i2c_mode_00						=> w_i2c_00_mode_02,

        i_scl_01							=> i_scl_01,     
		i_sda_01							=> i_sda_01,    
		o_scl_01							=> w_scl_01_o_02,        
		o_sda_01							=> w_sda_01_o_02,        
		o_i2c_mode_01						=> w_i2c_01_mode_02,

		i_adc_data_read				        => (others => '0'),
		i_adc_channel				        => (others => '0'),
		o_adc_addr					        => open,

		i_sem_stat							=> i_sem_status,
		i_arbiter_stat						=> r_arbiter_stat,
		i_monitor_stat						=> r_monitor_stat,
		i_imem_stat							=> r_imem_scrub_status,
		i_dmem_stat							=> r_dmem_scrub_status,
		i_bootrom_stat						=> r_imem_scrub_status,

		o_index								=> r_index_02,
		i_event								=> r_event,

		i_hwa_id							=> i_hwa_id,

        i_hwa_read_00				        => i_hwa_read_00,
        i_hwa_read_01				        => i_hwa_read_01,
        i_hwa_read_02				        => i_hwa_read_02,
        i_hwa_read_03				        => i_hwa_read_03,
        i_hwa_read_04				        => i_hwa_read_04,
        i_hwa_read_05				        => i_hwa_read_05,
        i_hwa_read_06				        => i_hwa_read_06,
        i_hwa_read_07				        => i_hwa_read_07,

        o_hwa_write_00				        => r_hwa_write_00_02,
        o_hwa_write_01				        => r_hwa_write_01_02,
        o_hwa_write_02				        => r_hwa_write_02_02,
        o_hwa_write_03				        => r_hwa_write_03_02,
        o_hwa_write_04				        => r_hwa_write_04_02,
        o_hwa_write_05				        => r_hwa_write_05_02,
        o_hwa_write_06				        => r_hwa_write_06_02,
        o_hwa_write_07				        => r_hwa_write_07_02,

		i_hwa_stat							=> i_hwa_stat,
		o_hwa_ctrl							=> r_hwa_ctrl_02,

		o_pr_decouple						=> w_pr_decouple_02
    );


	--! Instantiate Reach Core 03
    REACH_03 : reach_core
	generic map(
		g_CORE_ID                   		=> c_CORE_ID_03,
		g_CLK_RATE                			=> g_CLK_RATE,
		g_OBFUSCATION_OFFSET				=> c_OBFUSCATION_03,
		g_CORRUPTION						=> 0
	)
    port map(
        i_clk						        => i_clk,
        i_reset_n					        => i_reset_n,

		i_error_detect                 		=> w_repair_en,
		o_arbiter_en                		=> w_arbiter_en_03,
		o_scrubber_en               		=> w_scrubber_en_03,

		o_pc                        		=> r_pc_03,

        i_bootload_en                       => i_bootload_en,
		o_radpc_active						=> w_radpc_active_03,
		o_illegal_opcode					=> w_illegal_opcode_03,
        o_instr                       		=> r_instr_03,
        o_runtime_stat                      => r_runtime_stat_03,

		i_sem_status						=> i_sem_status,

		i_pc_repair_en              		=> r_pc_repair_en,
		i_pc_repair                 		=> r_pc,

		o_reg_D_wr                  		=> r_reg_D_wr_03,
		i_reg_D_wr                  		=> r_reg_D_wr,

		o_reg_read				    		=> r_reg_read_03,
		i_reg_write							=> r_reg_write,
		i_reg_addr							=> r_reg_addr,
		i_reg_rw							=> w_reg_rw,

		i_imem_scrb_addr					=> r_imem_scrub_addr,
		i_imem_scrb_rw_en					=> w_imem_scrub_rw_en,
		i_imem_scrb_data					=> r_imem_scrub_data_write,
		o_imem_scrb_data					=> r_imem_scrub_read_03,

		i_dmem_scrb_addr					=> r_dmem_scrub_addr,
		i_dmem_scrb_rw_en					=> w_dmem_scrub_rw_en,
		i_dmem_scrb_data					=> r_dmem_scrub_data_write,
		o_dmem_scrb_data					=> r_dmem_scrub_read_03,

		o_port_A_sel						=> r_port_A_sel_03,
		o_port_B_sel						=> r_port_B_sel_03,
		o_port_C_sel						=> r_port_C_sel_03,

		i_gpio_00_in						=> i_gpio_00_in,
		o_gpio_00_out						=> r_gpio_00_out_03,
        o_gpio_00_dir                       => r_gpio_00_dir_03,
	
		i_gpio_01_in						=> i_gpio_01_in,
		o_gpio_01_out						=> r_gpio_01_out_03,
        o_gpio_01_dir                       => r_gpio_01_dir_03,

		i_gpio_02_in						=> i_gpio_02_in,
		o_gpio_02_out						=> r_gpio_02_out_03,
        o_gpio_02_dir                       => r_gpio_02_dir_03,

        i_uart_00_rx				        => i_uart_00_rx,    
        o_uart_00_tx				        => r_uart_00_tx_03,    
        o_uart_00_en                        => r_uart_00_en_03,    

        i_uart_01_rx				        => i_uart_01_rx,
        o_uart_01_tx				        => r_uart_01_tx_03,
        o_uart_01_en                        => r_uart_01_en_03,

        i_uart_02_rx				        => i_uart_02_rx,    
        o_uart_02_tx				        => r_uart_02_tx_03,    
        o_uart_02_en                        => r_uart_02_en_03,    

        i_uart_03_rx				        => i_uart_03_rx,
        o_uart_03_tx				        => r_uart_03_tx_03,
        o_uart_03_en                        => r_uart_03_en_03,

        i_miso_boot					        => i_miso_boot,
        o_miso_boot					        => w_miso_boot_03,
        i_mosi_boot					        => i_mosi_boot,
        o_mosi_boot					        => w_mosi_boot_03,
        i_sclk_boot					        => i_sclk_boot,
        o_sclk_boot					        => w_sclk_boot_03,
        i_cs_boot 					        => i_cs_boot,
        o_cs_boot 					        => w_cs_boot_03,
        o_boot_mode					        => w_boot_mode_03,

        i_miso_00					        => i_miso_00,
        o_miso_00					        => w_miso_00_o_03,
        i_mosi_00					        => i_mosi_00,
        o_mosi_00					        => w_mosi_00_o_03,
        i_sclk_00					        => i_sclk_00,
        o_sclk_00					        => w_sclk_00_o_03,
        i_cs_00						        => i_cs_00,
        o_cs_00						        => w_cs_00_o_03,
        o_spi_mode_00                       => w_spi_00_mode_03,

        i_miso_01					        => i_miso_01,
        o_miso_01					        => w_miso_01_o_03,
        i_mosi_01					        => i_mosi_01,
        o_mosi_01					        => w_mosi_01_o_03,
        i_sclk_01					        => i_sclk_01,
        o_sclk_01					        => w_sclk_01_o_03,
        i_cs_01						        => i_cs_01,
        o_cs_01						        => w_cs_01_o_03,
        o_spi_mode_01                       => w_spi_01_mode_03,

        i_miso_02					        => i_miso_02,
        o_miso_02					        => w_miso_02_o_03,
        i_mosi_02					        => i_mosi_02,
        o_mosi_02					        => w_mosi_02_o_03,
        i_sclk_02					        => i_sclk_02,
        o_sclk_02					        => w_sclk_02_o_03,
        i_cs_02						        => i_cs_02,
        o_cs_02						        => w_cs_02_o_03,
        o_spi_mode_02                       => w_spi_02_mode_03,

        i_miso_03					        => i_miso_03,
        o_miso_03					        => w_miso_03_o_03,
        i_mosi_03					        => i_mosi_03,
        o_mosi_03					        => w_mosi_03_o_03,
        i_sclk_03					        => i_sclk_03,
        o_sclk_03					        => w_sclk_03_o_03,
        i_cs_03						        => i_cs_03,
        o_cs_03						        => w_cs_03_o_03,
        o_spi_mode_03                       => w_spi_03_mode_03,

		i_miso_flash						=> i_miso_flash,
		o_mosi_flash						=> w_mosi_flash_03,
		o_sclk_flash						=> w_sclk_flash_03,
		o_cs_flash 							=> w_cs_flash_03,

        i_scl_00							=> i_scl_00,
		i_sda_00							=> i_sda_00,
		o_scl_00							=> w_scl_00_o_03,     
		o_sda_00							=> w_sda_00_o_03,     
		o_i2c_mode_00						=> w_i2c_00_mode_03,

        i_scl_01							=> i_scl_01,     
		i_sda_01							=> i_sda_01,      
		o_scl_01							=> w_scl_01_o_03,        
		o_sda_01							=> w_sda_01_o_03,        
		o_i2c_mode_01						=> w_i2c_01_mode_03,

		i_adc_data_read				        => (others => '0'),
		i_adc_channel				        => (others => '0'),
		o_adc_addr					        => open,

		i_sem_stat							=> i_sem_status,
		i_arbiter_stat						=> r_arbiter_stat,
		i_monitor_stat						=> r_monitor_stat,
		i_imem_stat							=> r_imem_scrub_status,
		i_dmem_stat							=> r_dmem_scrub_status,
		i_bootrom_stat						=> r_imem_scrub_status,

		o_index								=> r_index_03,
		i_event								=> r_event,

		i_hwa_id							=> i_hwa_id,

        i_hwa_read_00				        => i_hwa_read_00,
        i_hwa_read_01				        => i_hwa_read_01,
        i_hwa_read_02				        => i_hwa_read_02,
        i_hwa_read_03				        => i_hwa_read_03,
        i_hwa_read_04				        => i_hwa_read_04,
        i_hwa_read_05				        => i_hwa_read_05,
        i_hwa_read_06				        => i_hwa_read_06,
        i_hwa_read_07				        => i_hwa_read_07,

        o_hwa_write_00				        => r_hwa_write_00_03,
        o_hwa_write_01				        => r_hwa_write_01_03,
        o_hwa_write_02				        => r_hwa_write_02_03,
        o_hwa_write_03				        => r_hwa_write_03_03,
        o_hwa_write_04				        => r_hwa_write_04_03,
        o_hwa_write_05				        => r_hwa_write_05_03,
        o_hwa_write_06				        => r_hwa_write_06_03,
        o_hwa_write_07				        => r_hwa_write_07_03,

		i_hwa_stat							=> i_hwa_stat,
		o_hwa_ctrl							=> r_hwa_ctrl_03,

		o_pr_decouple						=> w_pr_decouple_03
    );


	------------------------------------------------------------------------------------------------------------------------------------
	--	CPU VOTERS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the Register D Voter
	REG_D_VOTE : voter
	generic map(
		g_VOTE_SIZE                 		=> 32
	)
	port map(
		i_val_00                			=> r_reg_D_wr_00,
		i_val_01                			=> r_reg_D_wr_01,
		i_val_02                			=> r_reg_D_wr_02,
		i_val_03                			=> r_reg_D_wr_03,
		
		o_result                 			=> r_reg_D_wr,
		o_syndrome                  		=> open
	);


	------------------------------------------------------------------------------------------------------------------------------------
	--	MONITOR INSTANTIATION
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the Monitor component
	MONITOR_00 : monitor
	port map (
		i_clk								=> i_clk,
		i_reset_n							=> i_reset_n,

		i_radpc_active_00                   => w_radpc_active_00,
		i_radpc_active_01                   => w_radpc_active_01,
		i_radpc_active_02                   => w_radpc_active_02,
		i_radpc_active_03                   => w_radpc_active_03,

		i_pc_00                             => r_pc_00,
		i_pc_01                             => r_pc_01,
		i_pc_02                             => r_pc_02,
		i_pc_03                             => r_pc_03,

		i_illegal_opcode_00             	=> w_illegal_opcode_00,
		i_illegal_opcode_01             	=> w_illegal_opcode_01,
		i_illegal_opcode_02             	=> w_illegal_opcode_02,
		i_illegal_opcode_03             	=> w_illegal_opcode_03,

		i_runtime_stat_00               	=> r_runtime_stat_00,
		i_runtime_stat_01               	=> r_runtime_stat_01,
		i_runtime_stat_02               	=> r_runtime_stat_02,
		i_runtime_stat_03               	=> r_runtime_stat_03,

		i_instr_00				    	    => r_instr_00,
		i_instr_01				    	    => r_instr_01,
		i_instr_02				    	    => r_instr_02,
		i_instr_03				    	    => r_instr_03,

		o_radpc_active                      => w_radpc_active,
		o_pc                                => o_pc,
		o_illegal_opcode                    => w_illegal_opcode,
		o_runtime_stat                      => r_runtime_stat,
		o_instr				                => r_instr,

		o_monitor_stat                    	=> r_monitor_stat
	);


	-- Assign monitor outputs
	o_monitor_stat 		<= r_monitor_stat;

	o_radpc_active		<= w_radpc_active;
	o_illegal_opcode	<= w_illegal_opcode;
	o_runtime_stat		<= r_runtime_stat;
	o_instr				<= r_instr;

	w_repair_en			<= 	'1' 	when( r_monitor_stat /= x"00" ) and ( r_monitor_stat(1 downto 0) /= "11" )else 
							'0';


	------------------------------------------------------------------------------------------------------------------------------------
	-- ARBITER INSTANTIATION
	------------------------------------------------------------------------------------------------------------------------------------

	--! Instantiate the Arbiter Enable voter
	VOTER_ARBITER_ENABLE : voter
	generic map(
		g_VOTE_SIZE                 		=> 1
	)
	port map(
		i_val_00(0)                			=> w_arbiter_en_00,
		i_val_01(0)                			=> w_arbiter_en_01,
		i_val_02(0)                			=> w_arbiter_en_02,
		i_val_03(0)                			=> w_arbiter_en_03,
		
		o_result(0)                 		=> w_arbiter_en,
		o_syndrome                  		=> open
	);


	--! Instantiate the Arbiter component
	ARBITER_00 : arbiter
	port map(
		i_clk								=> i_clk,
		i_reset_n							=> i_reset_n,

		i_en								=> w_arbiter_en,

		i_pc_00                             => r_pc_00,
		i_pc_01                             => r_pc_01,
		i_pc_02                             => r_pc_02,
		i_pc_03                             => r_pc_03,

		i_reg_read_00						=> r_reg_read_00,
		i_reg_read_01						=> r_reg_read_01,
		i_reg_read_02						=> r_reg_read_02,
		i_reg_read_03						=> r_reg_read_03,

		o_reg_write							=> r_reg_write,
		o_reg_addr							=> r_reg_addr,
		o_reg_rw							=> w_reg_rw,

		o_pc_repair_en          			=> r_pc_repair_en,
		o_pc								=> r_pc,

		o_arbiter_stat            			=> r_arbiter_stat
	);


	-- Assign Arbiter outputs
	o_arbiter_stat 	<= r_arbiter_stat;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SCRUBBER INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the BOOTROM scrubber component
	BOOTROM_SCRUBBER_01 : scrubber
		generic map(
			g_CLK_RATE							=> g_CLK_RATE,
			g_DATA_WIDTH						=> c_WORD_LEN,
			g_ADDR_WIDTH						=> c_WORD_LEN,
			g_RAM_DEPTH							=> c_BOOTROM_CELL_SIZE
		)
		port map(
			i_clk								=> i_clk,
			i_reset_n							=> i_reset_n,

			i_en								=> w_scrubber_en,

			i_data_rd_00						=> r_imem_scrub_read_00,
			i_data_rd_01						=> r_imem_scrub_read_01,
			i_data_rd_02						=> r_imem_scrub_read_02,
			i_data_rd_03						=> r_imem_scrub_read_03,

			o_data_wr							=> r_imem_scrub_data_write,
			o_addr								=> r_imem_scrub_addr,
			o_rw 								=> w_imem_scrub_rw_en,

			o_error								=> w_imem_error,
			o_event								=> r_imem_error_addr,

			o_status							=> o_imem_scrub_stat
		);


	-- Instantiate the DMEM scrubber component
	DMEM_SCRUBBER_01 : scrubber
		generic map(
			g_CLK_RATE							=> g_CLK_RATE,
			g_DATA_WIDTH						=> c_WORD_LEN,
			g_ADDR_WIDTH						=> c_WORD_LEN,
			g_RAM_DEPTH							=> c_DMEM_CELL_SIZE
		)
		port map(
			i_clk								=> i_clk,
			i_reset_n							=> i_reset_n,

			i_en								=> w_scrubber_en,

			i_data_rd_00						=> r_dmem_scrub_read_00,
			i_data_rd_01						=> r_dmem_scrub_read_01,
			i_data_rd_02						=> r_dmem_scrub_read_02,
			i_data_rd_03						=> r_dmem_scrub_read_03,

			o_data_wr							=> r_dmem_scrub_data_write,
			o_addr								=> r_dmem_scrub_addr,
			o_rw 								=> w_dmem_scrub_rw_en,

			o_error								=> w_dmem_error,
			o_event								=> r_dmem_error_addr,

			o_status							=> o_dmem_scrub_stat
		);


	-- Assign scrubber enable
	w_scrubber_en 	<= w_scrubber_en_00 or w_scrubber_en_01 or w_scrubber_en_02 or w_scrubber_en_03;


	------------------------------------------------------------------------------------------------------------------------------------
	-- EVENT LOGGER INSTANTIATION
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the Event Logger
	EVENT_LOGGER_00 : error_logger
		port map(
			i_clk					=> i_clk,
			i_reset_n				=> i_reset_n,

			i_dmem_scrb_event		=> r_dmem_error_addr,
			i_dmem_scrb_error		=> w_dmem_error, 

			i_index					=> r_index,
			o_event					=> r_event
		);


	-- Instantiate the Event Logger Index Voter
	EVENT_INDEX_VOTE : voter
		generic map(
			g_VOTE_SIZE                 		=> 8
		)
		port map(
			i_val_00                			=> r_index_00,
			i_val_01                			=> r_index_01,
			i_val_02                			=> r_index_02,
			i_val_03                			=> r_index_03,
			
			o_result                 			=> r_index,
			o_syndrome                  		=> open
		);



	------------------------------------------------------------------------------------------------------------------------------------
	--	PORT FUNCTION CONTROLLER (PFC) VOTER
	------------------------------------------------------------------------------------------------------------------------------------

	--! Instantiate the PFC Voter
	PFC_PORT_A_VOTE : voter
	generic map(
		g_VOTE_SIZE                 		=> 32
	)
	port map(
		i_val_00                			=> r_port_A_sel_00,
		i_val_01                			=> r_port_A_sel_01,
		i_val_02                			=> r_port_A_sel_02,
		i_val_03                			=> r_port_A_sel_03,
		
		o_result                 			=> o_port_A_sel,
		o_syndrome                  		=> open
	);


	--! Instantiate the PFC Voter
	PFC_PORT_B_VOTE : voter
	generic map(
		g_VOTE_SIZE                 		=> 32
	)
	port map(
		i_val_00                			=> r_port_B_sel_00,
		i_val_01                			=> r_port_B_sel_01,
		i_val_02                			=> r_port_B_sel_02,
		i_val_03                			=> r_port_B_sel_03,
		
		o_result                 			=> o_port_B_sel,
		o_syndrome                  		=> open
	);


	--! Instantiate the PFC Voter
	PFC_PORT_C_VOTE : voter
	generic map(
		g_VOTE_SIZE                 		=> 32
	)
	port map(
		i_val_00                			=> r_port_C_sel_00,
		i_val_01                			=> r_port_C_sel_01,
		i_val_02                			=> r_port_C_sel_02,
		i_val_03                			=> r_port_C_sel_03,
		
		o_result                 			=> o_port_C_sel,
		o_syndrome                  		=> open
	);


    ------------------------------------------------------------------------------------------------------------------------------------
	--	GPIO VOTERS
	------------------------------------------------------------------------------------------------------------------------------------

	--! Instantiate the GPIO 00 output voter
	VOTER_GPIO_00_OUT : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => r_gpio_00_out_00,
		i_val_01                    => r_gpio_00_out_01,
		i_val_02                    => r_gpio_00_out_02,
		i_val_03                    => r_gpio_00_out_03,
		
		o_result                    => o_gpio_00_out,
		o_syndrome                  => open
	);


	--! Instantiate the GPIO 01 output voter
	VOTER_GPIO_01_OUT : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => r_gpio_01_out_00,
		i_val_01                    => r_gpio_01_out_01,
		i_val_02                    => r_gpio_01_out_02,
		i_val_03                    => r_gpio_01_out_03,
		
		o_result                    => o_gpio_01_out,
		o_syndrome                  => open
	);


	--! Instantiate the GPIO 02 output voter
	VOTER_GPIO_02_OUT : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => r_gpio_02_out_00,
		i_val_01                    => r_gpio_02_out_01,
		i_val_02                    => r_gpio_02_out_02,
		i_val_03                    => r_gpio_02_out_03,
		
		o_result                    => o_gpio_02_out,
		o_syndrome                  => open
	);


	--! Instantiate the GPIO 00 direction voter
	VOTER_GPIO_00_DIR : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => r_gpio_00_dir_00,
		i_val_01                    => r_gpio_00_dir_01,
		i_val_02                    => r_gpio_00_dir_02,
		i_val_03                    => r_gpio_00_dir_03,
		
		o_result                    => o_gpio_00_dir,
		o_syndrome                  => open
	);


	--! Instantiate the GPIO 01 direction voter
	VOTER_GPIO_01_DIR : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => r_gpio_01_dir_00,
		i_val_01                    => r_gpio_01_dir_01,
		i_val_02                    => r_gpio_01_dir_02,
		i_val_03                    => r_gpio_01_dir_03,
		
		o_result                    => o_gpio_01_dir,
		o_syndrome                  => open
	);


	--! Instantiate the GPIO 01 direction voter
	VOTER_GPIO_02_DIR : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => r_gpio_02_dir_00,
		i_val_01                    => r_gpio_02_dir_01,
		i_val_02                    => r_gpio_02_dir_02,
		i_val_03                    => r_gpio_02_dir_03,
		
		o_result                    => o_gpio_02_dir,
		o_syndrome                  => open
	);


    ------------------------------------------------------------------------------------------------------------------------------------
	--	UART VOTERS
	------------------------------------------------------------------------------------------------------------------------------------

	--! Instantiate the UART 00 TX voter
	VOTER_UART_00_TX : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => r_uart_00_tx_00,
		i_val_01(0)                 => r_uart_00_tx_01,
		i_val_02(0)                 => r_uart_00_tx_02,
		i_val_03(0)                 => r_uart_00_tx_03,
		
		o_result(0)                 => o_uart_00_tx,
		o_syndrome                  => open
	);


	--! Instantiate the UART 01 TX voter
	VOTER_UART_01_TX : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => r_uart_01_tx_00,
		i_val_01(0)                 => r_uart_01_tx_01,
		i_val_02(0)                 => r_uart_01_tx_02,
		i_val_03(0)                 => r_uart_01_tx_03,
		
		o_result(0)                 => o_uart_01_tx,
		o_syndrome                  => open
	);


	--! Instantiate the UART 02 TX voter
	VOTER_UART_02_TX : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => r_uart_02_tx_00,
		i_val_01(0)                 => r_uart_02_tx_01,
		i_val_02(0)                 => r_uart_02_tx_02,
		i_val_03(0)                 => r_uart_02_tx_03,
		
		o_result(0)                 => o_uart_02_tx,
		o_syndrome                  => open
	);


	--! Instantiate the UART 03 TX voter
	VOTER_UART_03_TX : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => r_uart_03_tx_00,
		i_val_01(0)                 => r_uart_03_tx_01,
		i_val_02(0)                 => r_uart_03_tx_02,
		i_val_03(0)                 => r_uart_03_tx_03,
		
		o_result(0)                 => o_uart_03_tx,
		o_syndrome                  => open
	);


	--! Instantiate the UART 00 EN voter
	VOTER_UART_00_EN : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => r_uart_00_en_00,
		i_val_01(0)                 => r_uart_00_en_01,
		i_val_02(0)                 => r_uart_00_en_02,
		i_val_03(0)                 => r_uart_00_en_03,
		
		o_result(0)                 => o_uart_00_en,
		o_syndrome                  => open
	);


	--! Instantiate the UART 01 EN voter
	VOTER_UART_01_EN : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => r_uart_01_en_00,
		i_val_01(0)                 => r_uart_01_en_01,
		i_val_02(0)                 => r_uart_01_en_02,
		i_val_03(0)                 => r_uart_01_en_03,
		
		o_result(0)                 => o_uart_01_en,
		o_syndrome                  => open
	);


	--! Instantiate the UART 02 EN voter
	VOTER_UART_02_EN : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => r_uart_02_en_00,
		i_val_01(0)                 => r_uart_02_en_01,
		i_val_02(0)                 => r_uart_02_en_02,
		i_val_03(0)                 => r_uart_02_en_03,
		
		o_result(0)                 => o_uart_02_en,
		o_syndrome                  => open
	);


	--! Instantiate the UART 03 EN voter
	VOTER_UART_03_EN : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => r_uart_03_en_00,
		i_val_01(0)                 => r_uart_03_en_01,
		i_val_02(0)                 => r_uart_03_en_02,
		i_val_03(0)                 => r_uart_03_en_03,
		
		o_result(0)                 => o_uart_03_en,
		o_syndrome                  => open
	);


    ------------------------------------------------------------------------------------------------------------------------------------
	--	SPI BOOT VOTER INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	--! Instantiated BOOTLOAD MISO Voter
	VOTER_SPI_BOOT_MISO : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_miso_boot_00,
		i_val_01(0)                 => w_miso_boot_01,
		i_val_02(0)                 => w_miso_boot_02,
		i_val_03(0)                 => w_miso_boot_03,
		
		o_result(0)                 => o_miso_boot,
		o_syndrome                  => open
	);


	--! Instantiated BOOTLOAD MOSI Voter
	VOTER_SPI_BOOT_MOSI : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_mosi_boot_00,
		i_val_01(0)                 => w_mosi_boot_01,
		i_val_02(0)                 => w_mosi_boot_02,
		i_val_03(0)                 => w_mosi_boot_03,
		
		o_result(0)                 => o_mosi_boot,
		o_syndrome                  => open
	);


	--! Instantiated BOOTLOAD SCLK voter
	VOTER_BOOT_SCLK : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_sclk_boot_00,
		i_val_01(0)                 => w_sclk_boot_01,
		i_val_02(0)                 => w_sclk_boot_02,
		i_val_03(0)                 => w_sclk_boot_03,
		
		o_result(0)                 => o_sclk_boot,
		o_syndrome                  => open
	);


	--! Instantiated BOOTLOAD CS voter
	VOTER_BOOT_CS : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_cs_boot_00,
		i_val_01(0)                 => w_cs_boot_01,
		i_val_02(0)                 => w_cs_boot_02,
		i_val_03(0)                 => w_cs_boot_03,
		
		o_result(0)                 => o_cs_boot,
		o_syndrome                  => open
	);


	--! Instantiated BOOTLOAD Mode voter
	VOTER_BOOT_MODE : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_boot_mode_00,
		i_val_01(0)                 => w_boot_mode_01,
		i_val_02(0)                 => w_boot_mode_02,
		i_val_03(0)                 => w_boot_mode_03,
		
		o_result(0)                 => o_boot_mode,
		o_syndrome                  => open
	);


	------------------------------------------------------------------------------------------------------------------------------------
	--	NOR FLASH VOTER INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	--! Instantiated NOR Flash MOSI Voter
	VOTER_FLASH_MOSI : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_mosi_flash_00,
		i_val_01(0)                 => w_mosi_flash_01,
		i_val_02(0)                 => w_mosi_flash_02,
		i_val_03(0)                 => w_mosi_flash_03,
		
		o_result(0)                 => o_mosi_flash,
		o_syndrome                  => open
	);


	--! Instantiated NOR Flash SCLK voter
	VOTER_FLASH_SCLK : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_sclk_flash_00,
		i_val_01(0)                 => w_sclk_flash_01,
		i_val_02(0)                 => w_sclk_flash_02,
		i_val_03(0)                 => w_sclk_flash_03,
		
		o_result(0)                 => o_sclk_flash,
		o_syndrome                  => open
	);


	--! Instantiated NOR Flash CS voter
	VOTER_FLASH_CS : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_cs_flash_00,
		i_val_01(0)                 => w_cs_flash_01,
		i_val_02(0)                 => w_cs_flash_02,
		i_val_03(0)                 => w_cs_flash_03,
		
		o_result(0)                 => o_cs_flash,
		o_syndrome                  => open
	);


    ------------------------------------------------------------------------------------------------------------------------------------
	--	I2C VOTER INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	--! Instantiate the I2C 00 SCL voter
	VOTER_I2C_00_SCL : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_scl_00_o_00,
		i_val_01(0)                 => w_scl_00_o_01,
		i_val_02(0)                 => w_scl_00_o_02,
		i_val_03(0)                 => w_scl_00_o_03,
		
		o_result(0)                 => o_scl_00,
		o_syndrome                  => open
	);


	--! Instantiate the I2C 00 SDA voter
	VOTER_I2C_00_SDA : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_sda_00_o_00,
		i_val_01(0)                 => w_sda_00_o_01,
		i_val_02(0)                 => w_sda_00_o_02,
		i_val_03(0)                 => w_sda_00_o_03,
		
		o_result(0)                 => o_sda_00,
		o_syndrome                  => open
	);

	--! Instantiate the I2C 00 Mode voter
	VOTER_I2C_00_MODE : voter
	generic map(
		g_VOTE_SIZE                 => 2
	)
	port map(
		i_val_00                 	=> w_i2c_00_mode_00,
		i_val_01                 	=> w_i2c_00_mode_01,
		i_val_02                 	=> w_i2c_00_mode_02,
		i_val_03                 	=> w_i2c_00_mode_03,
		
		o_result                 	=> o_i2c_mode_00,
		o_syndrome                  => open
	);


	--! Instantiate the I2C 00 SCL voter
	VOTER_I2C_01_SCL : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_scl_01_o_00,
		i_val_01(0)                 => w_scl_01_o_01,
		i_val_02(0)                 => w_scl_01_o_02,
		i_val_03(0)                 => w_scl_01_o_03,
		
		o_result(0)                 => o_scl_01,
		o_syndrome                  => open
	);

	--! Instantiate the I2C 01 SDA voter
	VOTER_I2C_01_SDA : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_sda_01_o_00,
		i_val_01(0)                 => w_sda_01_o_01,
		i_val_02(0)                 => w_sda_01_o_02,
		i_val_03(0)                 => w_sda_01_o_03,
		
		o_result(0)                 => o_sda_01,
		o_syndrome                  => open
	);


	--! Instantiate the I2C 01 Mode voter
	VOTER_I2C_01_MODE : voter
	generic map(
		g_VOTE_SIZE                 => 2
	)
	port map(
		i_val_00                 	=> w_i2c_01_mode_00,
		i_val_01                 	=> w_i2c_01_mode_01,
		i_val_02                 	=> w_i2c_01_mode_02,
		i_val_03                 	=> w_i2c_01_mode_03,
		
		o_result                 	=> o_i2c_mode_01,
		o_syndrome                  => open
	);


    ------------------------------------------------------------------------------------------------------------------------------------
	--	SPI VOTER INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	--! Instantiate the SPI 00 MISO voter
	VOTER_SPI_00_MISO : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_miso_00_o_00,
		i_val_01(0)                 => w_miso_00_o_01,
		i_val_02(0)                 => w_miso_00_o_02,
		i_val_03(0)                 => w_miso_00_o_03,
		
		o_result(0)                 => o_miso_00,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 00 MOSI voter
	VOTER_SPI_00_MOSI : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_mosi_00_o_00,
		i_val_01(0)                 => w_mosi_00_o_01,
		i_val_02(0)                 => w_mosi_00_o_02,
		i_val_03(0)                 => w_mosi_00_o_03,
		
		o_result(0)                 => o_mosi_00,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 00 SCLK voter
	VOTER_SPI_00_SCLK : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_sclk_00_o_00,
		i_val_01(0)                 => w_sclk_00_o_01,
		i_val_02(0)                 => w_sclk_00_o_02,
		i_val_03(0)                 => w_sclk_00_o_03,
		
		o_result(0)                 => o_sclk_00,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 00 CS voter
	VOTER_SPI_00_CS : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_cs_00_o_00,
		i_val_01(0)                 => w_cs_00_o_01,
		i_val_02(0)                 => w_cs_00_o_02,
		i_val_03(0)                 => w_cs_00_o_03,
		
		o_result(0)                 => o_cs_00,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 00 Mode Select voter
	VOTER_SPI_00_MODE : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_spi_00_mode_00,
		i_val_01(0)                 => w_spi_00_mode_01,
		i_val_02(0)                 => w_spi_00_mode_02,
		i_val_03(0)                 => w_spi_00_mode_03,
		
		o_result(0)                 => o_spi_mode_00,
		o_syndrome                  => open
	);


	--! Instantiate the SPI 01 MISO voter
	VOTER_SPI_01_MISO : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_miso_01_o_00,
		i_val_01(0)                 => w_miso_01_o_01,
		i_val_02(0)                 => w_miso_01_o_02,
		i_val_03(0)                 => w_miso_01_o_03,
		
		o_result(0)                 => o_miso_01,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 01 MOSI voter
	VOTER_SPI_01_MOSI : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_mosi_01_o_00,
		i_val_01(0)                 => w_mosi_01_o_01,
		i_val_02(0)                 => w_mosi_01_o_02,
		i_val_03(0)                 => w_mosi_01_o_03,
		
		o_result(0)                 => o_mosi_01,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 01 SCLK voter
	VOTER_SPI_01_SCLK : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_sclk_01_o_00,
		i_val_01(0)                 => w_sclk_01_o_01,
		i_val_02(0)                 => w_sclk_01_o_02,
		i_val_03(0)                 => w_sclk_01_o_03,
		
		o_result(0)                 => o_sclk_01,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 01 CS voter
	VOTER_SPI_01_CS : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_cs_01_o_00,
		i_val_01(0)                 => w_cs_01_o_01,
		i_val_02(0)                 => w_cs_01_o_02,
		i_val_03(0)                 => w_cs_01_o_03,
		
		o_result(0)                 => o_cs_01,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 01 Mode Select voter
	VOTER_SPI_01_MODE : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_spi_01_mode_00,
		i_val_01(0)                 => w_spi_01_mode_01,
		i_val_02(0)                 => w_spi_01_mode_02,
		i_val_03(0)                 => w_spi_01_mode_03,
		
		o_result(0)                 => o_spi_mode_01,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 02 MISO voter
	VOTER_SPI_02_MISO : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_miso_02_o_00,
		i_val_01(0)                 => w_miso_02_o_01,
		i_val_02(0)                 => w_miso_02_o_02,
		i_val_03(0)                 => w_miso_02_o_03,
		
		o_result(0)                 => o_miso_02,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 02 MOSI voter
	VOTER_SPI_02_MOSI : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_mosi_02_o_00,
		i_val_01(0)                 => w_mosi_02_o_01,
		i_val_02(0)                 => w_mosi_02_o_02,
		i_val_03(0)                 => w_mosi_02_o_03,
		
		o_result(0)                 => o_mosi_02,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 02 SCLK voter
	VOTER_SPI_02_SCLK : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_sclk_02_o_00,
		i_val_01(0)                 => w_sclk_02_o_01,
		i_val_02(0)                 => w_sclk_02_o_02,
		i_val_03(0)                 => w_sclk_02_o_03,
		
		o_result(0)                 => o_sclk_02,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 02 CS voter
	VOTER_SPI_02_CS : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_cs_02_o_00,
		i_val_01(0)                 => w_cs_02_o_01,
		i_val_02(0)                 => w_cs_02_o_02,
		i_val_03(0)                 => w_cs_02_o_03,
		
		o_result(0)                 => o_cs_02,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 02 Mode Select voter
	VOTER_SPI_02_MODE : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_spi_02_mode_00,
		i_val_01(0)                 => w_spi_02_mode_01,
		i_val_02(0)                 => w_spi_02_mode_02,
		i_val_03(0)                 => w_spi_02_mode_03,
		
		o_result(0)                 => o_spi_mode_02,
		o_syndrome                  => open
	);


	--! Instantiate the SPI 03 MISO voter
	VOTER_SPI_03_MISO : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_miso_03_o_00,
		i_val_01(0)                 => w_miso_03_o_01,
		i_val_02(0)                 => w_miso_03_o_02,
		i_val_03(0)                 => w_miso_03_o_03,
		
		o_result(0)                 => o_miso_03,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 03 MOSI voter
	VOTER_SPI_03_MOSI : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_mosi_03_o_00,
		i_val_01(0)                 => w_mosi_03_o_01,
		i_val_02(0)                 => w_mosi_03_o_02,
		i_val_03(0)                 => w_mosi_03_o_03,
		
		o_result(0)                 => o_mosi_03,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 03 SCLK voter
	VOTER_SPI_03_SCLK : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_sclk_03_o_00,
		i_val_01(0)                 => w_sclk_03_o_01,
		i_val_02(0)                 => w_sclk_03_o_02,
		i_val_03(0)                 => w_sclk_03_o_03,
		
		o_result(0)                 => o_sclk_03,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 03 CS voter
	VOTER_SPI_03_CS : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_cs_03_o_00,
		i_val_01(0)                 => w_cs_03_o_01,
		i_val_02(0)                 => w_cs_03_o_02,
		i_val_03(0)                 => w_cs_03_o_03,
		
		o_result(0)                 => o_cs_03,
		o_syndrome                  => open
	);

	--! Instantiate the SPI 03 Mode Select voter
	VOTER_SPI_03_MODE : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => w_spi_03_mode_00,
		i_val_01(0)                 => w_spi_03_mode_01,
		i_val_02(0)                 => w_spi_03_mode_02,
		i_val_03(0)                 => w_spi_03_mode_03,
		
		o_result(0)                 => o_spi_mode_03,
		o_syndrome                  => open
	);


    -- ------------------------------------------------------------------------------------------------------------------------------------
	-- --	ADC VOTER INSTANTIATIONS
	-- ------------------------------------------------------------------------------------------------------------------------------------

	-- --! ADC Address Value 00
	-- ADC_ADDR_00 : voter
	-- generic map(
	-- 	g_VOTE_SIZE                 => 7
	-- )
	-- port map(
	-- 	i_val_00					=> r_adc_addr_00,
	-- 	i_val_01					=> r_adc_addr_01,
	-- 	i_val_02					=> r_adc_addr_02,
	-- 	i_val_03					=> r_adc_addr_03,
		
	-- 	o_result                 	=> o_adc_addr,
	-- 	o_syndrome                  => open
	-- );


    ------------------------------------------------------------------------------------------------------------------------------------
	--	HARDWARE ACCELERATOR VOTERS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the Voter for HWA Write Value 00
	HWA_WRITE_00 : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00					=> r_hwa_write_00_00,
		i_val_01					=> r_hwa_write_00_01,
		i_val_02					=> r_hwa_write_00_02,
		i_val_03					=> r_hwa_write_00_03,
		
		o_result                 	=> o_hwa_write_00,
		o_syndrome                  => open
	);

	-- Instantiate the Voter for HWA Write Value 01
	HWA_WRITE_01 : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00					=> r_hwa_write_01_00,
		i_val_01					=> r_hwa_write_01_01,
		i_val_02					=> r_hwa_write_01_02,
		i_val_03					=> r_hwa_write_01_03,
		
		o_result                 	=> o_hwa_write_01,
		o_syndrome                  => open
	);

	-- Instantiate the Voter for HWA Write Value 02
	HWA_WRITE_02 : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00					=> r_hwa_write_02_00,
		i_val_01					=> r_hwa_write_02_01,
		i_val_02					=> r_hwa_write_02_02,
		i_val_03					=> r_hwa_write_02_03,
		
		o_result                 	=> o_hwa_write_02,
		o_syndrome                  => open
	);

	-- Instantiate the Voter for HWA Write Value 03
	HWA_WRITE_03 : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00					=> r_hwa_write_03_00,
		i_val_01					=> r_hwa_write_03_01,
		i_val_02					=> r_hwa_write_03_02,
		i_val_03					=> r_hwa_write_03_03,
		
		o_result                 	=> o_hwa_write_03,
		o_syndrome                  => open
	);

	-- Instantiate the Voter for HWA Write Value 04
	HWA_WRITE_04 : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00					=> r_hwa_write_04_00,
		i_val_01					=> r_hwa_write_04_01,
		i_val_02					=> r_hwa_write_04_02,
		i_val_03					=> r_hwa_write_04_03,
		
		o_result                 	=> o_hwa_write_04,
		o_syndrome                  => open
	);

	-- Instantiate the Voter for HWA Write Value 05
	HWA_WRITE_05 : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00					=> r_hwa_write_05_00,
		i_val_01					=> r_hwa_write_05_01,
		i_val_02					=> r_hwa_write_05_02,
		i_val_03					=> r_hwa_write_05_03,
		
		o_result                 	=> o_hwa_write_05,
		o_syndrome                  => open
	);

	-- Instantiate the Voter for HWA Write Value 06
	HWA_WRITE_06 : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00					=> r_hwa_write_06_00,
		i_val_01					=> r_hwa_write_06_01,
		i_val_02					=> r_hwa_write_06_02,
		i_val_03					=> r_hwa_write_06_03,
		
		o_result                 	=> o_hwa_write_06,
		o_syndrome                  => open
	);

	-- Instantiate the Voter for HWA Write Value 07
	HWA_WRITE_07 : voter
	generic map(
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00					=> r_hwa_write_07_00,
		i_val_01					=> r_hwa_write_07_01,
		i_val_02					=> r_hwa_write_07_02,
		i_val_03					=> r_hwa_write_07_03,
		
		o_result                 	=> o_hwa_write_07,
		o_syndrome                  => open
	);

	-- Instantiate the Voter for HWA Control
	HWA_CTRL : voter
	generic map(
		g_VOTE_SIZE                 => 8
	)
	port map(
		i_val_00					=> r_hwa_ctrl_00,
		i_val_01					=> r_hwa_ctrl_01,
		i_val_02					=> r_hwa_ctrl_02,
		i_val_03					=> r_hwa_ctrl_03,
		
		o_result                 	=> o_hwa_ctrl,
		o_syndrome                  => open
	);


	-- Instantiate the Voter for HWA PR Decoupleing
	HWA_PR_DECOUPLE : voter
	generic map(
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)					=> w_pr_decouple_00,
		i_val_01(0)					=> w_pr_decouple_01,
		i_val_02(0)					=> w_pr_decouple_02,
		i_val_03(0)					=> w_pr_decouple_03,
		
		o_result(0)                 => o_pr_decouple,
		o_syndrome                  => open
	);


    ------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------



end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------