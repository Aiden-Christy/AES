----------------------------------------------------------------------------------------------------------------------------------------
--
--  RADPC
--	REACH PROCESSOR CORE
--  RISC-V RV32I PROCESSOR
--
--	Created by Chris Major
--  Resilient Computing
-- 	6/16/2022
--
--!	@file
--!	@brief A component for a processor core with RISC-V RV32I functionality
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
entity reach_core is
generic (
    g_CORE_ID                   : integer           := 0;                                   -- Process Core Unique ID
    g_CLK_RATE                	: integer           := 100_000_000;                         -- Expected Clock Rate
    g_OBFUSCATION_OFFSET        : integer           := 0;                                   -- Obfuscation Offset
    g_CORRUPTION				: integer			:= 0								    -- Memory Corruption Value
);
port(
	i_clk						: in    std_logic;			                                -- Clock
	i_reset_n					: in    std_logic;			                                -- Active Low Reset

    i_error_detect              : in    std_logic;			                                -- Repair Enable
    o_arbiter_en                : out   std_logic;                                          -- Arbiter Enable Flag
    o_scrubber_en               : out   std_logic;                                          -- Scrubber Enable Flag

    o_pc                        : out   std_logic_vector(31 downto 0);		                -- Program Counter

    i_bootload_en               : in    std_logic;                                          -- Bootload Enable
    o_radpc_active              : out   std_logic;                                          -- RadPC Active Flag
    o_illegal_opcode            : out   std_logic;                                          -- Illegal opcode flag
    o_runtime_stat              : out   std_logic_vector(31 downto 0);                     	-- Runtime Status
    o_instr				        : out	std_logic_vector(31 downto 0);		                -- Current Instruction
    
    i_sem_status				: in 	std_logic_vector(7 downto 0);						-- SEM Status Pins

    i_pc_repair_en              : in    std_logic;                                          -- Arbiter PC Repair Enable
    i_pc_repair                 : in    std_logic_vector(31 downto 0);                      -- Arbiter PC Repair Value

    o_reg_D_wr                  : out   std_logic_vector(31 downto 0);                      -- Register D Write
    i_reg_D_wr                  : in    std_logic_vector(31 downto 0);                      -- Register D Write (Voted)

    o_reg_read				    : out	std_logic_vector(31 downto 0); 						-- Register Read Data
    i_reg_write					: in	std_logic_vector(31 downto 0); 						-- Register Write Data
    i_reg_addr					: in	std_logic_vector(4 downto 0);						-- Register Address
    i_reg_rw					: in	std_logic;											-- Register Read/Write Enable

	i_imem_scrb_addr			: in 	std_logic_vector(31 downto 0);						-- IMEM Scrubber Address
	i_imem_scrb_rw_en			: in	std_logic;											-- IMEM Scrubber Read/Write Enable
	i_imem_scrb_data			: in 	std_logic_vector(31 downto 0);						-- IMEM Scrubber Memory Input Data
	o_imem_scrb_data			: out	std_logic_vector(31 downto 0);						-- IMEM Scrubber Memory Output Data

	i_dmem_scrb_addr			: in 	std_logic_vector(31 downto 0);						-- DMEM Scrubber Address
	i_dmem_scrb_rw_en			: in	std_logic;											-- DMEM Scrubber Read/Write Enable
	i_dmem_scrb_data			: in 	std_logic_vector(31 downto 0);						-- DMEM Scrubber Memory Input Data
	o_dmem_scrb_data			: out	std_logic_vector(31 downto 0);						-- DMEM Scrubber Memory Output Data

    o_port_A_sel                : out   std_logic_vector(31 downto 0);                     	-- Port A Select
    o_port_B_sel                : out   std_logic_vector(31 downto 0);                     	-- Port B Select
    o_port_C_sel                : out   std_logic_vector(31 downto 0);                     	-- Port C Select

	i_gpio_00_in				: in 	std_logic_vector(31 downto 0);						-- GPIO Input Pins 00
	o_gpio_00_out				: out 	std_logic_vector(31 downto 0);						-- GPIO Output Pins 00
	o_gpio_00_dir				: out 	std_logic_vector(31 downto 0);						-- GPIO Direction 00

	i_gpio_01_in				: in 	std_logic_vector(31 downto 0);						-- GPIO Input Pins 01
	o_gpio_01_out				: out 	std_logic_vector(31 downto 0);						-- GPIO Output Pins 01
	o_gpio_01_dir				: out 	std_logic_vector(31 downto 0);						-- GPIO Direction 01

	i_gpio_02_in				: in 	std_logic_vector(31 downto 0);						-- GPIO Input Pins 01
	o_gpio_02_out				: out 	std_logic_vector(31 downto 0);						-- GPIO Output Pins 01
	o_gpio_02_dir				: out 	std_logic_vector(31 downto 0);						-- GPIO Direction 01

	i_uart_00_rx				: in	std_logic;			                                --! UART 00 RX
	o_uart_00_tx				: out	std_logic;			                                --! UART 00 TX
	o_uart_00_en                : out	std_logic;			                                --! UART 00 Enable

	i_uart_01_rx				: in	std_logic;			                               	--! UART 01 RX
	o_uart_01_tx				: out	std_logic;			                               	--! UART 01 TX
	o_uart_01_en                : out	std_logic;			                                --! UART 01 Enable
	
	i_uart_02_rx				: in	std_logic;			                                --! UART 02 RX
	o_uart_02_tx				: out	std_logic;			                                --! UART 02 TX
	o_uart_02_en                : out	std_logic;			                                --! UART 02 Enable

	i_uart_03_rx				: in	std_logic;			                               	--! UART 03 RX
	o_uart_03_tx				: out	std_logic;			                               	--! UART 03 TX
	o_uart_03_en                : out	std_logic;			                                --! UART 03 Enable

	i_miso_boot					: in	std_logic;											--! BOOT Input Master In Slave Out (MISO)
	o_miso_boot					: out	std_logic;											--! BOOT Output Master In Slave Out (MISO)
	i_mosi_boot					: in	std_logic;											--! BOOT Input Master Out Slave In (MOSI)
	o_mosi_boot					: out	std_logic;											--! BOOT Output Master Out Slave In (MOSI)
	i_sclk_boot					: in	std_logic;											--! BOOT Incoming Serial Clock (SCLK)
	o_sclk_boot					: out	std_logic;											--! BOOT Outgoing Serial Clock (SCLK)
	i_cs_boot 					: in	std_logic;											--! BOOT Incoming Serial Data (CS)
	o_cs_boot 					: out	std_logic;											--! BOOT Outgoing Serial Data (CS)
	o_boot_mode					: out	std_logic;											--! BOOT Mode

	i_miso_00					: in	std_logic;											--! SPI 00 Input Master In Slave Out (MISO)
	o_miso_00					: out	std_logic;											--! SPI 00 Output Master In Slave Out (MISO)
	i_mosi_00					: in	std_logic;											--! SPI 00 Input Master Out Slave In (MOSI)
	o_mosi_00					: out	std_logic;											--! SPI 00 Output Master Out Slave In (MOSI)
	i_sclk_00					: in	std_logic;											--! SPI 00 Incoming Serial Clock (SCLK)
	o_sclk_00					: out	std_logic;											--! SPI 00 Outgoing Serial Clock (SCLK)
	i_cs_00						: in	std_logic;											--! SPI 00 Incoming Serial Data (CS)
	o_cs_00						: out	std_logic;											--! SPI 00 Outgoing Serial Data (CS)
	o_spi_mode_00				: out	std_logic;											--! SPI 00 Mode

	i_miso_01					: in	std_logic;											--! SPI 01 Input Master In Slave Out (MISO)
	o_miso_01					: out	std_logic;											--! SPI 01 Output Master In Slave Out (MISO)
	i_mosi_01					: in	std_logic;											--! SPI 01 Input Master Out Slave In (MOSI)
	o_mosi_01					: out	std_logic;											--! SPI 01 Output Master Out Slave In (MOSI)
	i_sclk_01					: in	std_logic;											--! SPI 01 Incoming Serial Clock (SCLK)
	o_sclk_01					: out	std_logic;											--! SPI 01 Outgoing Serial Clock (SCLK)
	i_cs_01						: in	std_logic;											--! SPI 01 Incoming Serial Data (CS)
	o_cs_01						: out	std_logic;											--! SPI 01 Outgoing Serial Data (CS)
	o_spi_mode_01				: out	std_logic;											--! SPI 00 Mode

	i_miso_02					: in	std_logic;											--! SPI 02 Input Master In Slave Out (MISO)
	o_miso_02					: out	std_logic;											--! SPI 02 Output Master In Slave Out (MISO)
	i_mosi_02					: in	std_logic;											--! SPI 02 Input Master Out Slave In (MOSI)
	o_mosi_02					: out	std_logic;											--! SPI 02 Output Master Out Slave In (MOSI)
	i_sclk_02					: in	std_logic;											--! SPI 02 Incoming Serial Clock (SCLK)
	o_sclk_02					: out	std_logic;											--! SPI 02 Outgoing Serial Clock (SCLK)
	i_cs_02						: in	std_logic;											--! SPI 02 Incoming Serial Data (CS)
	o_cs_02						: out	std_logic;											--! SPI 02 Outgoing Serial Data (CS)
	o_spi_mode_02				: out	std_logic;											--! SPI 02 Mode

	i_miso_03					: in	std_logic;											--! SPI 03 Input Master In Slave Out (MISO)
	o_miso_03					: out	std_logic;											--! SPI 03 Output Master In Slave Out (MISO)
	i_mosi_03					: in	std_logic;											--! SPI 03 Input Master Out Slave In (MOSI)
	o_mosi_03					: out	std_logic;											--! SPI 03 Output Master Out Slave In (MOSI)
	i_sclk_03					: in	std_logic;											--! SPI 03 Incoming Serial Clock (SCLK)
	o_sclk_03					: out	std_logic;											--! SPI 03 Outgoing Serial Clock (SCLK)
	i_cs_03						: in	std_logic;											--! SPI 03 Incoming Serial Data (CS)
	o_cs_03						: out	std_logic;											--! SPI 03 Outgoing Serial Data (CS)
	o_spi_mode_03				: out	std_logic;											--! SPI 03 Mode

	i_miso_flash				: in	std_logic;											--! NOR Flash Master In Slave Out (MISO)
	o_mosi_flash				: out	std_logic;											--! NOR Flash Master Out Slave In (MOSI)
	o_sclk_flash				: out	std_logic;											--! NOR Flash Serial Clock (SCLK)
	o_cs_flash 					: out	std_logic;											--! NOR Flash Serial Data (CS)

	i_scl_00					: in	std_logic;											-- I2C 00 Incoming Serial Clock Line (SCL)
	i_sda_00					: in	std_logic;											-- I2C 00 Incoming Serial Data Line (SDA)
	o_scl_00					: out	std_logic;											-- I2C 00 Outgoing Serial Clock Line (SCL)
	o_sda_00					: out	std_logic;											-- I2C 00 Outgoing Serial Data Line (SDA)
	o_I2C_mode_00				: out	std_logic_vector(1 downto 0);						-- I2C 00 INOUT Mode Control
	
	i_scl_01					: in	std_logic;											-- I2C 01 Incoming Serial Clock Line (SCL)
	i_sda_01					: in	std_logic;											-- I2C 01 Incoming Serial Data Line (SDA)
	o_scl_01					: out	std_logic;											-- I2C 01 Outgoing Serial Clock Line (SCL)
	o_sda_01					: out	std_logic;											-- I2C 01 Outgoing Serial Data Line (SDA)
	o_I2C_mode_01				: out	std_logic_vector(1 downto 0);						-- I2C 01 INOUT Mode Control

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

    o_pr_decouple				: out	std_logic											-- Partial Reconfiguration Decoupling Enable
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture reach_core_arch of reach_core is

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Control Unit
    component control_unit is
    generic(
        g_OBFUSCATION_OFFSET        : integer           := 0
    );
    port(
        i_clk						: in    std_logic;
	    i_reset_n					: in    std_logic;

        i_error_detect              : in    std_logic;

        i_opcode                    : in    std_logic_vector(6 downto 0);
        i_funct3                    : in    std_logic_vector(2 downto 0);
        i_funct7                    : in    std_logic_vector(6 downto 0);

        i_BrEQ                      : in    std_logic;
        i_BrLT                      : in    std_logic;

        i_exception_flag            : in    std_logic;
        o_exception_clr             : out   std_logic;

        o_radpc_active              : out   std_logic;

        o_BrU                       : out   std_logic;

        o_pc_sel                    : out   std_logic_vector(1 downto 0);
        o_pc_en                     : out   std_logic;

        o_data_pass                 : out   std_logic_vector(1 downto 0);
        o_b_sel                     : out   std_logic;
        o_a_sel                     : out   std_logic;

        o_funct7                    : out   std_logic_vector(6 downto 0);
        o_funct3                    : out   std_logic_vector(2 downto 0);

        o_reg_wen                   : out   std_logic;
        o_imm_sel                   : out   std_logic_vector(2 downto 0);

        o_mem_rw_en                 : out   std_logic;
        o_wb_sel                    : out   std_logic_vector(1 downto 0);
        o_load_size                 : out   std_logic_vector(2 downto 0);

        o_csr_en                    : out   std_logic;
        o_csr_sel                   : out   std_logic_vector(1 downto 0);
        o_csr_imm                   : out   std_logic;

        o_mepc_en                   : out   std_logic;

        o_arbiter_en                : out   std_logic;
        o_scrubber_en               : out   std_logic;
        o_illegal_opcode            : out   std_logic
    );
    end component;


    -- Declare the Program Counter (PC) Component
    component program_counter is
    generic(
        g_PC_RESET					: integer 			:= 0
    );
    port(
        i_clk						: in	std_logic;
        i_reset_n					: in	std_logic;
        i_alu_val					: in 	std_logic_vector(31 downto 0);

        i_mtvec                     : in    std_logic_vector(31 downto 0);
        i_mepc						: in	std_logic_vector(31 downto 0);

	    i_pc_en						: in	std_logic;
	    i_pc_sel					: in	std_logic_vector(1 downto 0);

        i_arbiter_en          		: in    std_logic;
        i_arbiter_pc             	: in    std_logic_vector(31 downto 0); 

        o_pc						: out	std_logic_vector(31 downto 0);
        o_pc_plus					: out	std_logic_vector(31 downto 0)
    );
    end component;


    -- Instantiate the Memory Management Unit (MMU)
    component mmu is
    generic (
	    g_CLK_RATE                	: integer           := 100_000_000;
        g_OBFUSCATION_OFFSET        : integer           := 0;
        g_CORRUPTION				: integer			:= 0
    );
    port(
        i_clk						: in	std_logic;
        i_reset_n					: in	std_logic;
        
        i_pc						: in    std_logic_vector(31 downto 0);
        i_addr						: in    std_logic_vector(31 downto 0);
        i_rw_en						: in    std_logic;
        i_data_wr					: in    std_logic_vector(31 downto 0);
        i_load_size				    : in    std_logic_vector(2 downto 0);

        i_imem_scrb_addr			: in 	std_logic_vector(31 downto 0);
        i_imem_scrb_rw_en			: in	std_logic;
        i_imem_scrb_data			: in 	std_logic_vector(31 downto 0);
        o_imem_scrb_data			: out	std_logic_vector(31 downto 0);

        i_dmem_scrb_addr			: in 	std_logic_vector(31 downto 0);
        i_dmem_scrb_rw_en			: in	std_logic;
        i_dmem_scrb_data			: in 	std_logic_vector(31 downto 0);
        o_dmem_scrb_data			: out	std_logic_vector(31 downto 0);

        o_instr					    : out	std_logic_vector(31 downto 0);
        o_data_rd					: out	std_logic_vector(31 downto 0);
        o_illegal_pc                : out 	std_logic;

        o_port_A_sel                : out   std_logic_vector(31 downto 0);
        o_port_B_sel                : out   std_logic_vector(31 downto 0);
        o_port_C_sel                : out   std_logic_vector(31 downto 0);

        i_gpio_00_in				: in 	std_logic_vector(31 downto 0);
        o_gpio_00_out				: out 	std_logic_vector(31 downto 0);
        o_gpio_00_dir				: out 	std_logic_vector(31 downto 0);
        o_gpio_00_irq				: out	std_logic;

        i_gpio_01_in				: in 	std_logic_vector(31 downto 0);
        o_gpio_01_out				: out 	std_logic_vector(31 downto 0);
        o_gpio_01_dir				: out 	std_logic_vector(31 downto 0);
        o_gpio_01_irq				: out	std_logic;

        i_gpio_02_in				: in 	std_logic_vector(31 downto 0);
        o_gpio_02_out				: out 	std_logic_vector(31 downto 0);
        o_gpio_02_dir				: out 	std_logic_vector(31 downto 0);
        o_gpio_02_irq				: out	std_logic;

        i_uart_00_rx				: in	std_logic;
        o_uart_00_tx				: out	std_logic;
        o_uart_00_en                : out	std_logic;
        o_uart_00_irq				: out	std_logic;

        i_uart_01_rx				: in	std_logic;
        o_uart_01_tx				: out	std_logic;
        o_uart_01_en                : out	std_logic;
        o_uart_01_irq				: out	std_logic;

        i_uart_02_rx				: in	std_logic;
        o_uart_02_tx				: out	std_logic;
        o_uart_02_en                : out	std_logic;
        o_uart_02_irq				: out	std_logic;

        i_uart_03_rx				: in	std_logic;
        o_uart_03_tx				: out	std_logic;
        o_uart_03_en                : out	std_logic;
        o_uart_03_irq				: out	std_logic;

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
        o_spi_irq_00				: out	std_logic;

        i_miso_01					: in	std_logic;
        o_miso_01					: out	std_logic;
        i_mosi_01					: in	std_logic;
        o_mosi_01					: out	std_logic;
        i_sclk_01					: in	std_logic;
        o_sclk_01					: out	std_logic;
        i_cs_01						: in	std_logic;
        o_cs_01						: out	std_logic;
        o_spi_mode_01				: out	std_logic;
        o_spi_irq_01				: out	std_logic;

        i_miso_02					: in	std_logic;
        o_miso_02					: out	std_logic;
        i_mosi_02					: in	std_logic;
        o_mosi_02					: out	std_logic;
        i_sclk_02					: in	std_logic;
        o_sclk_02					: out	std_logic;
        i_cs_02						: in	std_logic;
        o_cs_02						: out	std_logic;
        o_spi_mode_02				: out	std_logic;
        o_spi_irq_02				: out	std_logic;

        i_miso_03					: in	std_logic;
        o_miso_03					: out	std_logic;
        i_mosi_03					: in	std_logic;
        o_mosi_03					: out	std_logic;
        i_sclk_03					: in	std_logic;
        o_sclk_03					: out	std_logic;
        i_cs_03						: in	std_logic;
        o_cs_03						: out	std_logic;
        o_spi_mode_03				: out	std_logic;
        o_spi_irq_03				: out	std_logic;

        i_miso_flash				: in	std_logic;
        o_mosi_flash				: out	std_logic;
        o_sclk_flash				: out	std_logic;
        o_cs_flash 					: out	std_logic;

		i_scl_00					: in	std_logic;
		i_sda_00					: in	std_logic;
		o_scl_00					: out	std_logic;
		o_sda_00					: out	std_logic;
		o_I2C_mode_00				: out	std_logic_vector(1 downto 0);
		o_i2c_irq_00				: out	std_logic;
		
		i_scl_01					: in	std_logic;
		i_sda_01					: in	std_logic;
		o_scl_01					: out	std_logic;
		o_sda_01					: out	std_logic;
		o_I2C_mode_01				: out	std_logic_vector(1 downto 0);
		o_i2c_irq_01				: out	std_logic;

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

        o_pr_decouple				: out	std_logic;

        o_timer_00_irq				: out	std_logic;
        o_timer_01_irq				: out	std_logic
    );
    end component;


    -- Declare the Registers component
    component register_map is
    port(
        i_clk						: in	std_logic;
        i_reset_n					: in	std_logic;

        i_addr_D                    : in	std_logic_vector(4 downto 0);
        i_addr_A                    : in	std_logic_vector(4 downto 0);
        i_addr_B                    : in	std_logic_vector(4 downto 0);
    
        i_data_D                    : in	std_logic_vector(31 downto 0);
    
        i_reg_rw                    : in	std_logic;

        o_arb_read				    : out	std_logic_vector(31 downto 0);
        i_arb_write					: in	std_logic_vector(31 downto 0);
        i_arb_addr					: in	std_logic_vector(4 downto 0);
        i_arb_rw					: in	std_logic;

        o_data_A                    : out	std_logic_vector(31 downto 0);
        o_data_B                    : out	std_logic_vector(31 downto 0)
    );
    end component;


    -- Declare the ALU
    component alu is
    port(
        i_data_A                    : in 	std_logic_vector(31 downto 0);
        i_data_B                    : in	std_logic_vector(31 downto 0);
        
        i_alu_sel                   : in    std_logic_vector(2 downto 0);
        i_data_pass                 : in    std_logic_vector(1 downto 0);
        i_funct7                    : in    std_logic_vector(6 downto 0);

        o_alu_output			    : out	std_logic_vector(31 downto 0)
    );
    end component;


    -- Declare the IMM GEN
    component imm_gen is
    port(
        i_inst                      : in 	std_logic_vector(31 downto 7);
        i_imm_sel                   : in	std_logic_vector(2 downto 0);
    
        o_imm_val			        : out	std_logic_vector(31 downto 0)
    );
    end component;


    -- Declare the Branch Component
    component branch_cmp is
    port(
        i_data_A                    : in 	std_logic_vector(31 downto 0);
        i_data_B                    : in	std_logic_vector(31 downto 0);
    
        i_BrU			            : in 	std_logic;
        o_BrEQ			            : out	std_logic;
        o_BrLT			            : out	std_logic
    );
    end component;


    -- Declare the Control Status Registers (CSR) component
    component csr is
    port(
        i_clk                       : in	std_logic;
        i_reset_n                   : in	std_logic;

        i_csr_addr                  : in    std_logic_vector(11 downto 0);

        i_csr_en                    : in    std_logic;
        i_csr_sel                   : in    std_logic_vector(1 downto 0);
        i_csr_data_write            : in    std_logic_vector(31 downto 0);

        o_csr_data_read             : out   std_logic_vector(31 downto 0);

        i_illegal_opcode            : in    std_logic;
        i_illegal_pc                : in    std_logic;

        i_sem_status                : in 	std_logic_vector(7 downto 0);
        o_runtime_stat              : out   std_logic_vector(31 downto 0);
        i_bootload_en               : in    std_logic;

        i_pc                        : in    std_logic_vector(31 downto 0);
        i_mepc_en                   : in    std_logic;

        i_gpio_00_irq               : in    std_logic;
        i_gpio_01_irq               : in    std_logic;
        i_uart_00_irq               : in    std_logic;
        i_uart_01_irq               : in    std_logic;
        i_timer_00_irq              : in    std_logic;
        i_timer_01_irq              : in    std_logic;
        i_spi_00_irq                : in    std_logic;
        i_spi_01_irq                : in    std_logic;
        i_i2c_00_irq                : in    std_logic;
        i_i2c_01_irq                : in    std_logic;

        i_exception_clr             : in    std_logic;
        o_exception_flag            : out   std_logic;
        o_mtvec                     : out   std_logic_vector(31 downto 0);
        o_mepc                      : out   std_logic_vector(31 downto 0)
    );
    end component;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    signal r_pc                         : std_logic_vector(31 downto 0);                        -- Program Counter (PC)
    signal r_pc_plus                    : std_logic_vector(31 downto 0);                        -- Program Counter Lookahead

    signal w_exception_clr              : std_logic;                                            -- Exception Clear
    signal w_exception_flag             : std_logic;                                            -- Exception Flag
    signal w_illegal_opcode             : std_logic;                                            -- Illegal Opcode Flag
    signal w_illegal_pc                 : std_logic;                                            -- Illegal Program Count Flag

    signal r_mtvec                      : std_logic_vector(31 downto 0);                        -- Machine Trap Vector (MTVEC) 
    signal r_mepc                       : std_logic_vector(31 downto 0);                        -- MEPC (MEPC) 
    signal w_mepc_en                    : std_logic;                                            -- MEPC Write Enable

    signal r_instr                      : std_logic_vector(31 downto 0);                        -- Core Instruction
    signal r_addr_D                     : std_logic_vector(4 downto 0);                         -- Register D Address
    signal r_addr_A                     : std_logic_vector(4 downto 0);                         -- Register A Address
    signal r_addr_B                     : std_logic_vector(4 downto 0);                         -- Register B Address

    --signal r_data_D                     : std_logic_vector(31 downto 0);                        -- Register D Data
    signal r_data_A                     : std_logic_vector(31 downto 0);                        -- Register A Data
    signal r_data_B                     : std_logic_vector(31 downto 0);                        -- Register B Data

    signal r_alu_A                      : std_logic_vector(31 downto 0);                        -- ALU Register A Data
    signal r_alu_B                      : std_logic_vector(31 downto 0);                        -- ALU Register B Data
    signal r_alu_result                 : std_logic_vector(31 downto 0);                        -- ALU Output Data 

    signal r_imm_b                      : std_logic_vector(31 downto 0);                        -- ALU B Immediate Data
    signal r_mem_data_out               : std_logic_vector(31 downto 0);                        -- Memory Read Output

    -- CSR SIGNALS
    signal r_csr_result                 : std_logic_vector(31 downto 0);                        -- CSR Output
    signal w_csr_en                     : std_logic;                                            -- CSR Read Enable
    signal r_csr_sel                    : std_logic_vector(1 downto 0);                         -- CSR ALU Select
    signal w_csr_imm                    : std_logic;                                            -- CSR Immediate Select

    signal r_csr_data_write             : std_logic_vector(31 downto 0);                        -- CSR Data In

    signal r_irq                        : std_logic;                                            -- Interrupt Request Signal

    signal w_gpio_00_irq                : std_logic;                                            -- GPIO_00 Interrupt Request Signal
    signal w_gpio_01_irq                : std_logic;                                            -- GPIO_01 Interrupt Request Signal
    signal w_gpio_02_irq                : std_logic;                                            -- GPIO_02 Interrupt Request Signal

    signal w_timer_00_irq               : std_logic;                                            -- TIMER_00 Interrupt Request Signal
    signal w_timer_01_irq               : std_logic;                                            -- TIMER_01 Interrupt Request Signal

    signal w_i2c_00_irq                 : std_logic;                                            -- I2C_00 Interrupt Request Signal
    signal w_i2c_01_irq                 : std_logic;                                            -- I2C_01 Interrupt Request Signal

	signal w_uart_00_irq				: std_logic;                    						-- UART Direction 00
	signal w_uart_01_irq				: std_logic;                    						-- UART Direction 01
	signal w_uart_02_irq				: std_logic;                    						-- UART Direction 02
	signal w_uart_03_irq				: std_logic;                    						-- UART Direction 03

    signal w_spi_00_irq                 : std_logic;                                            -- SPI 00 Interrupt Request Signal
    signal w_spi_01_irq                 : std_logic;                                            -- SPI 01 Interrupt Request Signal
    signal w_spi_02_irq                 : std_logic;                                            -- SPI 02 Interrupt Request Signal
    signal w_spi_03_irq                 : std_logic;                                            -- SPI 03 Interrupt Request Signal

    signal w_reg_wen                    : std_logic;                                            -- Register Write Enable
    signal r_funct3                     : std_logic_vector(2 downto 0);                         -- ALU Function Select
    signal r_data_pass                  : std_logic_vector(1 downto 0);                         -- ALU Passthrough Select
    signal r_funct7                     : std_logic_vector(6 downto 0);                         -- ALU Function 7 Select
    signal w_b_sel                      : std_logic;                                            -- ALU B Data Select
    signal w_a_sel                      : std_logic;                                            -- ALU A Data Select
    signal r_imm_sel                    : std_logic_vector(2 downto 0);                         -- Imm Gen Select
    signal w_mem_rw_en                  : std_logic;                                            -- Memory RW Enable
    signal r_wb_sel                     : std_logic_vector(1 downto 0);                         -- Memory/ALU Result Select
    signal r_load_size                  : std_logic_vector(2 downto 0);                         -- Memory Data Load Size
    signal w_pc_sel                     : std_logic_vector(1 downto 0);                         -- PC Select
    signal w_pc_en                      : std_logic;                                            -- PC Enable

    signal r_BrU			            : std_logic;                                            -- Unsigned/Signed Switch
    signal r_BrEQ			            : std_logic;                                            -- Branch When Equal
    signal r_BrLT			            : std_logic;                                            -- Branch When Lesser Than


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------
	            
    -- Instantiate the Control Unit
    CTRL_UNIT_01 : control_unit
    generic map(
        g_OBFUSCATION_OFFSET        => g_OBFUSCATION_OFFSET
    )
    port map (
        i_clk                       => i_clk,
        i_reset_n					=> i_reset_n,

        i_error_detect                 => i_error_detect,

        i_opcode                    => r_instr( 6 downto 0 ),
        i_funct3                    => r_instr( 14 downto 12 ),
        i_funct7                    => r_instr( 31 downto 25 ),
    
        i_BrEQ                      => r_BrEQ,
        i_BrLT                      => r_BrLT,

        i_exception_flag            => w_exception_flag,
        o_exception_clr             => w_exception_clr,

        o_radpc_active              => o_radpc_active,

        o_BrU                       => r_BrU,

        o_pc_sel                    => w_pc_sel,
        o_pc_en                     => w_pc_en,

        o_data_pass                 => r_data_pass,
        o_a_sel                     => w_a_sel,
        o_b_sel                     => w_b_sel,

        o_funct3                    => r_funct3,
        o_funct7                    => r_funct7,

        o_reg_wen                   => w_reg_wen,
        o_imm_sel                   => r_imm_sel,

        o_mem_rw_en                 => w_mem_rw_en,
        o_wb_sel                    => r_wb_sel,
        o_load_size                 => r_load_size,

        o_csr_en                    => w_csr_en,
        o_csr_sel                   => r_csr_sel,
        o_csr_imm                   => w_csr_imm,

        o_mepc_en                   => w_mepc_en,

        o_arbiter_en                => o_arbiter_en,   
        o_scrubber_en               => o_scrubber_en, 
        o_illegal_opcode            => w_illegal_opcode 
    );


    -- Instantiate the PC
    PC_01 : program_counter
    generic map (
	    g_PC_RESET					=> to_integer( c_BOOTROM_START )
    )
    port map (
        i_clk                       => i_clk,
        i_reset_n					=> i_reset_n,
        i_alu_val					=> r_alu_result,
        i_mtvec                     => r_mtvec,
        i_mepc                      => r_mepc,
        
        i_pc_en						=> w_pc_en,
	    i_pc_sel					=> w_pc_sel,

        i_arbiter_en          		=> i_pc_repair_en,
        i_arbiter_pc             	=> i_pc_repair,

        o_pc						=> r_pc,
        o_pc_plus					=> r_pc_plus
    );


    -- Instantiate the Memory Map
    MMU_01 : mmu
    generic map(
	    g_CLK_RATE                	=> g_CLK_RATE,
        g_OBFUSCATION_OFFSET        => g_OBFUSCATION_OFFSET,
        g_CORRUPTION				=> g_CORRUPTION
    )
    port map(
        i_clk						=> i_clk,
        i_reset_n					=> i_reset_n,
        
        i_pc						=> r_pc,
        i_addr						=> r_alu_result,
        i_rw_en						=> w_mem_rw_en,
        i_data_wr					=> r_data_B,
        i_load_size				    => r_load_size,

        i_imem_scrb_addr			=> i_imem_scrb_addr,
        i_imem_scrb_rw_en			=> i_imem_scrb_rw_en,
        i_imem_scrb_data			=> i_imem_scrb_data,
        o_imem_scrb_data			=> o_imem_scrb_data,

        i_dmem_scrb_addr			=> i_dmem_scrb_addr,
        i_dmem_scrb_rw_en			=> i_dmem_scrb_rw_en,
        i_dmem_scrb_data			=> i_dmem_scrb_data,
        o_dmem_scrb_data			=> o_dmem_scrb_data,

        o_instr					    => r_instr,
        o_data_rd					=> r_mem_data_out,
        o_illegal_pc                => w_illegal_pc,

        o_port_A_sel                => o_port_A_sel,
        o_port_B_sel                => o_port_B_sel,
        o_port_C_sel                => o_port_C_sel,

        i_gpio_00_in				=> i_gpio_00_in,
        o_gpio_00_out				=> o_gpio_00_out,
        o_gpio_00_dir				=> o_gpio_00_dir,
        o_gpio_00_irq				=> w_gpio_00_irq,
    
        i_gpio_01_in				=> i_gpio_01_in,
        o_gpio_01_out				=> o_gpio_01_out,
        o_gpio_01_dir				=> o_gpio_01_dir,
        o_gpio_01_irq				=> w_gpio_01_irq,
    
        i_gpio_02_in				=> i_gpio_02_in,
        o_gpio_02_out				=> o_gpio_02_out,
        o_gpio_02_dir				=> o_gpio_02_dir,
        o_gpio_02_irq				=> w_gpio_02_irq,

        i_uart_00_rx				=> i_uart_00_rx,
        o_uart_00_tx				=> o_uart_00_tx,
        o_uart_00_en                => o_uart_00_en,
        o_uart_00_irq               => w_uart_00_irq,
    
        i_uart_01_rx				=> i_uart_01_rx,
        o_uart_01_tx				=> o_uart_01_tx,
        o_uart_01_en                => o_uart_01_en,
        o_uart_01_irq               => w_uart_01_irq,

        i_uart_02_rx				=> i_uart_02_rx,
        o_uart_02_tx				=> o_uart_02_tx,
        o_uart_02_en                => o_uart_02_en,
        o_uart_02_irq               => w_uart_02_irq,
    
        i_uart_03_rx				=> i_uart_03_rx,
        o_uart_03_tx				=> o_uart_03_tx,
        o_uart_03_en                => o_uart_03_en,
        o_uart_03_irq               => w_uart_03_irq,

        i_miso_boot					=> i_miso_boot,
        o_miso_boot					=> o_miso_boot,
        i_mosi_boot					=> i_mosi_boot,
        o_mosi_boot					=> o_mosi_boot,
        i_sclk_boot					=> i_sclk_boot,
        o_sclk_boot					=> o_sclk_boot,
        i_cs_boot 					=> i_cs_boot,
        o_cs_boot 					=> o_cs_boot,
        o_boot_mode					=> o_boot_mode,

        i_miso_00					=> i_miso_00,
        o_miso_00					=> o_miso_00,
        i_mosi_00					=> i_mosi_00,
        o_mosi_00					=> o_mosi_00,
        i_sclk_00					=> i_sclk_00,
        o_sclk_00					=> o_sclk_00,
        i_cs_00						=> i_cs_00,
        o_cs_00						=> o_cs_00,
        o_spi_mode_00               => o_spi_mode_00,
        o_spi_irq_00				=> w_spi_00_irq,

        i_miso_01					=> i_miso_01,
        o_miso_01					=> o_miso_01,
        i_mosi_01					=> i_mosi_01,
        o_mosi_01					=> o_mosi_01,
        i_sclk_01					=> i_sclk_01,
        o_sclk_01					=> o_sclk_01,
        i_cs_01						=> i_cs_01,
        o_cs_01						=> o_cs_01,
        o_spi_mode_01               => o_spi_mode_01,
        o_spi_irq_01				=> w_spi_01_irq,

        i_miso_02					=> i_miso_02,
        o_miso_02					=> o_miso_02,
        i_mosi_02					=> i_mosi_02,
        o_mosi_02					=> o_mosi_02,
        i_sclk_02					=> i_sclk_02,
        o_sclk_02					=> o_sclk_02,
        i_cs_02						=> i_cs_02,
        o_cs_02						=> o_cs_02,
        o_spi_mode_02               => o_spi_mode_02,
        o_spi_irq_02				=> w_spi_02_irq,

        i_miso_03					=> i_miso_03,
        o_miso_03					=> o_miso_03,
        i_mosi_03					=> i_mosi_03,
        o_mosi_03					=> o_mosi_03,
        i_sclk_03					=> i_sclk_03,
        o_sclk_03					=> o_sclk_03,
        i_cs_03						=> i_cs_03,
        o_cs_03						=> o_cs_03,
        o_spi_mode_03               => o_spi_mode_03,
        o_spi_irq_03				=> w_spi_03_irq,

        i_miso_flash				=> i_miso_flash,
        o_mosi_flash				=> o_mosi_flash,
        o_sclk_flash				=> o_sclk_flash,
        o_cs_flash 					=> o_cs_flash,

		i_scl_00					=> i_scl_00,
		i_sda_00					=> i_sda_00,
		o_scl_00					=> o_scl_00,
		o_sda_00					=> o_sda_00,
		o_I2C_mode_00				=> o_I2C_mode_00,
		o_i2c_irq_00				=> w_i2c_00_irq,

		i_scl_01					=> i_scl_01,
		i_sda_01					=> i_sda_01,
		o_scl_01					=> o_scl_01,
		o_sda_01					=> o_sda_01,
		o_I2C_mode_01				=> o_I2C_mode_01,
		o_i2c_irq_01				=> w_i2c_01_irq,

        i_adc_data_read				=> i_adc_data_read,
        i_adc_channel				=> i_adc_channel,
        o_adc_addr					=> o_adc_addr,

        i_sem_stat					=> i_sem_stat,
        i_arbiter_stat				=> i_arbiter_stat,
        i_monitor_stat				=> i_monitor_stat,
        i_imem_stat					=> i_dmem_stat,
        i_dmem_stat					=> i_dmem_stat,
        i_bootrom_stat				=> i_bootrom_stat,

        o_index						=> o_index,
		i_event						=> i_event,

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

        o_pr_decouple				=> o_pr_decouple,

        o_timer_00_irq				=> w_timer_00_irq,
        o_timer_01_irq				=> w_timer_01_irq
    );


    -- Instantiate the Registers
    REG_01 : register_map
    port map (
        i_clk                       => i_clk,
        i_reset_n					=> i_reset_n,

        i_addr_D                    => r_addr_D,
        i_addr_A                    => r_addr_A,
        i_addr_B                    => r_addr_B,
    
        i_data_D                    => i_reg_D_wr,  --r_data_D,
    
        i_reg_rw                    => w_reg_wen,
        
        o_arb_read				    => o_reg_read,
        i_arb_write					=> i_reg_write,
        i_arb_addr					=> i_reg_addr,
        i_arb_rw					=> i_reg_rw,

        o_data_A                    => r_data_A,        -- o_reg_A_rd,  
        o_data_B                    => r_data_B         -- o_reg_B_rd
    );


    -- Instantiate the ALU
    ALU_01 : alu
    port map (
        i_data_A                    => r_alu_A,
        i_data_B                    => r_alu_B,
        
        i_alu_sel                   => r_funct3,
        i_data_pass                 => r_data_pass,
        i_funct7                    => r_funct7,

        o_alu_output                => r_alu_result
    );


    -- Instantiate the IMM GEN
    IMM_GEN_01 : imm_gen
    port map (
        i_inst                      => r_instr(31 downto 7),
        i_imm_sel                   => r_imm_sel,
    
        o_imm_val			        => r_imm_b
    );


    -- Instantiate the Branch component
    BRANCH_01 : branch_cmp
    port map (
        i_data_A                    => r_data_A,        -- i_reg_A_rd
        i_data_B                    => r_data_B,        -- i_reg_B_rd
    
        i_BrU			            => r_BrU,
        o_BrEQ			            => r_BrEQ,
        o_BrLT			            => r_BrLT
    );


    -- Instantiate the CSR component
    CSR_01 : csr
    port map(
        i_clk						=> i_clk,
        i_reset_n					=> i_reset_n,
    
        i_csr_addr                  => r_imm_b(11 downto 0),

        i_csr_en                    => w_csr_en,
        i_csr_sel                   => r_csr_sel,
        i_csr_data_write            => r_csr_data_write,
    
        o_csr_data_read             => r_csr_result,

        i_illegal_opcode            => w_illegal_opcode,
        i_illegal_pc                => w_illegal_pc,

        i_sem_status                => i_sem_status,
        i_bootload_en               => i_bootload_en,
        o_runtime_stat              => o_runtime_stat,

        i_pc                        => r_pc,
        i_mepc_en                   => w_mepc_en,

        i_gpio_00_irq               => w_gpio_00_irq,
        i_gpio_01_irq               => w_gpio_01_irq,
        i_uart_00_irq               => w_uart_00_irq,
        i_uart_01_irq               => w_uart_01_irq,
        i_timer_00_irq              => w_timer_00_irq,
        i_timer_01_irq              => w_timer_01_irq,
        i_spi_00_irq                => w_spi_00_irq,
        i_spi_01_irq                => w_spi_01_irq,
        i_i2c_00_irq                => w_i2c_00_irq,
        i_i2c_01_irq                => w_i2c_01_irq,

        i_exception_clr             => w_exception_clr,
        o_exception_flag            => w_exception_flag,
        o_mtvec                     => r_mtvec,
        o_mepc                      => r_mepc
    );


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Route Program Counter to output
    o_pc                            <=  r_pc;

    -- Assign register addresses
    r_addr_D                        <=  r_instr(11 downto 7);
    r_addr_A                        <=  r_instr(19 downto 15);
    r_addr_B                        <=  r_instr(24 downto 20);


    -- Assign to CSR input
    r_csr_data_write                <=  x"000000" & "000" & r_addr_A        when( w_csr_imm = '1' and w_csr_en = '1' )  else
                                        r_alu_A;


    -- Assign to ALU input A
    r_alu_A                         <=  r_pc                                when( w_a_sel = '1' )                       else
                                        r_data_A;


    -- Assign to ALU input B
    r_alu_B                         <=  r_csr_result                        when( w_b_sel = '1' and w_csr_en = '1' )    else
                                        r_imm_b                             when( w_b_sel = '1' )                       else
                                        r_data_B;


    -- Assign Register Input D
    o_reg_D_wr                      <=  r_alu_result                        when( r_wb_sel = c_WB_ALU )                 else
                                        r_pc_plus                           when( r_wb_sel = c_WB_PC_PLUS )             else
                                        r_csr_result                        when( r_wb_sel = c_WB_CSR )                 else
                                        r_mem_data_out;


    -- Route current instruction to output
	o_instr				            <=  r_instr;

    -- Assign illegal opcode flag to output
    o_illegal_opcode                <=  w_illegal_opcode;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------