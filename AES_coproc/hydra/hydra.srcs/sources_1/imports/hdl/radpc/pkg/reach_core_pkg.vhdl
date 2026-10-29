-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	REACH CORE PACKAGE
--
--	ENGINEER: 	CHRIS MAJOR
--  COMPANY: 	RESILIENT COMPUTING
-- 	DATE:		01/27/2024
--
--	A PACKAGE DEFINING THE RISC-V CONSTANTS OF THE REACH CORE PROCESSOR
--
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIBRARIES
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	-- IEEE Standard Logic Package
	use IEEE.STD_LOGIC_1164.ALL;

	-- IEEE Numeric Standard Package
	use IEEE.NUMERIC_STD.ALL;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PACKAGE
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package reach_core_pkg is

	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- 	CONSTANT DECLARATIONS - CLOCK SPEED AND TIMING
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	constant c_CLK_RATE					: integer 								:= 32_000_000;										-- RadPC Clock Rate [Hz]


	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- 	CONSTANT DECLARATIONS - GENERATION SETTINGS
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	constant c_ENABLE_BOOTLOAD			: std_logic								:= '1';												-- Enable Bootloading
	constant c_ENABLE_HWA				: std_logic								:= '1';												-- Enable Hardware Acceleration


	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- 	CONSTANT DECLARATIONS - RISC-V ISA
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    constant c_A_SUPPORT                : std_logic                         	:= '0';             								-- Atomic (A) Extension Support
    constant c_B_SUPPORT                : std_logic                         	:= '0';             								-- Bitmanip (B) Extension Support
    constant c_C_SUPPORT                : std_logic                         	:= '0';             								-- Compressed (C) Extension Support
    constant c_D_SUPPORT                : std_logic                         	:= '0';             								-- Double Precision Float (D) Extension Support
    constant c_F_SUPPORT                : std_logic                         	:= '0';             								-- Single Precision Float (F) Extension Support
    constant c_G_SUPPORT                : std_logic                         	:= '0';             								-- General Extension (G) Extension Support
    constant c_H_SUPPORT                : std_logic                         	:= '0';             								-- Hypervisor (H) Extension Support
    constant c_I_SUPPORT                : std_logic                         	:= '1';             								-- Integer (I) Extension Support
    constant c_M_SUPPORT                : std_logic                         	:= '0';             								-- Multiplication (M) Extension Support
    constant c_V_SUPPORT                : std_logic                         	:= '0';             								-- Vector (V) Extension Support


	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- 	CONSTANT DECLARATIONS - RISC-V CPU CONSTANTS
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	constant c_BYTE_LEN					: integer								:= 8;												-- RV32I Byte Length
	constant c_HALF_LEN					: integer								:= 16;												-- RV32I Half Length
	constant c_WORD_LEN					: integer								:= 32;												-- RV32I Word Length

	constant c_READ						: std_logic								:= '0';												-- Read Only Macro
	constant c_WRITE					: std_logic								:= '1';												-- Read Write Macro

	constant c_BYTE						: std_logic_vector(2 downto 0)			:= "000";											-- Byte
	constant c_HALF						: std_logic_vector(2 downto 0)			:= "001";											-- Half
	constant c_WORD						: std_logic_vector(2 downto 0)			:= "010";											-- Word
	constant c_BYTE_U					: std_logic_vector(2 downto 0)			:= "100";											-- Byte (Unsigned)
	constant c_HALF_U					: std_logic_vector(2 downto 0)			:= "101";											-- Half (Unsigned)

    constant c_R_OPCODE           		: std_logic_vector(6 downto 0)      	:= "0110011";           							-- Register (R) Instruction Opcode
    constant c_I_OPCODE           		: std_logic_vector(6 downto 0)      	:= "0010011";           							-- Immediate (I) Instruction Opcode
    constant c_L_OPCODE           		: std_logic_vector(6 downto 0)      	:= "0000011";           							-- Load (L) Instruction Opcode
    constant c_S_OPCODE           		: std_logic_vector(6 downto 0)      	:= "0100011";           							-- Store (S) Instruction Opcode
	constant c_B_OPCODE         		: std_logic_vector(6 downto 0)      	:= "1100011";           							-- Branch (B) Instruction Opcode
	constant c_JAL_OPCODE       		: std_logic_vector(6 downto 0)      	:= "1101111";           							-- Jump And Link (JAL) Instruction Opcode
	constant c_JALR_OPCODE      		: std_logic_vector(6 downto 0)      	:= "1100111";           							-- Jump and Link Register (JALR) Instruction Opcode
	constant c_LUI_OPCODE     			: std_logic_vector(6 downto 0)      	:= "0110111";           							-- Load Upper Immediate (LUI) Instruction Opcode
	constant c_AUIPC_OPCODE    			: std_logic_vector(6 downto 0)      	:= "0010111";           							-- Add Upper Immediate to PC (AUIPC) Instruction Opcode
	constant c_SYS_OPCODE      			: std_logic_vector(6 downto 0)      	:= "1110011";           							-- System (SYS) Instruction Opcode

    constant c_PC_INCR          		: std_logic_vector(1 downto 0)      	:= "00";                							-- Program Count (PC) Select to standard increment
    constant c_PC_ALU           		: std_logic_vector(1 downto 0)      	:= "01";                							-- Program Count (PC) Select to ALU Input
    constant c_PC_MTVEC          		: std_logic_vector(1 downto 0)      	:= "10";                							-- Program Count (PC) Select to MTVEC Input
	constant c_PC_MEPC					: std_logic_vector(1 downto 0)			:= "11";											-- Program Count (PC) Select to MEPC Input

    constant c_I_IMM            		: std_logic_vector(2 downto 0)      	:= "000";              								-- I-Type Immediate Generation Code 
    constant c_S_IMM            		: std_logic_vector(2 downto 0)      	:= "010";              								-- S-Type Immediate Generation Code
    constant c_B_IMM            		: std_logic_vector(2 downto 0)      	:= "011";              								-- B-Type Immediate Generation Code
    constant c_J_IMM            		: std_logic_vector(2 downto 0)      	:= "100";              								-- J-Type Immediate Generation Code
    constant c_U_IMM            		: std_logic_vector(2 downto 0)      	:= "101";              								-- U-Type Immediate Generation Code
    constant c_SYS_IMM          		: std_logic_vector(2 downto 0)      	:= "110";              								-- SYS-Type Immediate Generation Code

    constant c_WB_MEM_READ      		: std_logic_vector(1 downto 0)      	:= "00";               								-- Writeback (WB) Select to Memory Read
    constant c_WB_ALU           		: std_logic_vector(1 downto 0)      	:= "01";               								-- Writeback (WB) Select to ALU Result
    constant c_WB_PC_PLUS       		: std_logic_vector(1 downto 0)      	:= "10";               								-- Writeback (WB) Select to Program Count (Plus 4)
    constant c_WB_CSR           		: std_logic_vector(1 downto 0)      	:= "11";               								-- Writeback (WB) Select to CSR

    constant c_CSR_WRITE                : std_logic_vector(1 downto 0)      	:= "01";              								-- CSR Atomic Read/Write operation 
    constant c_CSR_SET                  : std_logic_vector(1 downto 0)      	:= "10";              								-- CSR Read/Set Bits operation
    constant c_CSR_CLEAR                : std_logic_vector(1 downto 0)      	:= "11";              								-- CSR Read/Clear Bits operation


	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- 	CONSTANT DECLARATIONS - MEMORY MAP
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Bootload Read Only Memory (BOOTROM)
	constant c_BOOTROM_SIZE				: integer								:= 1024;											-- BOOTROM Size (Bytes)
	constant c_BOOTROM_START			: unsigned(31 downto 0)					:= x"00000000";										-- BOOTROM Start Address (global)
    constant c_BOOTROM_CELL_SIZE        : integer                            	:= (c_BOOTROM_SIZE / 4);							-- Size of BOOTROM cells (bytes) 


	-- Instruction Memory (IMEM)
	constant c_IMEM_SIZE				: integer								:= 12288;											-- IMEM Size (Bytes)
	constant c_IMEM_START				: unsigned(31 downto 0)					:= x"10000000";										-- IMEM Start Address (global)
    constant c_IMEM_CELL_SIZE           : integer                               := (c_IMEM_SIZE / 4);								-- IMEM cell size (bytes) 
	constant c_IMEM_MAX					: unsigned(31 downto 0)					:= c_IMEM_START + to_unsigned(c_IMEM_SIZE, 32);		-- IMEM Max Address (global)


	-- Data Memory (DMEM)					
	constant c_DMEM_SIZE				: integer								:= 12288;											-- DMEM Size (bytes)
	constant c_DMEM_START				: unsigned(31 downto 0)					:= x"20000000";										-- DMEM Start Address (global)
    constant c_DMEM_CELL_SIZE           : integer                               := (c_DMEM_SIZE / 4);								-- DMEM cell size (bytes) 
	constant c_DMEM_MAX					: unsigned(31 downto 0)					:= c_DMEM_START + to_unsigned(c_DMEM_SIZE, 32);		-- DMEM Max Address (global)


	-- Program Function Controller (PFC)
	constant c_PFC_MEM_START			: unsigned(31 downto 0)					:= x"2F000000";										-- PFC Start Address (global)
	constant c_PFC_MEM_MAX				: unsigned(31 downto 0)					:= (c_PFC_MEM_START + 12);							-- PFC Max Address (global)


	-- Bootload SPI Peripheral (BOOT)
	constant c_BOOT_SPI_START			: unsigned(31 downto 0)					:= x"40000000";										-- BOOT SPI Start Address (global)
	constant c_BOOT_SPI_MEM_MAX			: unsigned(31 downto 0)					:= x"40000014";										-- BOOT SPI Max Address (Global)


	-- General Purpose Input/Output Devices (GPIO)
	constant c_GPIO_00_MEM_GENERATE		: boolean								:= true;											-- GPIO 00 Generate Flag
	constant c_GPIO_00_MEM_START		: unsigned(31 downto 0)					:= x"30004000";										-- GPIO 00 Start Address (Global)
	constant c_GPIO_00_MEM_MAX			: unsigned(31 downto 0)					:= x"3000401C";										-- GPIO 00 Max Address (Global)

	constant c_GPIO_01_MEM_GENERATE		: boolean								:= true;											-- GPIO 01 Generate Flag
	constant c_GPIO_01_MEM_START		: unsigned(31 downto 0)					:= x"30005000";										-- GPIO 01 Start Address (Global)
	constant c_GPIO_01_MEM_MAX			: unsigned(31 downto 0)					:= x"3000501C";										-- GPIO 01 Max Address (Global)

	constant c_GPIO_02_MEM_GENERATE		: boolean								:= true;											-- GPIO 02 Generate Flag
	constant c_GPIO_02_MEM_START		: unsigned(31 downto 0)					:= x"3000F000";										-- GPIO 02 Start Address (Global)
	constant c_GPIO_02_MEM_MAX			: unsigned(31 downto 0)					:= x"3000F01C";										-- GPIO 02 Max Address (Global)


	-- Universal Asynchronous Transmit/Receive (UART)
	constant c_UART_00_MEM_GENERATE		: boolean								:= true;											-- UART 00 Generate Flag
	constant c_UART_00_MEM_START		: unsigned(31 downto 0)					:= x"30000000";										-- UART 00 Start Address (Global)
	constant c_UART_00_MEM_MAX			: unsigned(31 downto 0)					:= x"3000001C";										-- UART 00 Max Address (Global)

	constant c_UART_01_MEM_GENERATE		: boolean								:= true;											-- UART 01 Generate Flag
	constant c_UART_01_MEM_START		: unsigned(31 downto 0)					:= x"30001000";										-- UART 01 Start Address (Global)
	constant c_UART_01_MEM_MAX			: unsigned(31 downto 0)					:= x"3000101C";										-- UART 01 Max Address (Global)

	constant c_UART_02_MEM_GENERATE		: boolean								:= true;											-- UART 02 Generate Flag
	constant c_UART_02_MEM_START		: unsigned(31 downto 0)					:= x"3000B000";										-- UART 02 Start Address (Global)
	constant c_UART_02_MEM_MAX			: unsigned(31 downto 0)					:= x"3000B01C";										-- UART 02 Max Address (Global)

	constant c_UART_03_MEM_GENERATE		: boolean								:= true;											-- UART 03 Generate Flag
	constant c_UART_03_MEM_START		: unsigned(31 downto 0)					:= x"3000C000";										-- UART 03 Start Address (Global)
	constant c_UART_03_MEM_MAX			: unsigned(31 downto 0)					:= x"3000C01C";										-- UART 03 Max Address (Global)


	-- Serial Peripheral Interface (SPI)
	constant c_SPI_00_MEM_GENERATE		: boolean								:= true;											-- SPI 00 Generate Flag
	constant c_SPI_00_MEM_START			: unsigned(31 downto 0)					:= x"30002000";										-- SPI 00 Start Address (Global)
	constant c_SPI_00_MEM_MAX			: unsigned(31 downto 0)					:= x"30002014";										-- SPI 00 Max Address (Global)

	constant c_SPI_01_MEM_GENERATE		: boolean								:= true;											-- SPI 01 Generate Flag
	constant c_SPI_01_MEM_START			: unsigned(31 downto 0)					:= x"30003000";										-- SPI 01 Start Address (Global)
	constant c_SPI_01_MEM_MAX			: unsigned(31 downto 0)					:= x"30003014";										-- SPI 01 Max Address (Global)

	constant c_SPI_02_MEM_GENERATE		: boolean								:= true;											-- SPI 02 Generate Flag
	constant c_SPI_02_MEM_START			: unsigned(31 downto 0)					:= x"3000D000";										-- SPI 02 Start Address (Global)
	constant c_SPI_02_MEM_MAX			: unsigned(31 downto 0)					:= x"3000D014";										-- SPI 02 Max Address (Global)

	constant c_SPI_03_MEM_GENERATE		: boolean								:= true;											-- SPI 03 Generate Flag
	constant c_SPI_03_MEM_START			: unsigned(31 downto 0)					:= x"3000E000";										-- SPI 03 Start Address (Global)
	constant c_SPI_03_MEM_MAX			: unsigned(31 downto 0)					:= x"3000E014";										-- SPI 03 Max Address (Global)


	-- Inter-Integrated Circuit (I2C)
	constant c_I2C_00_MEM_GENERATE		: boolean								:= true;											-- I2C 00 Generate Flag
	constant c_I2C_00_MEM_START			: unsigned(31 downto 0)					:= x"30006000";										-- I2C 00 Start Address (Global)
	constant c_I2C_00_MEM_MAX			: unsigned(31 downto 0)					:= x"30006030";										-- I2C 00 Max Address (Global)

	constant c_I2C_01_MEM_GENERATE		: boolean								:= true;											-- I2C 01 Generate Flag
	constant c_I2C_01_MEM_START			: unsigned(31 downto 0)					:= x"30007000";										-- I2C 01 Start Address (Global)
	constant c_I2C_01_MEM_MAX			: unsigned(31 downto 0)					:= x"30007030";										-- I2C 01 Max Address (Global)


	-- Analog-To-Digital Converter (ADC)
	constant c_ADC_MEM_GENERATE			: boolean								:= false;											-- ADC Generate Flag
	constant c_ADC_MEM_START			: unsigned(31 downto 0)					:= x"3000A000";										-- ADC Start Address (Global)
	constant c_ADC_MEM_MAX				: unsigned(31 downto 0)					:= x"3000A004";										-- ADC Max Address (Global)


	-- Timer Peripheral
	constant c_TIMER_00_GENERATE		: boolean								:= false;											-- Timer 00 Generate Flag
	constant c_TIMER_00_START			: unsigned(31 downto 0)					:= x"30008000";										-- Timer 00 Start Address (Global)
	constant c_TIMER_00_MEM_MAX			: unsigned(31 downto 0)					:= x"30008060";										-- Timer 01 Max Address (Global)

	constant c_TIMER_01_GENERATE		: boolean								:= false;											-- Timer 01 Generate Flag
	constant c_TIMER_01_START			: unsigned(31 downto 0)					:= x"30009000";										-- Timer 01 Start Address (Global)
	constant c_TIMER_01_MEM_MAX			: unsigned(31 downto 0)					:= x"30009060";										-- Timer 01 Max Address (Global)


	-- Hardware Accelerator (HWA)
	constant c_HWA_MEM_GENERATE			: boolean								:= true;											-- HWA Generate Flag
	constant c_HWA_MEM_START			: unsigned(31 downto 0)					:= x"50000000";										-- HWA Start Address (Global)
	constant c_HWA_MEM_MAX				: unsigned(31 downto 0)					:= x"50000052";										-- HWA Max Address (Global)


	-- NOR Flash Memory Peripheral
	constant c_FLASH_MEM_GENERATE		: boolean								:= true;											-- NOR FLASH SPI Generate Flag
	constant c_FLASH_MEM_START			: unsigned(31 downto 0)					:= x"60000000";										-- NOR FLASH SPI Start Address (Global)
	constant c_FLASH_MEM_MAX			: unsigned(31 downto 0)					:= x"60000014";										-- NOR FLASH SPI Max Address (Global)


	-- FRM Peripheral
	constant c_FRM_START				: unsigned(31 downto 0)					:= x"F0000000";										-- FRM Start Address (Global)
	constant c_FRM_MEM_MAX				: unsigned(31 downto 0)					:= x"F0000018";										-- FRM Max Address (Global)


	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- CONSTANT DECLARATIONS - OBFUSCATION
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	constant c_OBFUSCATION_00			: integer								:= 0;												-- Obfuscation Value (Tile 00)
	constant c_OBFUSCATION_01			: integer								:= 0;												-- Obfuscation Value (Tile 01)
	constant c_OBFUSCATION_02			: integer								:= 0;												-- Obfuscation Value (Tile 02)
	constant c_OBFUSCATION_03			: integer								:= 0;												-- Obfuscation Value (Tile 03)


	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- TYPE DECLARATIONS
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Type for BOOTROM cell arrays
    type t_BOOT_ROM is array ( 0 to (c_BOOTROM_CELL_SIZE - 1) ) of std_logic_vector( 7 downto 0 );             

	-- Type for IMEM cell arrays
    type t_IMEM_RAM is array ( 0 to (c_IMEM_CELL_SIZE - 1) ) of std_logic_vector( 7 downto 0 );             

	-- Type for DMEM cell arrays
    type t_DMEM_RAM is array ( 0 to (c_DMEM_CELL_SIZE - 1) ) of std_logic_vector( 7 downto 0 );                 


	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- TYPE DECLARATIONS
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	--! Function to obfuscate opcodes by adding a given constant to each opcode in the memory array
	function obfuscate( t_ORIGINAL_IMEM : t_IMEM_RAM; c_INDEX : integer ) return t_IMEM_RAM;

	-- Function to simulate radiation errors in a DMEM component 
	function simulate_radiation( t_ORIGINAL_DMEM : t_DMEM_RAM; c_ADDRESS : integer; c_BIT_MASK : std_logic_vector(7 downto 0) ) return t_DMEM_RAM;


end package reach_core_pkg;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PACKAGE BODY
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package body reach_core_pkg is

	-- Function to obfuscate opcodes by adding a given constant to each opcode in the memory array
	function obfuscate( t_ORIGINAL_IMEM : t_IMEM_RAM; c_INDEX : integer ) return t_IMEM_RAM is

		variable t_OBFUSCATED_RAM : t_IMEM_RAM;

	begin

		for i in 0 to (c_IMEM_CELL_SIZE - 1) loop

			t_OBFUSCATED_RAM(i) := t_ORIGINAL_IMEM(i)(7) & std_logic_vector( to_unsigned( (to_integer( unsigned( t_ORIGINAL_IMEM(i)(6 downto 0) )) + c_INDEX), 7 ));

		end loop;

		return t_OBFUSCATED_RAM;

	end function;


	-- Function to simulate radiation errors in a DMEM component 
	function simulate_radiation( t_ORIGINAL_DMEM : t_DMEM_RAM; c_ADDRESS : integer; c_BIT_MASK : std_logic_vector(7 downto 0) ) return t_DMEM_RAM is

		variable t_CORRUPTED_RAM : t_DMEM_RAM;

	begin

		-- Iterate through the DMEM component
		for i in 0 to (c_DMEM_CELL_SIZE - 1) loop

			-- If the DMEM address specified by the loop is the requested address, flip the bits as specified by the mask
			if( i = c_ADDRESS ) then

				t_CORRUPTED_RAM(i) := t_ORIGINAL_DMEM(i) XOR c_BIT_MASK;

			-- Otherwise, write the original data
			else

				t_CORRUPTED_RAM(i) := t_ORIGINAL_DMEM(i);

			end if;

		end loop;

		return t_CORRUPTED_RAM;

	end function;


end package body reach_core_pkg;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
