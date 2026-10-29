----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  MEMORY MANAGEMENT UNIT (MMU)
--	GPIO MEMORY DEVICE
--
--	CREATED BY CHRIS MAJOR
--  RESILIENT COMPUTING
-- 	07/06/2022
--
--!	@file
--!	@brief A memory map for the General Purpose Input/Output (GPIO) memory device.
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
entity mem_gpio is
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
end entity;
	
	
----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture mem_gpio_arch of mem_gpio is

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the GPIO component
	component gpio is
	generic(
		g_GPIO_SIZE                 : integer 	:= 32
	);
	port(
		i_reset_n					: in	std_logic;	

		i_gpio_direction            : in    std_logic_vector( (g_GPIO_SIZE - 1) downto 0);
	
		i_gpio_write                : in   	std_logic_vector( (g_GPIO_SIZE - 1) downto 0);
		o_gpio_read                 : out  	std_logic_vector( (g_GPIO_SIZE - 1) downto 0);
	
		i_gpio                     	: in 	std_logic_vector( (g_GPIO_SIZE - 1) downto 0);
		o_gpio                 		: out  	std_logic_vector( (g_GPIO_SIZE - 1) downto 0)
	);
	end component;

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

	constant c_ADDR_SPACE				: integer							:= 28;

	constant c_GPIO_DATA_I				: std_logic_vector(29 downto 0)		:= "00" & x"0000000";	--! GPIO 00 Input Data
	constant c_GPIO_DATA_O				: std_logic_vector(29 downto 0)		:= "00" & x"0000001";	--! GPIO 00 Output Data
	constant c_GPIO_DATA_D				: std_logic_vector(29 downto 0)		:= "00" & x"0000002";	--! GPIO 00 Direction Data

	constant c_GPIO_DATA_IES			: std_logic_vector(29 downto 0)		:= "00" & x"0000003";	--! GPIO 00 Interrupt Edge Select Data
	constant c_GPIO_DATA_IE				: std_logic_vector(29 downto 0)		:= "00" & x"0000004";	--! GPIO 00 Interrupt Enable Data
	constant c_GPIO_DATA_IFG			: std_logic_vector(29 downto 0)		:= "00" & x"0000005";	--! GPIO 00 Interrupt Flag Data
	constant c_GPIO_DATA_VEC			: std_logic_vector(29 downto 0)		:= "00" & x"0000006";	--! GPIO 00 Interrupt Vector Data

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_gpio_in_val				: std_logic_vector(31 downto 0) := x"00000000";				-- GPIO Input Value
	signal r_gpio_dir_val				: std_logic_vector(31 downto 0) := x"00000000";				-- GPIO Direction Value
	signal r_gpio_out_val				: std_logic_vector(31 downto 0) := x"00000000";				-- GPIO Output Value

	signal r_gpio_ies_val				: std_logic_vector(31 downto 0) := x"00000000";				-- GPIO Interrupt Edge Select Value
	signal r_gpio_ie_val				: std_logic_vector(31 downto 0) := x"00000000";				-- GPIO Interrupt Enable Value
	signal r_gpio_ifg_val				: std_logic_vector(31 downto 0) := x"00000000";				-- GPIO Interrupt Flag Value
	signal r_gpio_vec_val				: std_logic_vector(31 downto 0) := x"00000000";				-- GPIO Interrupt Vector Value

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

	signal w_rw_mem_00					: std_logic;												-- Memory Device Read/Write 00
	signal w_rw_mem_01					: std_logic;												-- Memory Device Read/Write 01
	signal w_rw_mem_02					: std_logic;												-- Memory Device Read/Write 02
	signal w_rw_mem_03					: std_logic;												-- Memory Device Read/Write 03

	signal r_gpio_int					: std_logic_vector(31 downto 0) := x"00000000";				-- GPIO Interrupt Input
	signal r_gpio_in_del				: std_logic_vector(31 downto 0) := x"00000000";				-- GPIO Input Value Delayed

begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate GPIO 00
	GPIO_00 : gpio
	generic map(
		g_GPIO_SIZE                 		=> 32
	)
	port map(
		i_reset_n							=> i_reset_n,

		i_gpio_direction(7 downto 0)    	=> r_gpio_dir_val(7 downto 0),
		i_gpio_direction(15 downto 8)   	=> r_gpio_dir_val(15 downto 8),
		i_gpio_direction(23 downto 16)  	=> r_gpio_dir_val(23 downto 16),
		i_gpio_direction(31 downto 24)  	=> r_gpio_dir_val(31 downto 24),
	
		i_gpio_write(7 downto 0)    		=> r_gpio_out_val(7 downto 0),
		i_gpio_write(15 downto 8)   		=> r_gpio_out_val(15 downto 8),
		i_gpio_write(23 downto 16)  		=> r_gpio_out_val(23 downto 16),
		i_gpio_write(31 downto 24)  		=> r_gpio_out_val(31 downto 24),

		o_gpio_read(7 downto 0)    			=> r_gpio_in_val(7 downto 0),
		o_gpio_read(15 downto 8)    		=> r_gpio_in_val(15 downto 8),
		o_gpio_read(23 downto 16)   		=> r_gpio_in_val(23 downto 16),
		o_gpio_read(31 downto 24)   		=> r_gpio_in_val(31 downto 24),
	
		i_gpio                     			=> i_gpio_in,
		o_gpio                 				=> o_gpio_out
	);

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
		
		--variable bit_0		: integer range 0 to 64;
		--variable bit_1		: integer range 0 to 64;
		--variable bit_2		: integer range 0 to 64;
		--variable bit_3		: integer range 0 to 64;
		--variable bit_4		: integer range 0 to 64;
		--variable bit_5		: integer range 0 to 64;
		--variable bit_6		: integer range 0 to 64;
		--variable bit_7		: integer range 0 to 64;
		--variable bit_8		: integer range 0 to 64;
		--variable bit_9		: integer range 0 to 64;
		--variable bit_10		: integer range 0 to 64;
		--variable bit_11		: integer range 0 to 64;
		--variable bit_12		: integer range 0 to 64;
		--variable bit_13		: integer range 0 to 64;
		--variable bit_14		: integer range 0 to 64;
		--variable bit_15		: integer range 0 to 64;
		--variable bit_16		: integer range 0 to 64;
		--variable bit_17		: integer range 0 to 64;
		--variable bit_18		: integer range 0 to 64;
		--variable bit_19		: integer range 0 to 64;
		--variable bit_20		: integer range 0 to 64;
		--variable bit_21		: integer range 0 to 64;
		--variable bit_22		: integer range 0 to 64;
		--variable bit_23		: integer range 0 to 64;
		--variable bit_24		: integer range 0 to 64;
		--variable bit_25		: integer range 0 to 64;
		--variable bit_26		: integer range 0 to 64;
		--variable bit_27		: integer range 0 to 64;
		--variable bit_28		: integer range 0 to 64;
		--variable bit_29		: integer range 0 to 64;
		--variable bit_30		: integer range 0 to 64;
		--variable bit_31		: integer range 0 to 64;

	begin

		-- On reset, clear GPIO
		if( i_reset_n = '0' ) then

			r_gpio_out_val(7 downto 0) 		<= x"00";
			r_gpio_dir_val(7 downto 0)		<= x"00";
			--r_gpio_in_del(7 downto 0)		<= x"00";

			--r_gpio_ies_val(7 downto 0)		<= x"00";
			--r_gpio_ie_val(7 downto 0)		<= x"00";
			--r_gpio_ifg_val(7 downto 0)		<= x"00";
			--r_gpio_vec_val(7 downto 0)		<= x"00";

		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_00 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_00(29 downto 0) ) is

					-- Handle writing GPIO Output
					when c_GPIO_DATA_O 						=> 	r_gpio_out_val(7 downto 0) 	<= r_data_in_mem_00;

					-- Handle writing GPIO Direction
					when c_GPIO_DATA_D 						=> 	r_gpio_dir_val(7 downto 0) 	<= r_data_in_mem_00;

					-- Handle writing GPIO Interrupt Edge Select
					when c_GPIO_DATA_IES					=> 	r_gpio_ies_val(7 downto 0) 	<= r_data_in_mem_00;

					-- Handle writing GPIO Interrupt Enable
					when c_GPIO_DATA_IE						=> 	r_gpio_ie_val(7 downto 0) 	<= r_data_in_mem_00;

					-- Handle writing GPIO Interrupt Flag
					when c_GPIO_DATA_IFG					=> 	r_gpio_ifg_val(7 downto 0) 	<= r_data_in_mem_00;

					-- Handle defaults
					when others								=>

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_00(29 downto 0) ) is

					-- Handle writing GPIO Output
					when c_GPIO_DATA_O 						=> 	r_data_out_mem_00 <= r_gpio_out_val(7 downto 0);

					-- Handle writing GPIO Direction
					when c_GPIO_DATA_D						=> 	r_data_out_mem_00 <= r_gpio_dir_val(7 downto 0);

					-- Handle writing GPIO Input
					when c_GPIO_DATA_I						=> 	r_data_out_mem_00 <= r_gpio_in_val(7 downto 0);

					-- Handle reading GPIO Interrupt Edge Select
					when c_GPIO_DATA_IES					=> 	r_data_out_mem_00 <= r_gpio_ies_val(7 downto 0);

					-- Handle reading GPIO Interrupt Enable
					when c_GPIO_DATA_IE						=> 	r_data_out_mem_00 <= r_gpio_ie_val(7 downto 0);

					-- Handle reading GPIO Interrupt Flag
					when c_GPIO_DATA_IFG					=> 	r_data_out_mem_00 <= r_gpio_ifg_val(7 downto 0);

					-- Handle reading GPIO Interrupt Vector
					when c_GPIO_DATA_VEC					=> 	r_data_out_mem_00 <= r_gpio_vec_val(7 downto 0);

					-- Handle defaults
					when others								=> 	r_data_out_mem_00 <= x"00";

				end case;

				-- Update Input Delay
				--r_gpio_in_del(7 downto 0)	<= r_gpio_in_val(7 downto 0);

				-- --Update and latch Interrupt Flag
				-- if(((r_gpio_ie_val(7 downto 0) /= x"00") AND (r_gpio_int(7 downto 0) /= x"00"))) then

				-- 	--r_gpio_ifg_val(7 downto 0) <= (r_gpio_int(7 downto 0) AND r_gpio_ie_val(7 downto 0));

				-- 	if (r_gpio_int(7) = '1' AND r_gpio_ie_val(7) = '1') then
				-- 		r_gpio_ifg_val(7) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(6) = '1' AND r_gpio_ie_val(6) = '1') then
				-- 		r_gpio_ifg_val(6) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(5) = '1' AND r_gpio_ie_val(5) = '1') then
				-- 		r_gpio_ifg_val(5) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(4) = '1' AND r_gpio_ie_val(4) = '1') then
				-- 		r_gpio_ifg_val(4) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(3) = '1' AND r_gpio_ie_val(3) = '1') then
				-- 		r_gpio_ifg_val(3) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(2) = '1' AND r_gpio_ie_val(2) = '1') then
				-- 		r_gpio_ifg_val(2) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(1) = '1' AND r_gpio_ie_val(1) = '1') then
				-- 		r_gpio_ifg_val(1) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(0) = '1' AND r_gpio_ie_val(0) = '1') then
				-- 		r_gpio_ifg_val(0) <= '1';
				-- 	end if;
				-- end if;

				-- -- Update GPIO vector value given current Interrupt Flag (IFG) value
				-- r_gpio_vec_val(7 downto 0) <= std_logic_vector(to_unsigned(bit_0, r_gpio_vec_val'length/4));

				-- --Priority If-Else chain for the GPIO vector register
				-- --64 is lowest priority
				-- --0  is no interrupt pending
				-- if (r_gpio_ifg_val(31) = '1') then
				-- 	bit_31	:= 64;
				-- 	else
				-- 	bit_31	:= 0;
				-- end if;
				-- if (r_gpio_ifg_val(30) = '1') then
				-- 	bit_30	:= 62;
				-- 	else
				-- 	bit_30	:= bit_31;
				-- end if;
				-- if (r_gpio_ifg_val(29) = '1') then
				-- 	bit_29	:= 60;
				-- 	else
				-- 	bit_29	:= bit_30;
				-- end if;
				-- if (r_gpio_ifg_val(28) = '1') then
				-- 	bit_28	:= 58;
				-- 	else
				-- 	bit_28	:= bit_29;
				-- end if;
				-- if (r_gpio_ifg_val(27) = '1') then
				-- 	bit_27	:= 56;
				-- 	else
				-- 	bit_27	:= bit_28;
				-- end if;
				-- if (r_gpio_ifg_val(26) = '1') then
				-- 	bit_26	:= 54;
				-- 	else
				-- 	bit_26	:= bit_27;
				-- end if;
				-- if (r_gpio_ifg_val(25) = '1') then
				-- 	bit_25	:= 52;
				-- 	else
				-- 	bit_25	:= bit_26;
				-- end if;
				-- if (r_gpio_ifg_val(24) = '1') then
				-- 	bit_24	:= 50;
				-- 	else
				-- 	bit_24	:= bit_25;
				-- end if;
				-- if (r_gpio_ifg_val(23) = '1') then
				-- 	bit_23	:= 48;
				-- 	else
				-- 	bit_23	:= bit_24;
				-- end if;
				-- if (r_gpio_ifg_val(22) = '1') then
				-- 	bit_22	:= 46;
				-- 	else
				-- 	bit_22	:= bit_23;
				-- end if;
				-- if (r_gpio_ifg_val(21) = '1') then
				-- 	bit_21	:= 44;
				-- 	else
				-- 	bit_21	:= bit_22;
				-- end if;
				-- if (r_gpio_ifg_val(20) = '1') then
				-- 	bit_20	:= 42;
				-- 	else
				-- 	bit_20	:= bit_21;
				-- end if;
				-- if (r_gpio_ifg_val(19) = '1') then
				-- 	bit_19	:= 40;
				-- 	else
				-- 	bit_19	:= bit_20;
				-- end if;
				-- if (r_gpio_ifg_val(18) = '1') then
				-- 	bit_18	:= 38;
				-- 	else
				-- 	bit_18	:= bit_19;
				-- end if;
				-- if (r_gpio_ifg_val(17) = '1') then
				-- 	bit_17	:= 36;
				-- 	else
				-- 	bit_17	:= bit_18;
				-- end if;
				-- if (r_gpio_ifg_val(16) = '1') then
				-- 	bit_16	:= 34;
				-- 	else
				-- 	bit_16	:= bit_17;
				-- end if;
				-- if (r_gpio_ifg_val(15) = '1') then
				-- 	bit_15	:= 32;
				-- 	else
				-- 	bit_15	:= bit_16;
				-- end if;
				-- if (r_gpio_ifg_val(14) = '1') then
				-- 	bit_14	:= 30;
				-- 	else
				-- 	bit_14	:= bit_15;
				-- end if;
				-- if (r_gpio_ifg_val(13) = '1') then
				-- 	bit_13	:= 28;
				-- 	else
				-- 	bit_13	:= bit_14;
				-- end if;
				-- if (r_gpio_ifg_val(11) = '1') then
				-- 	bit_12	:= 26;
				-- 	else
				-- 	bit_12	:= bit_13;
				-- end if;
				-- if (r_gpio_ifg_val(11) = '1') then
				-- 	bit_11	:= 24;
				-- 	else
				-- 	bit_11	:= bit_12;
				-- end if;
				-- if (r_gpio_ifg_val(10) = '1') then
				-- 	bit_10	:= 22;
				-- 	else
				-- 	bit_10	:= bit_11;
				-- end if;
				-- if (r_gpio_ifg_val(9) = '1') then
				-- 	bit_9	:= 20;
				-- 	else
				-- 	bit_9	:= bit_10;
				-- end if;
				-- if (r_gpio_ifg_val(8) = '1') then
				-- 	bit_8	:= 18;
				-- 	else
				-- 	bit_8	:= bit_9;
				-- end if;
				-- if (r_gpio_ifg_val(7) = '1') then
				-- 	bit_7	:= 16;
				-- 	else
				-- 	bit_7	:= bit_8;
				-- end if;
				-- if (r_gpio_ifg_val(6) = '1') then
				-- 	bit_6	:= 14;
				-- 	else
				-- 	bit_6	:= bit_7;
				-- end if;
				-- if (r_gpio_ifg_val(5) = '1') then
				-- 	bit_5	:= 12;
				-- 	else
				-- 	bit_5	:= bit_6;
				-- end if;
				-- if (r_gpio_ifg_val(4) = '1') then
				-- 	bit_4	:= 10;
				-- 	else
				-- 	bit_4	:= bit_5;
				-- end if;
				-- if (r_gpio_ifg_val(3) = '1') then
				-- 	bit_3	:= 8;
				-- 	else
				-- 	bit_3	:= bit_4;
				-- end if;
				-- if (r_gpio_ifg_val(2) = '1') then
				-- 	bit_2	:= 6;
				-- 	else
				-- 	bit_2	:= bit_3;
				-- end if;
				-- if (r_gpio_ifg_val(1) = '1') then
				-- 	bit_1	:= 4;
				-- 	else
				-- 	bit_1	:= bit_2;
				-- end if;
				-- if (r_gpio_ifg_val(0) = '1') then
				-- 	bit_0	:= 2;
				-- 	else
				-- 	bit_0	:= bit_1;
				-- end if;

			end if;

		end if;

	end process;


	-- WRITE to Memory Device 01
	MEM_WRITE_01 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear GPIO
		if( i_reset_n = '0' ) then

			r_gpio_out_val(15 downto 8)		<= x"00";
			r_gpio_dir_val(15 downto 8)		<= x"00";
			--r_gpio_in_del(15 downto 8)		<= x"00";

			--r_gpio_ies_val(15 downto 8)		<= x"00";
			--r_gpio_ie_val(15 downto 8)		<= x"00";
			--r_gpio_ifg_val(15 downto 8)		<= x"00";
			--r_gpio_vec_val(15 downto 8)		<= x"00";

		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_01 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_01(29 downto 0) ) is

					-- Handle writing GPIO Output
					when c_GPIO_DATA_O 						=> 	r_gpio_out_val(15 downto 8) 	<= r_data_in_mem_01;

					-- Handle writing GPIO Direction
					when c_GPIO_DATA_D 						=> 	r_gpio_dir_val(15 downto 8) 	<= r_data_in_mem_01;

					-- Handle writing GPIO Interrupt Edge Select
					when c_GPIO_DATA_IES					=> 	r_gpio_ies_val(15 downto 8) 	<= r_data_in_mem_01;

					-- Handle writing GPIO Interrupt Enable
					when c_GPIO_DATA_IE						=> 	r_gpio_ie_val(15 downto 8) 		<= r_data_in_mem_01;

					-- Handle writing GPIO Interrupt Flag
					when c_GPIO_DATA_IFG					=> 	r_gpio_ifg_val(15 downto 8) 	<= r_data_in_mem_01;

					-- Handle defaults
					when others								=>

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_01(29 downto 0) ) is

					-- Handle writing GPIO Output
					when c_GPIO_DATA_O 						=> 	r_data_out_mem_01 <= r_gpio_out_val(15 downto 8);

					-- Handle writing GPIO Direction
					when c_GPIO_DATA_D						=> 	r_data_out_mem_01 <= r_gpio_dir_val(15 downto 8);

					-- Handle writing GPIO Input
					when c_GPIO_DATA_I 						=> 	r_data_out_mem_01 <= r_gpio_in_val(15 downto 8);

					-- Handle reading GPIO Interrupt Edge Select
					when c_GPIO_DATA_IES					=> 	r_data_out_mem_01 <= r_gpio_ies_val(15 downto 8);

					-- Handle reading GPIO Interrupt Enable
					when c_GPIO_DATA_IE						=> 	r_data_out_mem_01 <= r_gpio_ie_val(15 downto 8);

					-- Handle reading GPIO Interrupt Flag
					when c_GPIO_DATA_IFG					=> 	r_data_out_mem_01 <= r_gpio_ifg_val(15 downto 8);

					-- Handle reading GPIO Interrupt Vector
					when c_GPIO_DATA_VEC					=> 	r_data_out_mem_01 <= r_gpio_vec_val(15 downto 8);

					-- Handle defaults
					when others								=> 	r_data_out_mem_01 <= x"00";

				end case;

				--Update Input Delay
				--r_gpio_in_del(15 downto 8)	<= r_gpio_in_val(15 downto 8);

				-- --Update and latch Interrupt Flag
				-- if(((r_gpio_ie_val(15 downto 8) /= x"00") AND (r_gpio_int(15 downto 8) /= x"00"))) then
				-- 	--r_gpio_ifg_val(15 downto 8) <= (r_gpio_int(15 downto 8) AND r_gpio_ie_val(15 downto 8));

				-- 	if (r_gpio_int(8) = '1' AND r_gpio_ie_val(8) = '1') then
				-- 		r_gpio_ifg_val(8) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(9) = '1' AND r_gpio_ie_val(9) = '1') then
				-- 		r_gpio_ifg_val(9) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(10) = '1' AND r_gpio_ie_val(10) = '1') then
				-- 		r_gpio_ifg_val(10) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(11) = '1' AND r_gpio_ie_val(11) = '1') then
				-- 		r_gpio_ifg_val(11) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(12) = '1' AND r_gpio_ie_val(12) = '1') then
				-- 		r_gpio_ifg_val(12) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(13) = '1' AND r_gpio_ie_val(13) = '1') then
				-- 		r_gpio_ifg_val(13) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(14) = '1' AND r_gpio_ie_val(14) = '1') then
				-- 		r_gpio_ifg_val(14) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(15) = '1' AND r_gpio_ie_val(15) = '1') then
				-- 		r_gpio_ifg_val(15) <= '1';
				-- 	end if;
				--end if;

			end if;

		end if;

	end process;	


	-- WRITE to Memory Device 02
	MEM_WRITE_02 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear GPIO
		if( i_reset_n = '0' ) then

			r_gpio_out_val(23 downto 16)	<= x"00";
			r_gpio_dir_val(23 downto 16)	<= x"00";
			--r_gpio_in_del(23 downto 16)		<= x"00";

			--r_gpio_ies_val(23 downto 16)	<= x"00";
			--r_gpio_ie_val(23 downto 16)		<= x"00";
			--r_gpio_ifg_val(23 downto 16)	<= x"00";
			--r_gpio_vec_val(23 downto 16)	<= x"00";

		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_02 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_02(29 downto 0) ) is

					-- Handle writing GPIO Output
					when c_GPIO_DATA_O 						=> 	r_gpio_out_val(23 downto 16) <= r_data_in_mem_02;

					-- Handle writing GPIO Direction
					when c_GPIO_DATA_D 						=> 	r_gpio_dir_val(23 downto 16) <= r_data_in_mem_02;

					-- Handle writing GPIO Interrupt Edge Select
					when c_GPIO_DATA_IES					=> 	r_gpio_ies_val(23 downto 16) 	<= r_data_in_mem_02;

					-- Handle writing GPIO Interrupt Enable
					when c_GPIO_DATA_IE						=> 	r_gpio_ie_val(23 downto 16) 	<= r_data_in_mem_02;

					-- Handle writing GPIO Interrupt Flag
					when c_GPIO_DATA_IFG					=> 	r_gpio_ifg_val(23 downto 16) 	<= r_data_in_mem_02;

					-- Handle defaults
					when others								=>

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_02(29 downto 0) ) is

					-- Handle writing GPIO Output
					when c_GPIO_DATA_O 						=> 	r_data_out_mem_02 <= r_gpio_out_val(23 downto 16);

					-- Handle writing GPIO Direction
					when c_GPIO_DATA_D 						=> 	r_data_out_mem_02 <= r_gpio_dir_val(23 downto 16);

					-- Handle writing GPIO Input
					when c_GPIO_DATA_I						=> 	r_data_out_mem_02 <= r_gpio_in_val(23 downto 16);

					-- Handle reading GPIO Interrupt Edge Select
					when c_GPIO_DATA_IES					=> 	r_data_out_mem_02 <= r_gpio_ies_val(23 downto 16);

					-- Handle reading GPIO Interrupt Enable
					when c_GPIO_DATA_IE						=> 	r_data_out_mem_02 <= r_gpio_ie_val(23 downto 16);

					-- Handle reading GPIO Interrupt Flag
					when c_GPIO_DATA_IFG					=> 	r_data_out_mem_02 <= r_gpio_ifg_val(23 downto 16);

					-- Handle reading GPIO Interrupt Vector
					when c_GPIO_DATA_VEC					=> 	r_data_out_mem_02 <= r_gpio_vec_val(23 downto 16);


					-- Handle defaults
					when others								=> 	r_data_out_mem_02 <= x"00";

				end case;
				
				--Update Input Delay
				--r_gpio_in_del(23 downto 16)	<= r_gpio_in_val(23 downto 16);

				-- --Update and latch Interrupt Flag
				-- if((r_gpio_ie_val(23 downto 16) /= x"00") AND (r_gpio_int(23 downto 16) /= x"00")) then
				-- 	--r_gpio_ifg_val(23 downto 16) <= (r_gpio_int(23 downto 16) AND r_gpio_ie_val(23 downto 16));
				-- 	if (r_gpio_int(16) = '1' AND r_gpio_ie_val(16) = '1') then
				-- 		r_gpio_ifg_val(16) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(17) = '1' AND r_gpio_ie_val(17) = '1') then
				-- 		r_gpio_ifg_val(17) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(18) = '1' AND r_gpio_ie_val(18) = '1') then
				-- 		r_gpio_ifg_val(18) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(19) = '1' AND r_gpio_ie_val(19) = '1') then
				-- 		r_gpio_ifg_val(19) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(20) = '1' AND r_gpio_ie_val(20) = '1') then
				-- 		r_gpio_ifg_val(20) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(21) = '1' AND r_gpio_ie_val(21) = '1') then
				-- 		r_gpio_ifg_val(21) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(22) = '1' AND r_gpio_ie_val(22) = '1') then
				-- 		r_gpio_ifg_val(22) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(23) = '1' AND r_gpio_ie_val(23) = '1') then
				-- 		r_gpio_ifg_val(23) <= '1';
				-- 	end if;
				-- end if;
			end if;

		end if;

	end process;	


	-- WRITE to Memory Device 03
	MEM_WRITE_03 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear GPIO
		if( i_reset_n = '0' ) then

			r_gpio_out_val(31 downto 24)	<= x"00";
			r_gpio_dir_val(31 downto 24)	<= x"00";
			--r_gpio_in_del(31 downto 24)		<= x"00";

			--r_gpio_ies_val(31 downto 24)		<= x"00";
			--r_gpio_ie_val(31 downto 24)		<= x"00";
			--r_gpio_ifg_val(31 downto 24)		<= x"00";
			--r_gpio_vec_val(31 downto 24)		<= x"00";

		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_03 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					-- Handle writing GPIO Output
					when c_GPIO_DATA_O 						=> 	r_gpio_out_val(31 downto 24) 	<= r_data_in_mem_03;

					-- Handle writing GPIO Direction
					when c_GPIO_DATA_D	 					=> 	r_gpio_dir_val(31 downto 24) 	<= r_data_in_mem_03;

					-- Handle writing GPIO Interrupt Edge Select
					when c_GPIO_DATA_IES					=> 	r_gpio_ies_val(31 downto 24) 	<= r_data_in_mem_03;

					-- Handle writing GPIO Interrupt Enable
					when c_GPIO_DATA_IE						=> 	r_gpio_ie_val(31 downto 24) 	<= r_data_in_mem_03;

					-- Handle writing GPIO Interrupt Flag
					when c_GPIO_DATA_IFG					=> 	r_gpio_ifg_val(31 downto 24) 	<= r_data_in_mem_03;

					-- Handle defaults
					when others								=>

				end case;

			else

				-- Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					-- Handle writing GPIO Output
					when c_GPIO_DATA_O 						=> 	r_data_out_mem_03 <= r_gpio_out_val(31 downto 24);

					-- Handle writing GPIO Direction
					when c_GPIO_DATA_D 						=> 	r_data_out_mem_03 <= r_gpio_dir_val(31 downto 24);

					-- Handle writing GPIO Input
					when c_GPIO_DATA_I						=> 	r_data_out_mem_03 <= r_gpio_in_val(31 downto 24);

					-- Handle reading GPIO Interrupt Edge Select
					when c_GPIO_DATA_IES					=> 	r_data_out_mem_03 <= r_gpio_ies_val(31 downto 24);

					-- Handle reading GPIO Interrupt Enable
					when c_GPIO_DATA_IE						=> 	r_data_out_mem_03 <= r_gpio_ie_val(31 downto 24);

					-- Handle reading GPIO Interrupt Flag
					when c_GPIO_DATA_IFG					=> 	r_data_out_mem_03 <= r_gpio_ifg_val(31 downto 24);

					-- Handle reading GPIO Interrupt Vector
					when c_GPIO_DATA_VEC					=> 	r_data_out_mem_03 <= r_gpio_vec_val(31 downto 24);

					-- Handle defaults
					when others								=> 	r_data_out_mem_03 <= x"00";

				end case;

				--Update Input Delay
				--r_gpio_in_del(31 downto 24)	<= r_gpio_in_val(31 downto 24);

				--Update and latch Interrupt Flag
				-- if((r_gpio_ie_val(31 downto 24) /= x"00") AND (r_gpio_int(31 downto 24) /= x"00")) then

				-- 	--r_gpio_ifg_val(31 downto 24) <= (r_gpio_int(31 downto 24) AND r_gpio_ie_val(31 downto 24));
				-- 	if (r_gpio_int(24) = '1' AND r_gpio_ie_val(24) = '1') then
				-- 		r_gpio_ifg_val(24) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(25) = '1' AND r_gpio_ie_val(25) = '1') then
				-- 		r_gpio_ifg_val(25) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(26) = '1' AND r_gpio_ie_val(18) = '1') then
				-- 		r_gpio_ifg_val(26) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(27) = '1' AND r_gpio_ie_val(19) = '1') then
				-- 		r_gpio_ifg_val(27) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(28) = '1' AND r_gpio_ie_val(20) = '1') then
				-- 		r_gpio_ifg_val(28) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(29) = '1' AND r_gpio_ie_val(21) = '1') then
				-- 		r_gpio_ifg_val(29) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(30) = '1' AND r_gpio_ie_val(22) = '1') then
				-- 		r_gpio_ifg_val(30) <= '1';
				-- 	end if;
				-- 	if (r_gpio_int(31) = '1' AND r_gpio_ie_val(23) = '1') then
				-- 		r_gpio_ifg_val(31) <= '1';
				-- 	end if;
				-- end if;

			end if;

		end if;

	end process;

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign direction
	o_gpio_dir		<= 	r_gpio_dir_val;


	o_gpio_irq 		<=	--'1' when r_gpio_ifg_val /= x"00000000" else
						'0';

	-- -- Assign appropriate interrupt based on the interrupt edge select value
	-- --Low-to-High when IES = 0 Else High-to-Low when IES = 1
	-- HANDLE_EDGE_SELECT : for i in 31 downto 0 generate

	-- 	-- IS THIS THE TIMING ISSUE
	-- 	TEST_00 : process( i_clk, i_reset_n )
	-- 	begin

	-- 		if( rising_edge( i_clk )) then

	-- 			case( r_gpio_ies_val(i) ) is

	-- 				when '0'		=>	r_gpio_int(i)	<= 	((r_gpio_in_val(i)) AND (NOT r_gpio_in_del(i)));
	-- 				when '1'		=> 	r_gpio_int(i)	<= 	((NOT r_gpio_in_val(i)) AND (r_gpio_in_del(i)));
	-- 				when others		=>	r_gpio_int(i)	<=	'0';


	-- 			end case;

	-- 		end if;

	-- 	end process;

	-- end generate;

end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------