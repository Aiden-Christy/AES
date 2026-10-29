----------------------------------------------------------------------------------------------------------------------------------------
--
--	RAM MEMORY TEMPLATE
--
--	Created by Chris Major
-- 	11/17/2021
--
--	A synchronous Random Access Memory (RAM) design with a address validity flag
--  Data is byte-sized (ha ha) to match most conventional BRAM routing strategies
--
--  Data can be pre-loaded into ram_pkg.vhd
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

	-- RadPC Reach Core Memory Package
	use WORK.REACH_MEM_PKG.all;
	
    -- RadPC Reach Core BOOTROM Package
	use WORK.REACH_BOOTROM_PKG.all;


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity bootrom is
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
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture bootrom_arch of bootrom is

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the memory cell component
	component bootrom_cell is
	generic ( 
		g_MEM_DATA                      : t_BOOT_ROM                                              	-- Memory Initialization Data
	);
	port (
		i_clk                           : in    std_logic;                                          -- Input Clock  

		i_A_addr                       	: in    std_logic_vector( 31 downto 0 );                    -- Address (Port A)
		i_A_rw                         	: in    std_logic;                                          -- Read / Write (Port A)
		i_A_data_wr                    	: in    std_logic_vector( 7 downto 0 );                     -- Write Data (Port A)
		o_A_data_rd                   	: out   std_logic_vector( 7 downto 0 );                     -- Read Data (Port A)

		i_B_addr                      	: in    std_logic_vector( 31 downto 0 );                    -- Address (Port B)
		o_B_data_rd                   	: out   std_logic_vector( 7 downto 0 )                     	-- Read Data (Port A)
	);
	end component;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_pc_addr					: std_logic_vector(31 downto 0);							-- Addressable Program Counter

	signal r_instruction_00				: std_logic_vector(7 downto 0);								-- Instruction Byte 00
	signal r_instruction_01				: std_logic_vector(7 downto 0);								-- Instruction Byte 01
	signal r_instruction_02				: std_logic_vector(7 downto 0);								-- Instruction Byte 02
	signal r_instruction_03				: std_logic_vector(7 downto 0);								-- Instruction Byte 03


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- MEMORY CELL INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------
    
	-- Instantiate Memory Cell 00
	MEM_CELL_00 : bootrom_cell
	generic map ( 
		g_MEM_DATA                      => r_BOOTROM_00
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                      	=> i_scrb_addr,
		i_A_rw                         	=> i_scrb_rw,
		i_A_data_wr                    	=> i_scrb_wr(7 downto 0),
		o_A_data_rd                   	=> o_scrb_rd(7 downto 0),

		i_B_addr                      	=> r_pc_addr,
		o_B_data_rd                   	=> r_instruction_00
	);

	-- Instantiate Memory Cell 01
	MEM_CELL_01 : bootrom_cell
	generic map ( 
		g_MEM_DATA                      => r_BOOTROM_01
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                      	=> i_scrb_addr,
		i_A_rw                         	=> i_scrb_rw,
		i_A_data_wr                    	=> i_scrb_wr(15 downto 8),
		o_A_data_rd                   	=> o_scrb_rd(15 downto 8),

		i_B_addr                      	=> r_pc_addr,
		o_B_data_rd                   	=> r_instruction_01
	);

	-- Instantiate Memory Cell 02
	MEM_CELL_02 : bootrom_cell
	generic map ( 
		g_MEM_DATA                      => r_BOOTROM_02
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                      	=> i_scrb_addr,
		i_A_rw                         	=> i_scrb_rw,
		i_A_data_wr                    	=> i_scrb_wr(23 downto 16),
		o_A_data_rd                   	=> o_scrb_rd(23 downto 16),

		i_B_addr                      	=> r_pc_addr,
		o_B_data_rd                   	=> r_instruction_02
	);

	-- Instantiate Memory Cell 03
	MEM_CELL_03 : bootrom_cell
	generic map ( 
		g_MEM_DATA                      => r_BOOTROM_03
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                      	=> i_scrb_addr,
		i_A_rw                         	=> i_scrb_rw,
		i_A_data_wr                    	=> i_scrb_wr(31 downto 24),
		o_A_data_rd                   	=> o_scrb_rd(31 downto 24),

		i_B_addr                      	=> r_pc_addr,
		o_B_data_rd                   	=> r_instruction_03
	);


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign PC relative to bootrom space
	r_pc_addr		<= "00" & i_pc(31 downto 2); 


	-- Assign instruction
	o_instr			<= 	r_instruction_03 & r_instruction_02 & r_instruction_01 & r_instruction_00 when i_reset_n = '1' else
						(others => '0');


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------