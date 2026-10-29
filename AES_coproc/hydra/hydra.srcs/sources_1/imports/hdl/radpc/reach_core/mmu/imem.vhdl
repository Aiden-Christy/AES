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


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity imem is
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
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture imem_arch of imem is

	------------------------------------------------------------------------------------------------------------------------------------
	-- CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Create a constant array for obfuscation
	constant r_IMEM_OBFUSCATE_00 		: t_IMEM_RAM := obfuscate( r_IMEM_00, g_OBFUSCATION_OFFSET );


	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the memory cell component
	component imem_cell is
	generic ( 
		g_MEM_DATA                      : t_IMEM_RAM
	);
	port (
		i_clk                           : in    std_logic;                                          -- Input clock  

		i_A_addr                       	: in    std_logic_vector( 31 downto 0 );                    -- Address (Port A)
		i_A_rw                         	: in    std_logic;                                          -- Read / Write (Port A)
		i_A_data_wr                    	: in    std_logic_vector( 7 downto 0 );                     -- Write Data (Port A)
		o_A_data_rd                   	: out   std_logic_vector( 7 downto 0 );                     -- Read Data (Port A)

		i_B_addr                      	: in    std_logic_vector( 31 downto 0 );                    -- Address (Port B)
		o_B_data_rd                   	: out   std_logic_vector( 7 downto 0 )                     	-- Read Data (Port A)
	);
	end component;


	-- Declare the memory data routing component
	component bytewise_route is
	generic(
		g_MAX_MEM_ADDR					: integer	:= 1024
	);
	port (
		i_addr							: in 	std_logic_vector(31 downto 0);
		i_rw_en							: in	std_logic;
		i_data_width					: in	std_logic_vector(2 downto 0);

		i_data_write					: in    std_logic_vector(31 downto 0);

		i_cell_read_00					: in	std_logic_vector(7 downto 0);
		i_cell_read_01					: in	std_logic_vector(7 downto 0);
		i_cell_read_02					: in	std_logic_vector(7 downto 0);
		i_cell_read_03					: in	std_logic_vector(7 downto 0);

		o_cell_addr_00					: out 	std_logic_vector(31 downto 0);
		o_cell_addr_01					: out 	std_logic_vector(31 downto 0);
		o_cell_addr_02					: out 	std_logic_vector(31 downto 0);
		o_cell_addr_03					: out 	std_logic_vector(31 downto 0);

		o_cell_rw_00					: out	std_logic;
		o_cell_rw_01					: out	std_logic;
		o_cell_rw_02					: out	std_logic;
		o_cell_rw_03					: out	std_logic;

		o_cell_write_00					: out	std_logic_vector(7 downto 0);
		o_cell_write_01					: out	std_logic_vector(7 downto 0);
		o_cell_write_02					: out	std_logic_vector(7 downto 0);
		o_cell_write_03					: out	std_logic_vector(7 downto 0);

		o_data_read						: out	std_logic_vector(31 downto 0)
	);
	end component;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_addr_mem_00				: std_logic_vector(31 downto 0);							-- Address (Mem 00)
	signal r_addr_mem_01				: std_logic_vector(31 downto 0);							-- Address (Mem 01)
	signal r_addr_mem_02				: std_logic_vector(31 downto 0);							-- Address (Mem 02)
	signal r_addr_mem_03				: std_logic_vector(31 downto 0);							-- Address (Mem 03)

	signal r_data_in_mem_00				: std_logic_vector(7 downto 0);						    	-- Data In (Mem 00)
	signal r_data_in_mem_01				: std_logic_vector(7 downto 0);						    	-- Data In (Mem 01)
	signal r_data_in_mem_02				: std_logic_vector(7 downto 0);						    	-- Data In (Mem 02)
	signal r_data_in_mem_03				: std_logic_vector(7 downto 0);						    	-- Data In (Mem 03)

	signal r_data_out_mem_00			: std_logic_vector(7 downto 0);						    	-- Data Out (Mem 00)
	signal r_data_out_mem_01			: std_logic_vector(7 downto 0);						    	-- Data Out (Mem 01)
	signal r_data_out_mem_02			: std_logic_vector(7 downto 0);						    	-- Data Out (Mem 02)
	signal r_data_out_mem_03			: std_logic_vector(7 downto 0);						    	-- Data Out (Mem 03)

	signal w_rw_mem_00					: std_logic;												-- Memory Device Read/Write 00
	signal w_rw_mem_01					: std_logic;												-- Memory Device Read/Write 01
	signal w_rw_mem_02					: std_logic;												-- Memory Device Read/Write 02
	signal w_rw_mem_03					: std_logic;												-- Memory Device Read/Write 03

	signal r_pc_addr					: std_logic_vector(31 downto 0);							-- Addressable Program Counter

	signal r_instruction_00				: std_logic_vector(7 downto 0);								-- Instruction Byte 00
	signal r_instruction_01				: std_logic_vector(7 downto 0);								-- Instruction Byte 01
	signal r_instruction_02				: std_logic_vector(7 downto 0);								-- Instruction Byte 02
	signal r_instruction_03				: std_logic_vector(7 downto 0);								-- Instruction Byte 03


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- DATA ROUTING INSTANTIATION
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate Memory Data Routing
	DATA_ROUTE_00 : bytewise_route
	generic map (
		g_MAX_MEM_ADDR					=> c_IMEM_SIZE
	)
	port map (
		i_addr							=> i_cpu_addr,
		i_rw_en							=> i_cpu_rw,
		i_data_width					=> i_cpu_dw,

		i_data_write					=> i_cpu_wr,

		i_cell_read_00					=> r_data_out_mem_00,
		i_cell_read_01					=> r_data_out_mem_01,
		i_cell_read_02					=> r_data_out_mem_02,
		i_cell_read_03					=> r_data_out_mem_03,

		o_cell_addr_00					=> r_addr_mem_00,
		o_cell_addr_01					=> r_addr_mem_01,
		o_cell_addr_02					=> r_addr_mem_02,
		o_cell_addr_03					=> r_addr_mem_03,

		o_cell_rw_00					=> w_rw_mem_00,
		o_cell_rw_01					=> w_rw_mem_01,
		o_cell_rw_02					=> w_rw_mem_02,
		o_cell_rw_03					=> w_rw_mem_03,

		o_cell_write_00					=> r_data_in_mem_00,
		o_cell_write_01					=> r_data_in_mem_01,
		o_cell_write_02					=> r_data_in_mem_02,
		o_cell_write_03					=> r_data_in_mem_03,

		o_data_read						=> o_cpu_rd
	);
	

	------------------------------------------------------------------------------------------------------------------------------------
	-- MEMORY CELL INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------
    
	-- Instantiate Memory Cell 00
	MEM_CELL_00 : imem_cell
	generic map ( 
		g_MEM_DATA                      => r_IMEM_00
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                       	=> r_addr_mem_00,
		i_A_rw                         	=> w_rw_mem_00,
		i_A_data_wr                    	=> r_data_in_mem_00,
		o_A_data_rd                   	=> r_data_out_mem_00,

		i_B_addr                      	=> r_pc_addr,
		o_B_data_rd                   	=> r_instruction_00
	);

	-- Instantiate Memory Cell 01
	MEM_CELL_01 : imem_cell
	generic map ( 
		g_MEM_DATA                      => r_IMEM_01
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                       	=> r_addr_mem_01,
		i_A_rw                         	=> w_rw_mem_01,
		i_A_data_wr                    	=> r_data_in_mem_01,
		o_A_data_rd                   	=> r_data_out_mem_01,

		i_B_addr                      	=> r_pc_addr,
		o_B_data_rd                   	=> r_instruction_01
	);

	-- Instantiate Memory Cell 02
	MEM_CELL_02 : imem_cell
	generic map ( 
		g_MEM_DATA                      => r_IMEM_02
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                       	=> r_addr_mem_02,
		i_A_rw                         	=> w_rw_mem_02,
		i_A_data_wr                    	=> r_data_in_mem_02,
		o_A_data_rd                   	=> r_data_out_mem_02,

		i_B_addr                      	=> r_pc_addr,
		o_B_data_rd                   	=> r_instruction_02
	);

	-- Instantiate Memory Cell 03
	MEM_CELL_03 : imem_cell
	generic map ( 
		g_MEM_DATA                      => r_IMEM_03
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                       	=> r_addr_mem_03,
		i_A_rw                         	=> w_rw_mem_03,
		i_A_data_wr                    	=> r_data_in_mem_03,
		o_A_data_rd                   	=> r_data_out_mem_03,

		i_B_addr                      	=> r_pc_addr,
		o_B_data_rd                   	=> r_instruction_03
	);


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign PC relative to IMEM space
	r_pc_addr		<= "00" & i_pc(31 downto 2); 


	-- Assign instruction
	o_instr			<= 	r_instruction_03 & r_instruction_02 & r_instruction_01 & r_instruction_00 when i_reset_n = '1' else
						(others => '0');


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------