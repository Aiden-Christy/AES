----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	HARDWARE ACCELERATOR (HWA) CORES
--  INTEGER MULTIPLICATION
--
--	ENGINEER:		CHRIS MAJOR
--	COMPANY:		RESILIENT COMPUTING
--	DATE:			12/08/2025
--	
--	A PIPELINED 16-BIT MULTIPLICATION COMPONENT USING LOOK-UP TABLES
--	INTENDED FOR USE AS A HARDWARE ACCELERATOR WITHIN RADPC
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
--  LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	--! IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;

	--! IEEE Numeric Standard Library
	use IEEE.NUMERIC_STD.ALL;


	-- RadPC Reach Core Package
	use WORK.REACH_CORE_PKG.all;


----------------------------------------------------------------------------------------------------------------------------------------
--  ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity hwa is
port(
	i_clk						: in		std_logic;										-- Input Clock
	i_reset_n					: in		std_logic;										-- Reset (Active Low)

	o_hwa_id					: out		std_logic_vector(7 downto 0);					-- Hardware Accelerator ID

	i_data_A					: in		std_logic_vector(31 downto 0);					-- Input Data A
	i_data_B					: in		std_logic_vector(31 downto 0);					-- Input Data B
	i_data_C					: in		std_logic_vector(31 downto 0);					-- Input Data C
	i_data_D					: in		std_logic_vector(31 downto 0);					-- Input Data D
	i_data_E					: in		std_logic_vector(31 downto 0);					-- Input Data E
	i_data_F					: in		std_logic_vector(31 downto 0);					-- Input Data F
	i_data_G					: in		std_logic_vector(31 downto 0);					-- Input Data G
	i_data_H					: in		std_logic_vector(31 downto 0);					-- Input Data H

	o_data_A					: out		std_logic_vector(31 downto 0);					-- Output Data A
	o_data_B					: out		std_logic_vector(31 downto 0);					-- Output Data B
	o_data_C					: out		std_logic_vector(31 downto 0);					-- Output Data C
	o_data_D					: out		std_logic_vector(31 downto 0);					-- Output Data D
	o_data_E					: out		std_logic_vector(31 downto 0);					-- Output Data E
	o_data_F					: out		std_logic_vector(31 downto 0);					-- Output Data F
	o_data_G					: out		std_logic_vector(31 downto 0);					-- Output Data G
	o_data_H					: out		std_logic_vector(31 downto 0);					-- Output Data H

	i_hwa_ctrl					: in		std_logic_vector(7 downto 0);					-- Hardware Accelerator Control (CTRL)
	o_hwa_stat					: out		std_logic_vector(15 downto 0);					-- Hardware Accelerator Status (STAT)

	i_hwaio_in					: in		std_logic_vector(31 downto 0);					-- Hardware Accelerator I/O (Read)
	o_hwaio_out					: out		std_logic_vector(31 downto 0);					-- Hardware Accelerator I/O (Write)
	o_hwaio_dir					: out		std_logic_vector(31 downto 0)					-- Hardware Accelerator I/O (Direction)
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
--  ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture hwa_arch of hwa is

	---------------------------------------------------------------------------------------------------------------------------
	--	TYPE DECLARATIONS
	---------------------------------------------------------------------------------------------------------------------------

	-- Type for 4-bit x 4-bit Lookup Table
	type t_MUL_4X4_LUT is array( 0 to 15, 0 to 15 ) of integer range 0 to 255;


	---------------------------------------------------------------------------------------------------------------------------
	--	CONSTANT DECLARATIONS
	---------------------------------------------------------------------------------------------------------------------------

	-- 4-bit x 4-bit Lookup Table
	constant c_MUL_4X4_LUT 		: t_MUL_4X4_LUT := 
	(	
		( 0, 	0,  	0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0 	),
		( 0, 	1,		2,		3,		4,		5,		6,		7,		8,		9,		10,		11,		12,		13,		14,		15	),
		( 0, 	2,		4,		6,		8,		10,		12,		14,		16,		18,		20,		22,		24,		26,		28,		30	),
		( 0, 	3,		6,		9,		12,		15,		18,		21,		24,		27,		30,		33,		36,		39,		42,		45	),
		( 0, 	4,		8,		12,		16,		20,		24,		28,		32,		36,		40,		44,		48,		52,		56,		60	),
		( 0, 	5,		10,		15,		20,		25,		30,		35,		40,		45,		50,		55,		60,		65,		70,		75	),
		( 0, 	6,		12,		18,		24,		30,		36,		42,		48,		54,		60,		66,		72,		78,		84,		90	),
		( 0, 	7,		14,		21,		28,		35,		42,		49,		56,		63,		70,		77,		84,		91,		98,		105	),
		( 0, 	8,		16,		24,		32,		40,		48,		56,		64,		72,		80,		88,		96,		104,	112,	120	),
		( 0, 	9,		18,		27,		36,		45,		54,		63,		72,		81,		90,		99,		108,	117,	126,	135	),
		( 0, 	10,		20,		30,		40,		50,		60,		70,		80,		90,		100,	110,	120,	130,	140,	150	),
		( 0, 	11,		22,		33,		44,		55,		66,		77,		88,		99,		110,	121,	132,	143,	154,	165	),
		( 0, 	12,		24,		36,		48,		60,		72,		84,		96,		108,	120,	132,	144,	156,	168,	180	),
		( 0, 	13,		26,		39,		52,		65,		78,		91,		104,	117,	130,	143,	156,	169,	182,	195	),
		( 0, 	14,		28,		42,		56,		70,		84,		98,		112,	126,	140,	154,	168,	182,	196,	210	),
		( 0, 	15,		30,		45,		60,		75,		90,		105,	120,	135,	150,	165,	180,	195,	210,	225	)
	);


	---------------------------------------------------------------------------------------------------------------------------
	--	SIGNAL DECLARATIONS
	---------------------------------------------------------------------------------------------------------------------------

	signal w_en											: std_logic;						-- Enable

	signal r_product_00									: unsigned(7 downto 0);				-- Partial Product 00
	signal r_product_01									: unsigned(7 downto 0);				-- Partial Product 01
	signal r_product_02									: unsigned(7 downto 0);				-- Partial Product 02
	signal r_product_03									: unsigned(7 downto 0);				-- Partial Product 03
	signal r_product_04									: unsigned(7 downto 0);				-- Partial Product 04
	signal r_product_05									: unsigned(7 downto 0);				-- Partial Product 05
	signal r_product_06									: unsigned(7 downto 0);				-- Partial Product 06
	signal r_product_07									: unsigned(7 downto 0);				-- Partial Product 07
	signal r_product_08									: unsigned(7 downto 0);				-- Partial Product 08
	signal r_product_09									: unsigned(7 downto 0);				-- Partial Product 09
	signal r_product_10									: unsigned(7 downto 0);				-- Partial Product 10
	signal r_product_11									: unsigned(7 downto 0);				-- Partial Product 11
	signal r_product_12									: unsigned(7 downto 0);				-- Partial Product 12
	signal r_product_13									: unsigned(7 downto 0);				-- Partial Product 13
	signal r_product_14									: unsigned(7 downto 0);				-- Partial Product 14
	signal r_product_15									: unsigned(7 downto 0);				-- Partial Product 15

	signal r_sum_00										: unsigned(19 downto 0);			-- Partial Sum 00
	signal r_sum_01										: unsigned(19 downto 0);			-- Partial Sum 01
	signal r_sum_02										: unsigned(19 downto 0);			-- Partial Sum 02
	signal r_sum_03										: unsigned(19 downto 0);			-- Partial Sum 03

	signal r_product	 								: std_logic_vector(31 downto 0);	-- Full Product


begin

	---------------------------------------------------------------------------------------------------------------------------
	--	MULTIPLICATION PROCESS
	---------------------------------------------------------------------------------------------------------------------------

	-- Process to perform full multiplication
	MUL_16x16_PROCESS : process( i_clk, i_reset_n, w_en )
	begin

		-- On reset ...
		if( i_reset_n = '0' ) then

				-- Reset partial products
				r_product_00 	<= (others => '0');
				r_product_01 	<= (others => '0');
				r_product_02 	<= (others => '0');
				r_product_03 	<= (others => '0');

				r_product_04 	<= (others => '0');
				r_product_05 	<= (others => '0');
				r_product_06 	<= (others => '0');
				r_product_07 	<= (others => '0');

				r_product_08 	<= (others => '0');
				r_product_09 	<= (others => '0');
				r_product_10 	<= (others => '0');
				r_product_11 	<= (others => '0');

				r_product_12 	<= (others => '0');
				r_product_13 	<= (others => '0');
				r_product_14 	<= (others => '0');
				r_product_15 	<= (others => '0');

				-- Reset partial sums
				r_sum_00		<= (others => '0');
				r_sum_01		<= (others => '0');
				r_sum_02		<= (others => '0');
				r_sum_03		<= (others => '0');

				-- Reset product
				r_product		<= (others => '0');

		-- On rising clock edge ...
		elsif( rising_edge(i_clk) ) then

			-- On enable ...
			if( w_en = '1' ) then

				-- Assign the partial products from the lookup tables
				r_product_00 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(3 downto 0) ) ), 		to_integer( unsigned( i_data_B(3 downto 0) ) ) 		), 8);
				r_product_01 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(3 downto 0) ) ), 		to_integer( unsigned( i_data_B(7 downto 4) ) ) 		), 8);
				r_product_02 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(3 downto 0) ) ), 		to_integer( unsigned( i_data_B(11 downto 8) ) ) 	), 8);
				r_product_03 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(3 downto 0) ) ), 		to_integer( unsigned( i_data_B(15 downto 12) ) ) 	), 8);

				r_product_04 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(7 downto 4) ) ), 		to_integer( unsigned( i_data_B(3 downto 0) ) ) 		), 8);
				r_product_05 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(7 downto 4) ) ), 		to_integer( unsigned( i_data_B(7 downto 4) ) ) 		), 8);
				r_product_06 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(7 downto 4) ) ), 		to_integer( unsigned( i_data_B(11 downto 8) ) ) 	), 8);
				r_product_07 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(7 downto 4) ) ), 		to_integer( unsigned( i_data_B(15 downto 12) ) ) 	), 8);

				r_product_08 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(11 downto 8) ) ), 	to_integer( unsigned( i_data_B(3 downto 0) ) ) 		), 8);
				r_product_09 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(11 downto 8) ) ), 	to_integer( unsigned( i_data_B(7 downto 4) ) ) 		), 8);
				r_product_10 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(11 downto 8) ) ), 	to_integer( unsigned( i_data_B(11 downto 8) ) ) 	), 8);
				r_product_11 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(11 downto 8) ) ), 	to_integer( unsigned( i_data_B(15 downto 12) ) ) 	), 8);

				r_product_12 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(15 downto 12) ) ), 	to_integer( unsigned( i_data_B(3 downto 0) ) ) 		), 8);
				r_product_13 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(15 downto 12) ) ), 	to_integer( unsigned( i_data_B(7 downto 4) ) ) 		), 8);
				r_product_14 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(15 downto 12) ) ), 	to_integer( unsigned( i_data_B(11 downto 8) ) ) 	), 8);
				r_product_15 	<= to_unsigned( c_MUL_4X4_LUT( to_integer( unsigned( i_data_A(15 downto 12) ) ), 	to_integer( unsigned( i_data_B(15 downto 12) ) ) 	), 8);


				-- Assign the partial sums from the partial products
				r_sum_00		<= (x"000" & r_product_00) + (x"00" & r_product_01 & x"0") + (x"0" & r_product_02 & x"00") + (r_product_03 & x"000");
				r_sum_01		<= (x"000" & r_product_04) + (x"00" & r_product_05 & x"0") + (x"0" & r_product_06 & x"00") + (r_product_07 & x"000");
				r_sum_02		<= (x"000" & r_product_08) + (x"00" & r_product_09 & x"0") + (x"0" & r_product_10 & x"00") + (r_product_11 & x"000");
				r_sum_03		<= (x"000" & r_product_12) + (x"00" & r_product_13 & x"0") + (x"0" & r_product_14 & x"00") + (r_product_15 & x"000");


				-- Reset product
				r_product		<= std_logic_vector( ( r_sum_03 & x"000" ) + ( x"0" & r_sum_02 & x"00" ) + ( x"00" & r_sum_01 & x"0" ) + ( x"000" & r_sum_00 ) );

			end if;

		end if;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--  SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign HWA Control Register
	w_en			<= i_hwa_ctrl(0);


	-- Assign HWA ID
	o_hwa_id		<= x"03";


    -- Assign HWA Outputs
    o_data_A		<= r_product; 
    o_data_B		<= (others => '0'); 
    o_data_C		<= (others => '0'); 
    o_data_D		<= (others => '0'); 
    o_data_E		<= (others => '0'); 
    o_data_F		<= (others => '0'); 
    o_data_G		<= (others => '0'); 
    o_data_H		<= (others => '0'); 


    -- Assign HWA Status
    o_hwa_stat		<= (others => '0'); 


    -- Assign HWA Ports
	o_hwaio_out(31 downto 16)	<= r_product(15 downto 0);
	o_hwaio_out(15 downto 8)	<= i_data_B(7 downto 0);
	o_hwaio_out(7 downto 0)		<= i_data_A(7 downto 0);

	o_hwaio_dir                 <= x"FFFFFFFF";



end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
--  END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------