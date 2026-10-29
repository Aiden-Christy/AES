----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  MEMORY MANAGEMENT UNIT (MMU)
--	ANALOG-TO-DIGITAL CONVERTER (ADC) MEMORY DEVICE
--
--	CREATED BY CHRIS MAJOR
--  RESILIENT COMPUTING
-- 	06/05/2022
--
--!	@file
--!	@brief A memory map for the Analog To Digital Converter (ADC) memory device.
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
entity mem_adc is
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
end entity;
	
	
----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture mem_adc_arch of mem_adc is

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

	constant c_ADDR_SPACE				: integer							:= 4;					--! Total number of address spaces

	constant c_ADC_DATA					: std_logic_vector(29 downto 0)		:= "00" & x"0000000";	--! ADC Data


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_adc_addr					: std_logic_vector(7 downto 0);								--! ADC Address

	signal r_addr_mem_00				: std_logic_vector(31 downto 0);							--! Memory Device 00 Address
	signal r_addr_mem_01				: std_logic_vector(31 downto 0);							--! Memory Device 01 Address
	signal r_addr_mem_02				: std_logic_vector(31 downto 0);							--! Memory Device 02 Address
	signal r_addr_mem_03				: std_logic_vector(31 downto 0);							--! Memory Device 03 Address

	signal r_data_in_mem_00				: std_logic_vector(7 downto 0);						    	--! Memory Device Data In 00
	signal r_data_in_mem_01				: std_logic_vector(7 downto 0);						    	--! Memory Device Data In 01
	signal r_data_in_mem_02				: std_logic_vector(7 downto 0);						    	--! Memory Device Data In 02
	signal r_data_in_mem_03				: std_logic_vector(7 downto 0);						    	--! Memory Device Data In 03

	signal r_data_out_mem_00			: std_logic_vector(7 downto 0);						    	--! Memory Device Data Out 00
	signal r_data_out_mem_01			: std_logic_vector(7 downto 0);						    	--! Memory Device Data Out 01
	signal r_data_out_mem_02			: std_logic_vector(7 downto 0);						    	--! Memory Device Data Out 02
	signal r_data_out_mem_03			: std_logic_vector(7 downto 0);						    	--! Memory Device Data Out 03

	signal w_rw_mem_00					: std_logic;												--! Memory Device Read/Write 00
	signal w_rw_mem_01					: std_logic;												--! Memory Device Read/Write 01
	signal w_rw_mem_02					: std_logic;												--! Memory Device Read/Write 02
	signal w_rw_mem_03					: std_logic;												--! Memory Device Read/Write 03

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

		-- On reset, clear ADC Channel
		if( i_reset_n = '0' ) then

			r_adc_addr		<= (others => '0');


		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_00 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_00(29 downto 0) ) is

					-- Handle writing ADC Data (Channel)
					when c_ADC_DATA 						=> 	r_adc_addr 			<= r_data_in_mem_00;

					-- Handle defaults
					when others								=>	-- (Do Nothing)

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_00(29 downto 0) ) is

					-- Handle reading ADC Data (Channel)
					when c_ADC_DATA 						=> 	r_data_out_mem_00 	<= r_adc_addr;

					-- Handle defaults
					when others								=> 	r_data_out_mem_00 	<= x"00";

				end case;

			end if;

		end if;

	end process;


	-- WRITE to Memory Device 01
	MEM_WRITE_01 : process( i_clk, i_reset_n )
	begin

		-- On reset ...
		if( i_reset_n = '0' ) then

			-- (Do nothing)

		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_01 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_01(29 downto 0) ) is

					-- Handle defaults
					when others								=>	-- (Do Nothing)

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_01(29 downto 0) ) is

					-- Handle reading ADC Data (Channel)
					when c_ADC_DATA 						=> 	r_data_out_mem_01 	<= i_adc_data_read(7 downto 0);

					-- Handle defaults
					when others								=> 	r_data_out_mem_01 	<= x"00";

				end case;

			end if;

		end if;

	end process;	


	-- WRITE to Memory Device 02
	MEM_WRITE_02 : process( i_clk, i_reset_n )
	begin

		-- On reset ...
		if( i_reset_n = '0' ) then

			-- (Do Nothing)

		-- On rising clock edge ...
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_02 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_02(29 downto 0) ) is

					-- Handle defaults
					when others								=>	-- (Do Nothing)

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_02(29 downto 0) ) is

					-- Handle reading ADC Data (Channel)
					when c_ADC_DATA 						=> 	r_data_out_mem_02 	<= i_adc_data_read(15 downto 8);

					-- Handle defaults
					when others								=> 	r_data_out_mem_02 	<= x"00";

				end case;

			end if;

		end if;

	end process;	


	-- WRITE to Memory Device 03
	MEM_WRITE_03 : process( i_clk, i_reset_n )
	begin

		-- On reset ...
		if( i_reset_n = '0' ) then

			-- (Do nothing)

		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_03 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					-- Handle defaults
					when others								=>	-- (Do Nothing)	

				end case;

			else

				-- Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					-- Handle reading ADC Data (Channel)
					when c_ADC_DATA 						=> 	r_data_out_mem_03 	<= "000" & i_adc_channel;

					-- Handle defaults
					when others								=> 	r_data_out_mem_03 	<= x"00";

				end case;

			end if;

		end if;

	end process;

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign address
	o_adc_addr		<= r_adc_addr(6 downto 0);


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------