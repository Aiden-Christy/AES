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
-- 	LIBRARIES
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
-- 	ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity dmem is
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
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- 	ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture dmem_arch of dmem is

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the memory cell component
	component dmem_cell is
	generic ( 
		g_MEM_DATA                      : t_DMEM_RAM
	);
	port (
		i_clk                           : in    std_logic;

		i_A_addr                       	: in    std_logic_vector( 31 downto 0 );
		i_A_rw                         	: in    std_logic;
		i_A_data_wr                    	: in    std_logic_vector( 7 downto 0 );
		o_A_data_rd                   	: out   std_logic_vector( 7 downto 0 );

		i_B_addr                      	: in    std_logic_vector( 31 downto 0 );
		i_B_rw                         	: in    std_logic;
		i_B_data_wr                    	: in    std_logic_vector( 7 downto 0 );
		o_B_data_rd                   	: out   std_logic_vector( 7 downto 0 )
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
	-- 	SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_addr_mem_00				: std_logic_vector(31 downto 0);							-- Memory Device 00 Address
	signal r_addr_mem_01				: std_logic_vector(31 downto 0);							-- Memory Device 01 Address
	signal r_addr_mem_02				: std_logic_vector(31 downto 0);							-- Memory Device 02 Address
	signal r_addr_mem_03				: std_logic_vector(31 downto 0);							-- Memory Device 03 Address

	signal r_data_in_mem_00				: std_logic_vector(7 downto 0);						    	-- Memory Device Data In 00
	signal r_data_in_mem_01				: std_logic_vector(7 downto 0);						    	-- Memory Device Data In 01
	signal r_data_in_mem_02				: std_logic_vector(7 downto 0);						    	-- Memory Device Data In 02
	signal r_data_in_mem_03				: std_logic_vector(7 downto 0);						    	-- Memory Device Data In 03

	signal r_data_out_mem_00			: std_logic_vector(7 downto 0);						    	-- Memory Device Data Out 00
	signal r_data_out_mem_01			: std_logic_vector(7 downto 0);						    	-- Memory Device Data Out 01
	signal r_data_out_mem_02			: std_logic_vector(7 downto 0);						    	-- Memory Device Data Out 02
	signal r_data_out_mem_03			: std_logic_vector(7 downto 0);						    	-- Memory Device Data Out 03

	signal w_rw_mem_00					: std_logic;												-- Memory Device Read/Write 00
	signal w_rw_mem_01					: std_logic;												-- Memory Device Read/Write 01
	signal w_rw_mem_02					: std_logic;												-- Memory Device Read/Write 02
	signal w_rw_mem_03					: std_logic;												-- Memory Device Read/Write 03


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	DATA ROUTING INSTANTIATION
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate Memory Data Routing
	DATA_ROUTE_00 : bytewise_route
	generic map (
		g_MAX_MEM_ADDR					=> c_DMEM_SIZE
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
	-- 	MEMORY CELL INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------
    
	-- Flip bits in DMEM if enable is set
	FLIP_DMEM_BITS : if( g_FLIP_BITS = '1' ) generate
	begin

		-- Instantiate Memory Cell 00
		MEM_CELL_00 : dmem_cell
		generic map ( 
			g_MEM_DATA                      => simulate_radiation( r_DMEM_00, g_FLIP_ADDR, g_FLIP_MASK )
		)
		port map (
			i_clk                           => i_clk,

			i_A_addr                       	=> r_addr_mem_00,
			i_A_rw                         	=> w_rw_mem_00,
			i_A_data_wr                    	=> r_data_in_mem_00,
			o_A_data_rd                   	=> r_data_out_mem_00,

			i_B_addr                      	=> i_scrb_addr,
			i_B_rw                         	=> i_scrb_rw,
			i_B_data_wr                    	=> i_scrb_wr(7 downto 0),
			o_B_data_rd                   	=> o_scrb_rd(7 downto 0)
		);

	end generate;


	-- Set default DMEM contents if flip bits is disabled
	DEFAULT_DMEM : if( g_FLIP_BITS = '0' ) generate
	begin

		-- Instantiate Memory Cell 00
		MEM_CELL_00 : dmem_cell
		generic map ( 
			g_MEM_DATA                      => r_DMEM_00
		)
		port map (
			i_clk                           => i_clk,

			i_A_addr                       	=> r_addr_mem_00,
			i_A_rw                         	=> w_rw_mem_00,
			i_A_data_wr                    	=> r_data_in_mem_00,
			o_A_data_rd                   	=> r_data_out_mem_00,

			i_B_addr                      	=> i_scrb_addr,
			i_B_rw                         	=> i_scrb_rw,
			i_B_data_wr                    	=> i_scrb_wr(7 downto 0),
			o_B_data_rd                   	=> o_scrb_rd(7 downto 0)
		);

	end generate;


	-- Instantiate Memory Cell 01
	MEM_CELL_01 : dmem_cell
	generic map ( 
		g_MEM_DATA                      => r_DMEM_01
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                       	=> r_addr_mem_01,
		i_A_rw                         	=> w_rw_mem_01,
		i_A_data_wr                    	=> r_data_in_mem_01,
		o_A_data_rd                   	=> r_data_out_mem_01,

		i_B_addr                      	=> i_scrb_addr,
		i_B_rw                         	=> i_scrb_rw,
		i_B_data_wr                    	=> i_scrb_wr(15 downto 8),
		o_B_data_rd                   	=> o_scrb_rd(15 downto 8)
	);

	-- Instantiate Memory Cell 02
	MEM_CELL_02 : dmem_cell
	generic map ( 
		g_MEM_DATA                      => r_DMEM_02
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                       	=> r_addr_mem_02,
		i_A_rw                         	=> w_rw_mem_02,
		i_A_data_wr                    	=> r_data_in_mem_02,
		o_A_data_rd                   	=> r_data_out_mem_02,

		i_B_addr                      	=> i_scrb_addr,
		i_B_rw                         	=> i_scrb_rw,
		i_B_data_wr                    	=> i_scrb_wr(23 downto 16),
		o_B_data_rd                   	=> o_scrb_rd(23 downto 16)
	);

	-- Instantiate Memory Cell 03
	MEM_CELL_03 : dmem_cell
	generic map ( 
		g_MEM_DATA                      => r_DMEM_03
	)
	port map (
		i_clk                           => i_clk,

		i_A_addr                       	=> r_addr_mem_03,
		i_A_rw                         	=> w_rw_mem_03,
		i_A_data_wr                    	=> r_data_in_mem_03,
		o_A_data_rd                   	=> r_data_out_mem_03,

		i_B_addr                      	=> i_scrb_addr,
		i_B_rw                         	=> i_scrb_rw,
		i_B_data_wr                    	=> i_scrb_wr(31 downto 24),
		o_B_data_rd                   	=> o_scrb_rd(31 downto 24)
	);


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- 	END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------