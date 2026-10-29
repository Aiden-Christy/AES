----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	REACH PROCESSOR CORE MEMORY MANAGEMENT
--  HARDWARE ACCELERATOR MEMORY INTERFACE
--
--	Created by Chris Major
-- 	Resilient Computing
-- 	5/5/2022
--
--!	@file
--!	@brief A component for interfacing any generic Hardware Accelerator (HWA) to RadPC's processor cores via memory-mapped signals.
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
entity mem_hwa is
port(
	i_clk						: in	std_logic;												-- Input Clock
	i_reset_n					: in	std_logic;												-- Active Low Reset

	i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
	i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
	i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
	i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
	o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

	i_hwa_id					: in	std_logic_vector(7 downto 0);							-- Hardware Accelerator Identification (ID)

	i_hwa_read_00				: in 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Read Word 00
	i_hwa_read_01				: in 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Read Word 01
	i_hwa_read_02				: in 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Read Word 02
	i_hwa_read_03				: in 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Read Word 03
	i_hwa_read_04				: in 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Read Word 04
	i_hwa_read_05				: in 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Read Word 05
	i_hwa_read_06				: in 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Read Word 06
	i_hwa_read_07				: in 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Read Word 07

	o_hwa_write_00				: out 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Write Word 00
	o_hwa_write_01				: out 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Write Word 01
	o_hwa_write_02				: out 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Write Word 02
	o_hwa_write_03				: out 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Write Word 03
	o_hwa_write_04				: out 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Write Word 04
	o_hwa_write_05				: out 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Write Word 05
	o_hwa_write_06				: out 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Write Word 06
	o_hwa_write_07				: out 	std_logic_vector(31 downto 0);							-- Hardware Accelerator Write Word 07

	o_hwa_ctrl					: out	std_logic_vector(7 downto 0);							-- Hardware Accelerator Control (CTRL)
	i_hwa_stat					: in	std_logic_vector(15 downto 0);							-- Hardware Accelerator Status (STAT)

	o_pr_decouple				: out	std_logic												-- Partial Reconfiguration Decoupling Enable
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture mem_hwa_arch of mem_hwa is

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the memory data routing component
	component bytewise_route is
	generic(
		g_MAX_MEM_ADDR				: integer	:= 1024
	);
	port (
		i_addr						: in 	std_logic_vector(31 downto 0);
		i_rw_en						: in	std_logic;
		i_data_width				: in	std_logic_vector(2 downto 0);

		i_data_write				: in    std_logic_vector(31 downto 0);

		i_cell_read_00				: in	std_logic_vector(7 downto 0);
		i_cell_read_01				: in	std_logic_vector(7 downto 0);
		i_cell_read_02				: in	std_logic_vector(7 downto 0);
		i_cell_read_03				: in	std_logic_vector(7 downto 0);

		o_cell_addr_00				: out 	std_logic_vector(31 downto 0);
		o_cell_addr_01				: out 	std_logic_vector(31 downto 0);
		o_cell_addr_02				: out 	std_logic_vector(31 downto 0);
		o_cell_addr_03				: out 	std_logic_vector(31 downto 0);

		o_cell_rw_00				: out	std_logic;
		o_cell_rw_01				: out	std_logic;
		o_cell_rw_02				: out	std_logic;
		o_cell_rw_03				: out	std_logic;

		o_cell_write_00				: out	std_logic_vector(7 downto 0);
		o_cell_write_01				: out	std_logic_vector(7 downto 0);
		o_cell_write_02				: out	std_logic_vector(7 downto 0);
		o_cell_write_03				: out	std_logic_vector(7 downto 0);

		o_data_read					: out	std_logic_vector(31 downto 0)
	);
	end component;


	------------------------------------------------------------------------------------------------------------------------------------
	-- CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	constant c_ADDR_SPACE				: integer							:= 128;

	constant c_HWA_ID					: std_logic_vector(29 downto 0)		:= "00" & x"0000000";					-- HWA Identification (ID)

	constant c_HWA_WRITE_00				: std_logic_vector(29 downto 0)		:= "00" & x"0000001";					-- Internal HWA Read Word 00 Address
	constant c_HWA_WRITE_01				: std_logic_vector(29 downto 0)		:= "00" & x"0000002";					-- Internal HWA Read Word 01 Address
	constant c_HWA_WRITE_02				: std_logic_vector(29 downto 0)		:= "00" & x"0000003";					-- Internal HWA Read Word 02 Address
	constant c_HWA_WRITE_03				: std_logic_vector(29 downto 0)		:= "00" & x"0000004";					-- Internal HWA Read Word 03 Address
	constant c_HWA_WRITE_04				: std_logic_vector(29 downto 0)		:= "00" & x"0000005";					-- Internal HWA Read Word 04 Address
	constant c_HWA_WRITE_05				: std_logic_vector(29 downto 0)		:= "00" & x"0000006";					-- Internal HWA Read Word 05 Address
	constant c_HWA_WRITE_06				: std_logic_vector(29 downto 0)		:= "00" & x"0000007";					-- Internal HWA Read Word 06 Address
	constant c_HWA_WRITE_07				: std_logic_vector(29 downto 0)		:= "00" & x"0000008";					-- Internal HWA Read Word 07 Address

	constant c_HWA_READ_00				: std_logic_vector(29 downto 0)		:= "00" & x"0000009";					-- Internal HWA Read Word 00 Address
	constant c_HWA_READ_01				: std_logic_vector(29 downto 0)		:= "00" & x"000000A";					-- Internal HWA Read Word 01 Address
	constant c_HWA_READ_02				: std_logic_vector(29 downto 0)		:= "00" & x"000000B";					-- Internal HWA Read Word 02 Address
	constant c_HWA_READ_03				: std_logic_vector(29 downto 0)		:= "00" & x"000000C";					-- Internal HWA Read Word 03 Address
	constant c_HWA_READ_04				: std_logic_vector(29 downto 0)		:= "00" & x"000000D";					-- Internal HWA Read Word 04 Address
	constant c_HWA_READ_05				: std_logic_vector(29 downto 0)		:= "00" & x"000000E";					-- Internal HWA Read Word 05 Address
	constant c_HWA_READ_06				: std_logic_vector(29 downto 0)		:= "00" & x"000000F";					-- Internal HWA Read Word 06 Address
	constant c_HWA_READ_07				: std_logic_vector(29 downto 0)		:= "00" & x"0000010";					-- Internal HWA Read Word 07 Address

	constant c_HWA_CTRL					: std_logic_vector(29 downto 0)		:= "00" & x"0000011";					-- HWA Control Register (CTRL)
	constant c_HWA_STAT					: std_logic_vector(29 downto 0)		:= "00" & x"0000012";					-- HWA Status Register (STAT)

	constant c_HWA_PR_DECOUPLE			: std_logic_vector(29 downto 0)		:= "00" & x"0000020";					-- HWA PR Decouple Enable


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_hwa_write_00				: std_logic_vector(31 downto 0);							-- Internal Hardware Accelerator Write Register 00
	signal r_hwa_write_01				: std_logic_vector(31 downto 0);							-- Internal Hardware Accelerator Write Register 01
	signal r_hwa_write_02				: std_logic_vector(31 downto 0);							-- Internal Hardware Accelerator Write Register 02
	signal r_hwa_write_03				: std_logic_vector(31 downto 0);							-- Internal Hardware Accelerator Write Register 03
	signal r_hwa_write_04				: std_logic_vector(31 downto 0);							-- Internal Hardware Accelerator Write Register 04
	signal r_hwa_write_05				: std_logic_vector(31 downto 0);							-- Internal Hardware Accelerator Write Register 05
	signal r_hwa_write_06				: std_logic_vector(31 downto 0);							-- Internal Hardware Accelerator Write Register 06
	signal r_hwa_write_07				: std_logic_vector(31 downto 0);							-- Internal Hardware Accelerator Write Register 07

	signal r_hwa_ctrl					: std_logic_vector(7 downto 0);							   	-- Hardware Accelerator Control Register

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

	signal w_pr_decouple				: std_logic;												-- PR Decouple


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate Memory Data Routing
	DATA_ROUTE_00 : bytewise_route
	generic map (
		g_MAX_MEM_ADDR					=> c_ADDR_SPACE
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
	-- MEMORY READ/WRITE
	------------------------------------------------------------------------------------------------------------------------------------

	-- WRITE to Memory Device 00
	MEM_WRITE_00 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear GPIO
		if( i_reset_n = '0' ) then

			-- Reset 1st byte of all values
			r_hwa_write_00(7 downto 0) 		<= x"00";
			r_hwa_write_01(7 downto 0) 		<= x"00";
			r_hwa_write_02(7 downto 0) 		<= x"00";
			r_hwa_write_03(7 downto 0) 		<= x"00";
			r_hwa_write_04(7 downto 0) 		<= x"00";
			r_hwa_write_05(7 downto 0) 		<= x"00";
			r_hwa_write_06(7 downto 0) 		<= x"00";
			r_hwa_write_07(7 downto 0) 		<= x"00";

			r_hwa_ctrl						<= x"00";

			w_pr_decouple					<= '0';


		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_00 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_00(29 downto 0) ) is

					-- HWA Identifcation (ID) Register
					when c_HWA_ID							=> -- (Read Only)

					-- Handle writing Hardware Accelerator Write 00 (1st Byte)
					when c_HWA_WRITE_00 					=> 	r_hwa_write_00(7 downto 0) 		<= r_data_in_mem_00;

					-- Handle writing Hardware Accelerator Write 01 (1st Byte)
					when c_HWA_WRITE_01 					=> 	r_hwa_write_01(7 downto 0) 		<= r_data_in_mem_00;

					-- Handle writing Hardware Accelerator Write 02 (1st Byte)
					when c_HWA_WRITE_02 					=> 	r_hwa_write_02(7 downto 0) 		<= r_data_in_mem_00;

					-- Handle writing Hardware Accelerator Write 03 (1st Byte)
					when c_HWA_WRITE_03 					=> 	r_hwa_write_03(7 downto 0) 		<= r_data_in_mem_00;

					-- Handle writing Hardware Accelerator Write 04 (1st Byte)
					when c_HWA_WRITE_04 					=> 	r_hwa_write_04(7 downto 0) 		<= r_data_in_mem_00;
					
					-- Handle writing Hardware Accelerator Write 05 (1st Byte)
					when c_HWA_WRITE_05 					=> 	r_hwa_write_05(7 downto 0) 		<= r_data_in_mem_00;
					
					-- Handle writing Hardware Accelerator Write 06 (1st Byte)
					when c_HWA_WRITE_06 					=> 	r_hwa_write_06(7 downto 0) 		<= r_data_in_mem_00;
					
					-- Handle writing Hardware Accelerator Write 07 (1st Byte)
					when c_HWA_WRITE_07 					=> 	r_hwa_write_07(7 downto 0) 		<= r_data_in_mem_00;

					-- HWA Control Register
					when c_HWA_CTRL							=> 	r_hwa_ctrl						<= r_data_in_mem_00;

					-- HWA Status Register
					when c_HWA_STAT							=> 	-- (Read Only)

					-- HWA PR Decouple
					when c_HWA_PR_DECOUPLE					=> 	w_pr_decouple					<= r_data_in_mem_00(0);

					-- Handle defaults
					when others								=>	-- Do nothing

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_00(29 downto 0) ) is

					-- HWA Identifcation (ID) Register
					when c_HWA_ID							=> 	r_data_out_mem_00 				<= i_hwa_id;

					-- Handle reading Hardware Accelerator Write 00 (1st Byte)
					when c_HWA_WRITE_00 					=> 	r_data_out_mem_00 				<= r_hwa_write_00(7 downto 0);

					-- Handle reading Hardware Accelerator Write 01 (1st Byte)
					when c_HWA_WRITE_01 					=> 	r_data_out_mem_00 				<= r_hwa_write_01(7 downto 0);

					-- Handle reading Hardware Accelerator Write 02 (1st Byte)
					when c_HWA_WRITE_02 					=> 	r_data_out_mem_00 				<= r_hwa_write_02(7 downto 0);

					-- Handle reading Hardware Accelerator Write 03 (1st Byte)
					when c_HWA_WRITE_03 					=> 	r_data_out_mem_00 				<= r_hwa_write_03(7 downto 0);

					-- Handle reading Hardware Accelerator Write 04 (1st Byte)
					when c_HWA_WRITE_04 					=> 	r_data_out_mem_00 				<= r_hwa_write_04(7 downto 0);
					
					-- Handle reading Hardware Accelerator Write 05 (1st Byte)
					when c_HWA_WRITE_05 					=> 	r_data_out_mem_00 				<= r_hwa_write_05(7 downto 0);
					
					-- Handle reading Hardware Accelerator Write 06 (1st Byte)
					when c_HWA_WRITE_06 					=> 	r_data_out_mem_00 				<= r_hwa_write_06(7 downto 0);
					
					-- Handle reading Hardware Accelerator Write 07 (1st Byte)
					when c_HWA_WRITE_07 					=> 	r_data_out_mem_00 				<= r_hwa_write_07(7 downto 0);


					-- Handle reading Hardware Accelerator Read 00 (1st Byte)
					when c_HWA_READ_00 						=> 	r_data_out_mem_00 				<= i_hwa_read_00(7 downto 0);

					-- Handle reading Hardware Accelerator Read 01 (1st Byte)
					when c_HWA_READ_01 						=> 	r_data_out_mem_00 				<= i_hwa_read_01(7 downto 0);

					-- Handle reading Hardware Accelerator Read 02 (1st Byte)
					when c_HWA_READ_02 						=> 	r_data_out_mem_00 				<= i_hwa_read_02(7 downto 0);

					-- Handle reading Hardware Accelerator Read 03 (1st Byte)
					when c_HWA_READ_03 						=> 	r_data_out_mem_00 				<= i_hwa_read_03(7 downto 0);

					-- Handle reading Hardware Accelerator Read 04 (1st Byte)
					when c_HWA_READ_04 						=> 	r_data_out_mem_00 				<= i_hwa_read_04(7 downto 0);
					
					-- Handle reading Hardware Accelerator Read 05 (1st Byte)
					when c_HWA_READ_05 						=> 	r_data_out_mem_00 				<= i_hwa_read_05(7 downto 0);
					
					-- Handle reading Hardware Accelerator Read 06 (1st Byte)
					when c_HWA_READ_06 						=> 	r_data_out_mem_00 				<= i_hwa_read_06(7 downto 0);
					
					-- Handle reading Hardware Accelerator Read 07 (1st Byte)
					when c_HWA_READ_07 						=> 	r_data_out_mem_00 				<= i_hwa_read_07(7 downto 0);

					-- HWA Control Register
					when c_HWA_CTRL							=> 	r_data_out_mem_00				<= r_hwa_ctrl;

					-- HWA Status Register
					when c_HWA_STAT							=> 	r_data_out_mem_00 				<= i_hwa_stat(7 downto 0);

					-- HWA PR Decouple
					when c_HWA_PR_DECOUPLE					=> 	r_data_out_mem_00				<= "0000000" & w_pr_decouple;

					-- Handle defaults
					when others								=> 	r_data_out_mem_00 				<= x"00";

				end case;

			end if;

		end if;

	end process;		


	-- WRITE to Memory Device 01
	MEM_WRITE_01 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear GPIO
		if( i_reset_n = '0' ) then

			-- Reset 2nd byte of all values
			r_hwa_write_00(15 downto 8) 	<= x"00";
			r_hwa_write_01(15 downto 8) 	<= x"00";
			r_hwa_write_02(15 downto 8) 	<= x"00";
			r_hwa_write_03(15 downto 8) 	<= x"00";
			r_hwa_write_04(15 downto 8) 	<= x"00";
			r_hwa_write_05(15 downto 8) 	<= x"00";
			r_hwa_write_06(15 downto 8) 	<= x"00";
			r_hwa_write_07(15 downto 8) 	<= x"00";


		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_01 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_01(29 downto 0) ) is

					-- HWA Identifcation (ID) Register
					when c_HWA_ID							=> -- (Empty)

					-- Handle writing Hardware Accelerator Write 00 (2nd Byte)
					when c_HWA_WRITE_00 					=> 	r_hwa_write_00(15 downto 8) 	<= r_data_in_mem_01;

					-- Handle writing Hardware Accelerator Write 01 (2nd Byte)
					when c_HWA_WRITE_01 					=> 	r_hwa_write_01(15 downto 8) 	<= r_data_in_mem_01;

					-- Handle writing Hardware Accelerator Write 02 (2nd Byte)
					when c_HWA_WRITE_02 					=> 	r_hwa_write_02(15 downto 8)		<= r_data_in_mem_01;

					-- Handle writing Hardware Accelerator Write 03 (2nd Byte)
					when c_HWA_WRITE_03 					=> 	r_hwa_write_03(15 downto 8)		<= r_data_in_mem_01;

					-- Handle writing Hardware Accelerator Write 04 (2nd Byte)
					when c_HWA_WRITE_04 					=> 	r_hwa_write_04(15 downto 8)		<= r_data_in_mem_01;
					
					-- Handle writing Hardware Accelerator Write 05 (2nd Byte)
					when c_HWA_WRITE_05 					=> 	r_hwa_write_05(15 downto 8)		<= r_data_in_mem_01;
					
					-- Handle writing Hardware Accelerator Write 06 (2nd Byte)
					when c_HWA_WRITE_06 					=> 	r_hwa_write_06(15 downto 8)		<= r_data_in_mem_01;
					
					-- Handle writing Hardware Accelerator Write 07 (2nd Byte)
					when c_HWA_WRITE_07 					=> 	r_hwa_write_07(15 downto 8)		<= r_data_in_mem_01;

					-- HWA Control Register
					when c_HWA_CTRL							=> 	-- (Read Only)

					-- HWA Status Register
					when c_HWA_STAT							=> 	-- (Read Only)


					-- Handle defaults
					when others								=>	-- Do nothing

				end case;

			else

				-- Check the address to write
				case( r_addr_mem_01(29 downto 0) ) is

					-- HWA Identifcation (ID) Register
					when c_HWA_ID							=> 	r_data_out_mem_01 				<= x"00";

					-- Handle reading Hardware Accelerator Write 00 (2nd Byte)
					when c_HWA_WRITE_00 					=> 	r_data_out_mem_01 				<= r_hwa_write_00(15 downto 8);

					-- Handle reading Hardware Accelerator Write 01 (2nd Byte)
					when c_HWA_WRITE_01 					=> 	r_data_out_mem_01 				<= r_hwa_write_01(15 downto 8);

					-- Handle reading Hardware Accelerator Write 02 (2nd Byte)
					when c_HWA_WRITE_02 					=> 	r_data_out_mem_01 				<= r_hwa_write_02(15 downto 8);

					-- Handle reading Hardware Accelerator Write 03 (2nd Byte)
					when c_HWA_WRITE_03 					=> 	r_data_out_mem_01 				<= r_hwa_write_03(15 downto 8);

					-- Handle reading Hardware Accelerator Write 04 (2nd Byte)
					when c_HWA_WRITE_04 					=> 	r_data_out_mem_01 				<= r_hwa_write_04(15 downto 8);
					
					-- Handle reading Hardware Accelerator Write 05 (2nd Byte)
					when c_HWA_WRITE_05 					=> 	r_data_out_mem_01 				<= r_hwa_write_05(15 downto 8);
					
					-- Handle reading Hardware Accelerator Write 06 (2nd Byte)
					when c_HWA_WRITE_06 					=> 	r_data_out_mem_01 				<= r_hwa_write_06(15 downto 8);
					
					-- Handle reading Hardware Accelerator Write 07 (2nd Byte)
					when c_HWA_WRITE_07 					=> 	r_data_out_mem_01 				<= r_hwa_write_07(15 downto 8);


					-- Handle reading Hardware Accelerator Read 00 (2nd Byte)
					when c_HWA_READ_00 						=> 	r_data_out_mem_01 				<= i_hwa_read_00(15 downto 8);

					-- Handle reading Hardware Accelerator Read 01 (2nd Byte)
					when c_HWA_READ_01 						=> 	r_data_out_mem_01 				<= i_hwa_read_01(15 downto 8);

					-- Handle reading Hardware Accelerator Read 02 (2nd Byte)
					when c_HWA_READ_02 						=> 	r_data_out_mem_01 				<= i_hwa_read_02(15 downto 8);

					-- Handle reading Hardware Accelerator Read 03 (2nd Byte)
					when c_HWA_READ_03 						=> 	r_data_out_mem_01 				<= i_hwa_read_03(15 downto 8);

					-- Handle reading Hardware Accelerator Read 04 (2nd Byte)
					when c_HWA_READ_04 						=> 	r_data_out_mem_01 				<= i_hwa_read_04(15 downto 8);
					
					-- Handle reading Hardware Accelerator Read 05 (2nd Byte)
					when c_HWA_READ_05 						=> 	r_data_out_mem_01 				<= i_hwa_read_05(15 downto 8);
					
					-- Handle reading Hardware Accelerator Read 06 (2nd Byte)
					when c_HWA_READ_06 						=> 	r_data_out_mem_01 				<= i_hwa_read_06(15 downto 8);
					
					-- Handle reading Hardware Accelerator Read 07 (2nd Byte)
					when c_HWA_READ_07 						=> 	r_data_out_mem_01 				<= i_hwa_read_07(15 downto 8);

					-- HWA Control Register
					when c_HWA_CTRL							=> 	r_data_out_mem_01 				<= x"00";

					-- HWA Status Register
					when c_HWA_STAT							=> 	r_data_out_mem_01 				<= i_hwa_stat(15 downto 8);

					-- Handle defaults
					when others								=> 	r_data_out_mem_01 				<= x"00";

				end case;

			end if;

		end if;

	end process;	


	-- WRITE to Memory Device 02
	MEM_WRITE_02 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear GPIO
		if( i_reset_n = '0' ) then

			-- Reset 3rd byte of all values
			r_hwa_write_00(23 downto 16) 	<= x"00";
			r_hwa_write_01(23 downto 16) 	<= x"00";
			r_hwa_write_02(23 downto 16) 	<= x"00";
			r_hwa_write_03(23 downto 16) 	<= x"00";
			r_hwa_write_04(23 downto 16) 	<= x"00";
			r_hwa_write_05(23 downto 16) 	<= x"00";
			r_hwa_write_06(23 downto 16) 	<= x"00";
			r_hwa_write_07(23 downto 16) 	<= x"00";


		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_02 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_02(29 downto 0) ) is

					-- HWA Identifcation (ID) Register
					when c_HWA_ID							=> -- (Empty)

					-- Handle writing Hardware Accelerator Write 00 (3rd Byte)
					when c_HWA_WRITE_00 					=> 	r_hwa_write_00(23 downto 16) 	<= r_data_in_mem_02;

					-- Handle writing Hardware Accelerator Write 01 (3rd Byte)
					when c_HWA_WRITE_01 					=> 	r_hwa_write_01(23 downto 16) 	<= r_data_in_mem_02;

					-- Handle writing Hardware Accelerator Write 02 (3rd Byte)
					when c_HWA_WRITE_02 					=> 	r_hwa_write_02(23 downto 16)	<= r_data_in_mem_02;

					-- Handle writing Hardware Accelerator Write 03 (3rd Byte)
					when c_HWA_WRITE_03 					=> 	r_hwa_write_03(23 downto 16)	<= r_data_in_mem_02;

					-- Handle writing Hardware Accelerator Write 04 (3rd Byte)
					when c_HWA_WRITE_04 					=> 	r_hwa_write_04(23 downto 16)	<= r_data_in_mem_02;
					
					-- Handle writing Hardware Accelerator Write 05 (3rd Byte)
					when c_HWA_WRITE_05 					=> 	r_hwa_write_05(23 downto 16)	<= r_data_in_mem_02;
					
					-- Handle writing Hardware Accelerator Write 06 (3rd Byte)
					when c_HWA_WRITE_06 					=> 	r_hwa_write_06(23 downto 16)	<= r_data_in_mem_02;
					
					-- Handle writing Hardware Accelerator Write 07 (3rd Byte)
					when c_HWA_WRITE_07 					=> 	r_hwa_write_07(23 downto 16)	<= r_data_in_mem_02;


					-- Handle defaults
					when others								=>	-- Do nothing

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_02(29 downto 0) ) is

					-- HWA Identifcation (ID) Register
					when c_HWA_ID							=> 	r_data_out_mem_02 				<= x"00";

					-- Handle reading Hardware Accelerator Write 00 (3rd Byte)
					when c_HWA_WRITE_00 					=> 	r_data_out_mem_02 				<= r_hwa_write_00(23 downto 16);

					-- Handle reading Hardware Accelerator Write 01 (3rd Byte)
					when c_HWA_WRITE_01 					=> 	r_data_out_mem_02 				<= r_hwa_write_01(23 downto 16);

					-- Handle reading Hardware Accelerator Write 02 (3rd Byte)
					when c_HWA_WRITE_02 					=> 	r_data_out_mem_02 				<= r_hwa_write_02(23 downto 16);

					-- Handle reading Hardware Accelerator Write 03 (3rd Byte)
					when c_HWA_WRITE_03 					=> 	r_data_out_mem_02 				<= r_hwa_write_03(23 downto 16);

					-- Handle reading Hardware Accelerator Write 04 (3rd Byte)
					when c_HWA_WRITE_04 					=> 	r_data_out_mem_02 				<= r_hwa_write_04(23 downto 16);
					
					-- Handle reading Hardware Accelerator Write 05 (3rd Byte)
					when c_HWA_WRITE_05 					=> 	r_data_out_mem_02 				<= r_hwa_write_05(23 downto 16);
					
					-- Handle reading Hardware Accelerator Write 06 (3rd Byte)
					when c_HWA_WRITE_06 					=> 	r_data_out_mem_02 				<= r_hwa_write_06(23 downto 16);
					
					-- Handle reading Hardware Accelerator Write 07 (3rd Byte)
					when c_HWA_WRITE_07 					=> 	r_data_out_mem_02 				<= r_hwa_write_07(23 downto 16);


					-- Handle reading Hardware Accelerator Read 00 (3rd Byte)
					when c_HWA_READ_00 						=> 	r_data_out_mem_02 				<= i_hwa_read_00(23 downto 16);

					-- Handle reading Hardware Accelerator Read 01 (3rd Byte)
					when c_HWA_READ_01 						=> 	r_data_out_mem_02 				<= i_hwa_read_01(23 downto 16);

					-- Handle reading Hardware Accelerator Read 02 (3rd Byte)
					when c_HWA_READ_02 						=> 	r_data_out_mem_02 				<= i_hwa_read_02(23 downto 16);

					-- Handle reading Hardware Accelerator Read 03 (3rd Byte)
					when c_HWA_READ_03 						=> 	r_data_out_mem_02 				<= i_hwa_read_03(23 downto 16);

					-- Handle reading Hardware Accelerator Read 04 (3rd Byte)
					when c_HWA_READ_04 						=> 	r_data_out_mem_02 				<= i_hwa_read_04(23 downto 16);
					
					-- Handle reading Hardware Accelerator Read 05 (3rd Byte)
					when c_HWA_READ_05 						=> 	r_data_out_mem_02 				<= i_hwa_read_05(23 downto 16);
					
					-- Handle reading Hardware Accelerator Read 06 (3rd Byte)
					when c_HWA_READ_06 						=> 	r_data_out_mem_02 				<= i_hwa_read_06(23 downto 16);
					
					-- Handle reading Hardware Accelerator Read 07 (3rd Byte)
					when c_HWA_READ_07 						=> 	r_data_out_mem_02 				<= i_hwa_read_07(23 downto 16);

					-- HWA Control Register
					when c_HWA_CTRL							=> 	r_data_out_mem_02 				<= x"00";

					-- HWA Status Register
					when c_HWA_STAT							=> 	r_data_out_mem_02 				<= x"00";

					-- Handle defaults
					when others								=> 	r_data_out_mem_02 				<= x"00";

				end case;

			end if;

		end if;

	end process;	


	-- WRITE to Memory Device 03
	MEM_WRITE_03 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear GPIO
		if( i_reset_n = '0' ) then

			-- Reset 4th byte of all values
			r_hwa_write_00(31 downto 24) 	<= x"00";
			r_hwa_write_01(31 downto 24) 	<= x"00";
			r_hwa_write_02(31 downto 24) 	<= x"00";
			r_hwa_write_03(31 downto 24) 	<= x"00";
			r_hwa_write_04(31 downto 24) 	<= x"00";
			r_hwa_write_05(31 downto 24) 	<= x"00";
			r_hwa_write_06(31 downto 24) 	<= x"00";
			r_hwa_write_07(31 downto 24) 	<= x"00";


		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_03 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					-- HWA Identifcation (ID) Register
					when c_HWA_ID							=> -- (Empty)

					-- Handle writing Hardware Accelerator Write 00 (4th Byte)
					when c_HWA_WRITE_00 					=> 	r_hwa_write_00(31 downto 24) 	<= r_data_in_mem_03;

					-- Handle writing Hardware Accelerator Write 01 (4th Byte)
					when c_HWA_WRITE_01 					=> 	r_hwa_write_01(31 downto 24) 	<= r_data_in_mem_03;

					-- Handle writing Hardware Accelerator Write 02 (4th Byte)
					when c_HWA_WRITE_02 					=> 	r_hwa_write_02(31 downto 24)	<= r_data_in_mem_03;

					-- Handle writing Hardware Accelerator Write 03 (4th Byte)
					when c_HWA_WRITE_03 					=> 	r_hwa_write_03(31 downto 24)	<= r_data_in_mem_03;

					-- Handle writing Hardware Accelerator Write 04 (4th Byte)
					when c_HWA_WRITE_04 					=> 	r_hwa_write_04(31 downto 24)	<= r_data_in_mem_03;
					
					-- Handle writing Hardware Accelerator Write 05 (4th Byte)
					when c_HWA_WRITE_05 					=> 	r_hwa_write_05(31 downto 24)	<= r_data_in_mem_03;
					
					-- Handle writing Hardware Accelerator Write 06 (4th Byte)
					when c_HWA_WRITE_06 					=> 	r_hwa_write_06(31 downto 24)	<= r_data_in_mem_03;
					
					-- Handle writing Hardware Accelerator Write 07 (4th Byte)
					when c_HWA_WRITE_07 					=> 	r_hwa_write_07(31 downto 24)	<= r_data_in_mem_03;

					-- HWA Control Register
					when c_HWA_CTRL							=> 	-- (Read Only)

					-- HWA Status Register
					when c_HWA_STAT							=> 	-- (Read Only)

					-- Handle defaults
					when others								=>	-- Do nothing

				end case;

			else

				-- Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					-- HWA Identifcation (ID) Register
					when c_HWA_ID							=> 	r_data_out_mem_03 				<= x"00";

					-- Handle reading Hardware Accelerator Write 00 (4th Byte)
					when c_HWA_WRITE_00 					=> 	r_data_out_mem_03 				<= r_hwa_write_00(31 downto 24);

					-- Handle reading Hardware Accelerator Write 01 (4th Byte)
					when c_HWA_WRITE_01 					=> 	r_data_out_mem_03 				<= r_hwa_write_01(31 downto 24);

					-- Handle reading Hardware Accelerator Write 02 (4th Byte)
					when c_HWA_WRITE_02 					=> 	r_data_out_mem_03 				<= r_hwa_write_02(31 downto 24);

					-- Handle reading Hardware Accelerator Write 03 (4th Byte)
					when c_HWA_WRITE_03 					=> 	r_data_out_mem_03 				<= r_hwa_write_03(31 downto 24);

					-- Handle reading Hardware Accelerator Write 04 (4th Byte)
					when c_HWA_WRITE_04 					=> 	r_data_out_mem_03 				<= r_hwa_write_04(31 downto 24);
					
					-- Handle reading Hardware Accelerator Write 05 (4th Byte)
					when c_HWA_WRITE_05 					=> 	r_data_out_mem_03 				<= r_hwa_write_05(31 downto 24);
					
					-- Handle reading Hardware Accelerator Write 06 (4th Byte)
					when c_HWA_WRITE_06 					=> 	r_data_out_mem_03 				<= r_hwa_write_06(31 downto 24);
					
					-- Handle reading Hardware Accelerator Write 07 (4th Byte)
					when c_HWA_WRITE_07 					=> 	r_data_out_mem_03 				<= r_hwa_write_07(31 downto 24);


					-- Handle reading Hardware Accelerator Read 00 (4th Byte)
					when c_HWA_READ_00 						=> 	r_data_out_mem_03 				<= i_hwa_read_00(31 downto 24);

					-- Handle reading Hardware Accelerator Read 01 (4th Byte)
					when c_HWA_READ_01 						=> 	r_data_out_mem_03 				<= i_hwa_read_01(31 downto 24);

					-- Handle reading Hardware Accelerator Read 02 (4th Byte)
					when c_HWA_READ_02 						=> 	r_data_out_mem_03 				<= i_hwa_read_02(31 downto 24);

					-- Handle reading Hardware Accelerator Read 03 (4th Byte)
					when c_HWA_READ_03 						=> 	r_data_out_mem_03 				<= i_hwa_read_03(31 downto 24);

					-- Handle reading Hardware Accelerator Read 04 (4th Byte)
					when c_HWA_READ_04 						=> 	r_data_out_mem_03 				<= i_hwa_read_04(31 downto 24);
					
					-- Handle reading Hardware Accelerator Read 05 (4th Byte)
					when c_HWA_READ_05 						=> 	r_data_out_mem_03 				<= i_hwa_read_05(31 downto 24);
					
					-- Handle reading Hardware Accelerator Read 06 (4th Byte)
					when c_HWA_READ_06 						=> 	r_data_out_mem_03 				<= i_hwa_read_06(31 downto 24);
					
					-- Handle reading Hardware Accelerator Read 07 (4th Byte)
					when c_HWA_READ_07 						=> 	r_data_out_mem_03 				<= i_hwa_read_07(31 downto 24);

					-- HWA Control Register
					when c_HWA_CTRL							=> 	r_data_out_mem_03 				<= x"00";

					-- HWA Status Register
					when c_HWA_STAT							=> 	r_data_out_mem_03 				<= x"00";

					-- Handle defaults
					when others								=> 	r_data_out_mem_03 				<= x"00";

				end case;

			end if;

		end if;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign internal write signals to outputs
	o_hwa_write_00	<= 	r_hwa_write_00;
	o_hwa_write_01	<= 	r_hwa_write_01;
	o_hwa_write_02	<= 	r_hwa_write_02;
	o_hwa_write_03	<= 	r_hwa_write_03;
	o_hwa_write_04	<= 	r_hwa_write_04;
	o_hwa_write_05	<= 	r_hwa_write_05;
	o_hwa_write_06	<= 	r_hwa_write_06;
	o_hwa_write_07	<= 	r_hwa_write_07;

	o_hwa_ctrl		<=	r_hwa_ctrl;


	-- Assign PR decouple signal
	o_pr_decouple	<= w_pr_decouple;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------