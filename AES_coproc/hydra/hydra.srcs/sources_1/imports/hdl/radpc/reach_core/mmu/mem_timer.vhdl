----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  MEMORY MANAGEMENT UNIT (MMU)
--	TIMER MEMORY DEVICE
--
--	CREATED BY TRISTAN RUNNING CRANE
--  RESILIENT COMPUTING
-- 	05/29/2024
--
--!	@file
--!	@brief A memory map for Timer memory device.
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
entity mem_timer is
port(
	i_clk						: in	std_logic;												--! Clock
	i_reset_n					: in	std_logic;												--! Active Low Reset

	i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
	i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
	i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
	i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
	o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

	o_timer_irq					: out	std_logic												--! Timer Interrupt Request Signal
);
end entity;

----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture mem_timer_arch of mem_timer is

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------


	-- Declare the TIMER component
	component timer is
	port(
		i_clk						: in	std_logic;
		i_reset_n					: in	std_logic;

		i_ctl						: in	std_logic_vector(31 downto 0);
		i_mtime_L					: in	std_logic_vector(31 downto 0);
		i_mtime_H					: in	std_logic_vector(31 downto 0);
		i_mtimecmp_L				: in	std_logic_vector(31 downto 0);
		i_mtimecmp_H				: in	std_logic_vector(31 downto 0);

		o_mtime_L					: out	std_logic_vector(31 downto 0);
		o_mtime_H					: out	std_logic_vector(31 downto 0)
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

	constant c_ADDR_SPACE				: integer							:= 96;

	constant c_TIMER_CTL				: std_logic_vector(29 downto 0)		:= "00" & x"0000000";	--! TIMER Control Address
	constant c_TIMER_CMPCTL_0			: std_logic_vector(29 downto 0)		:= "00" & x"0000001";	--! TIMER Compare Control Address 0
	constant c_TIMER_CMPCTL_1			: std_logic_vector(29 downto 0)		:= "00" & x"0000002";	--! TIMER Compare Control Address 1
	constant c_TIMER_CMPCTL_2			: std_logic_vector(29 downto 0)		:= "00" & x"0000003";	--! TIMER Compare Control Address 2
	constant c_TIMER_CMPCTL_3			: std_logic_vector(29 downto 0)		:= "00" & x"0000004";	--! TIMER Compare Control Address 3
	constant c_TIMER_CMPCTL_4			: std_logic_vector(29 downto 0)		:= "00" & x"0000005";	--! TIMER Compare Control Address 4
	constant c_TIMER_CMPCTL_5			: std_logic_vector(29 downto 0)		:= "00" & x"0000006";	--! TIMER Compare Control Address 5
	constant c_TIMER_MTIME_L			: std_logic_vector(29 downto 0)		:= "00" & x"0000007";	--! TIMER Counter Low  Address
	constant c_TIMER_MTIME_H			: std_logic_vector(29 downto 0)		:= "00" & x"0000008";	--! TIMER Counter High Address
	constant c_TIMER_MTIMECMP_L_0		: std_logic_vector(29 downto 0)		:= "00" & x"0000009";	--! TIMER Compare Low  Address 0
	constant c_TIMER_MTIMECMP_H_0		: std_logic_vector(29 downto 0)		:= "00" & x"000000A";	--! TIMER Compare High Address 0
	constant c_TIMER_MTIMECMP_L_1		: std_logic_vector(29 downto 0)		:= "00" & x"000000B";	--! TIMER Compare Low  Address 1
	constant c_TIMER_MTIMECMP_H_1		: std_logic_vector(29 downto 0)		:= "00" & x"000000C";	--! TIMER Compare High Address 1
	constant c_TIMER_MTIMECMP_L_2		: std_logic_vector(29 downto 0)		:= "00" & x"000000D";	--! TIMER Compare Low  Address 2
	constant c_TIMER_MTIMECMP_H_2		: std_logic_vector(29 downto 0)		:= "00" & x"000000E";	--! TIMER Compare High Address 2
	constant c_TIMER_MTIMECMP_L_3		: std_logic_vector(29 downto 0)		:= "00" & x"000000F";	--! TIMER Compare Low  Address 3
	constant c_TIMER_MTIMECMP_H_3		: std_logic_vector(29 downto 0)		:= "00" & x"0000010";	--! TIMER Compare High Address 3
	constant c_TIMER_MTIMECMP_L_4		: std_logic_vector(29 downto 0)		:= "00" & x"0000011";	--! TIMER Compare Low  Address 4
	constant c_TIMER_MTIMECMP_H_4		: std_logic_vector(29 downto 0)		:= "00" & x"0000012";	--! TIMER Compare High Address 4
	constant c_TIMER_MTIMECMP_L_5		: std_logic_vector(29 downto 0)		:= "00" & x"0000013";	--! TIMER Compare Low  Address 5
	constant c_TIMER_MTIMECMP_H_5		: std_logic_vector(29 downto 0)		:= "00" & x"0000014";	--! TIMER Compare High Address 5
	constant c_TIMER_VEC				: std_logic_vector(29 downto 0)		:= "00" & x"0000015";	--! TIMER Interrupt Vector Address

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_timer_ctl_val					: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Control Register
	signal r_timer_cmpctl_0_val				: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Control Register 0
	signal r_timer_cmpctl_1_val				: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Control Register 1
	signal r_timer_cmpctl_2_val				: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Control Register 2
	signal r_timer_cmpctl_3_val				: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Control Register 3
	signal r_timer_cmpctl_4_val				: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Control Register 4
	signal r_timer_cmpctl_5_val				: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Control Register 5
	signal r_timer_mtime_L_I_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Counter Low  Write Register
	signal r_timer_mtime_H_I_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Counter High Write Register
	signal r_timer_mtime_L_O_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Counter Low  Read Register
	signal r_timer_mtime_H_O_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Counter High Read Register
	signal r_timer_mtimecmp_L_0_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Low  Register 0
	signal r_timer_mtimecmp_H_0_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare High Register 0
	signal r_timer_mtimecmp_L_1_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Low  Register 1
	signal r_timer_mtimecmp_H_1_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare High Register 1
	signal r_timer_mtimecmp_L_2_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Low  Register 2
	signal r_timer_mtimecmp_H_2_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare High Register 2
	signal r_timer_mtimecmp_L_3_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Low  Register 3
	signal r_timer_mtimecmp_H_3_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare High Register 3
	signal r_timer_mtimecmp_L_4_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Low  Register 4
	signal r_timer_mtimecmp_H_4_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare High Register 4
	signal r_timer_mtimecmp_L_5_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare Low  Register 5
	signal r_timer_mtimecmp_H_5_val			: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Compare High Register 5
	signal r_timer_vec_val					: std_logic_vector(31 downto 0)		:= x"00000000";			--TIMER Interrupt Vector Register

	signal r_timer_clk						: std_logic							:= '0';					--TIMER Input Clock
	signal r_clk_src						: std_logic							:= '0';					--TIMER Clock Source
	signal r_div_0							: std_logic							:= '0';
	signal r_div_1							: std_logic							:= '0';	
	signal r_clk_div_0						: std_logic							:= '0';					--TIMER Clock Divided 0
	signal r_clk_div_1						: std_logic							:= '0';					--TIMER Clock Divided 1
	signal r_timer_div_0					: unsigned(2 downto 0)				:= "000";				--TIMER Input Clock Divider 0
	signal r_timer_div_1					: unsigned(2 downto 0)				:= "000";				--TIMER Input Clock Divider 0

	signal r_addr_mem_00					: std_logic_vector(31 downto 0);							--! Memory Device 00 Address
	signal r_addr_mem_01					: std_logic_vector(31 downto 0);							--! Memory Device 01 Address
	signal r_addr_mem_02					: std_logic_vector(31 downto 0);							--! Memory Device 02 Address
	signal r_addr_mem_03					: std_logic_vector(31 downto 0);							--! Memory Device 03 Address

	signal r_data_in_mem_00					: std_logic_vector(7 downto 0);						    	--! Memory Device Data In 00
	signal r_data_in_mem_01					: std_logic_vector(7 downto 0);						    	--! Memory Device Data In 01
	signal r_data_in_mem_02					: std_logic_vector(7 downto 0);						    	--! Memory Device Data In 02
	signal r_data_in_mem_03					: std_logic_vector(7 downto 0);						    	--! Memory Device Data In 03

	signal r_data_out_mem_00				: std_logic_vector(7 downto 0);						    	--! Memory Device Data Out 00
	signal r_data_out_mem_01				: std_logic_vector(7 downto 0);						    	--! Memory Device Data Out 01
	signal r_data_out_mem_02				: std_logic_vector(7 downto 0);						    	--! Memory Device Data Out 02
	signal r_data_out_mem_03				: std_logic_vector(7 downto 0);						    	--! Memory Device Data Out 03

	signal w_rw_mem_00						: std_logic;												-- Memory Device Read/Write 00
	signal w_rw_mem_01						: std_logic;												-- Memory Device Read/Write 01
	signal w_rw_mem_02						: std_logic;												-- Memory Device Read/Write 02
	signal w_rw_mem_03						: std_logic;												-- Memory Device Read/Write 03

	signal r_csr_cmp_0_val, r_csr_clr_0_val	: std_logic							:= '0';
	signal r_csr_cmp_1_val, r_csr_clr_1_val	: std_logic							:= '0';
	signal r_csr_cmp_2_val, r_csr_clr_2_val	: std_logic							:= '0';
	signal r_csr_cmp_3_val, r_csr_clr_3_val	: std_logic							:= '0';
	signal r_csr_cmp_4_val, r_csr_clr_4_val	: std_logic							:= '0';
	signal r_csr_cmp_5_val, r_csr_clr_5_val	: std_logic							:= '0';

begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	--Instantiate TIMER 00
	TIMER_00 : timer
	port map(
		i_clk								=> r_timer_clk,
		i_reset_n							=> i_reset_n,

		i_ctl								=> r_timer_ctl_val,
		i_mtime_L							=> r_timer_mtime_L_I_val,
		i_mtime_H							=> r_timer_mtime_H_I_val,
		i_mtimecmp_L						=> r_timer_mtimecmp_L_0_val,
		i_mtimecmp_H						=> r_timer_mtimecmp_H_0_val,

		o_mtime_L							=> r_timer_mtime_L_O_val,
		o_mtime_H							=> r_timer_mtime_H_O_val
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

	--WRITE to Memory Device 00
	MEM_WRITE_00 : process( i_clk, i_reset_n )

		variable v_mtime_vec			: integer range 0 to 14;
		variable v_mtimecmp_1			: integer range 0 to 14;
		variable v_mtimecmp_2			: integer range 0 to 14;
		variable v_mtimecmp_3			: integer range 0 to 14;
		variable v_mtimecmp_4			: integer range 0 to 14;
		variable v_mtimecmp_5			: integer range 0 to 14;

	begin

		-- On reset, clear TIMER
		if( i_reset_n = '0' ) then

			r_timer_ctl_val(7 downto 0)				<= x"00";
			r_timer_cmpctl_0_val(7 downto 0)		<= x"00";
			r_timer_cmpctl_1_val(7 downto 0)		<= x"00";
			r_timer_cmpctl_2_val(7 downto 0)		<= x"00";
			r_timer_cmpctl_3_val(7 downto 0)		<= x"00";
			r_timer_cmpctl_4_val(7 downto 0)		<= x"00";
			r_timer_cmpctl_5_val(7 downto 0)		<= x"00";
			r_timer_mtime_L_I_val(7 downto 0)		<= x"00";
			r_timer_mtime_H_I_val(7 downto 0)		<= x"00";
			r_timer_mtimecmp_L_0_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_H_0_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_L_1_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_H_1_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_L_2_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_H_2_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_L_3_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_H_3_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_L_4_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_H_4_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_L_5_val(7 downto 0)	<= x"00";
			r_timer_mtimecmp_H_5_val(7 downto 0)	<= x"00";
			r_timer_vec_val(7 downto 0)				<= x"00";

		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			if( r_addr_mem_00(29 downto 0)  = c_TIMER_CMPCTL_0 and w_rw_mem_00 = '1') then

				r_csr_cmp_0_val <= r_data_in_mem_00(0);

			elsif(r_timer_cmpctl_0_val(1) = '1' AND ((r_timer_mtimecmp_H_0_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_0_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00") then

				r_csr_cmp_0_val <= '1';
			
				end if;
			if( r_addr_mem_00(29 downto 0)  = c_TIMER_CMPCTL_1 and w_rw_mem_00 = '1') then

				r_csr_cmp_1_val <= r_data_in_mem_00(0);

			elsif(r_timer_cmpctl_1_val(1) = '1' AND ((r_timer_mtimecmp_H_1_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_1_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00") then

				r_csr_cmp_1_val <= '1';
			
			end if;
			if( r_addr_mem_00(29 downto 0)  = c_TIMER_CMPCTL_2 and w_rw_mem_00 = '1') then

				r_csr_cmp_2_val <= r_data_in_mem_00(0);

			elsif(r_timer_cmpctl_2_val(1) = '1' AND ((r_timer_mtimecmp_H_2_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_2_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00") then

				r_csr_cmp_2_val <= '1';
			
			end if;
			if( r_addr_mem_00(29 downto 0)  = c_TIMER_CMPCTL_3 and w_rw_mem_00 = '1') then

				r_csr_cmp_3_val <= r_data_in_mem_00(0);

			elsif(r_timer_cmpctl_3_val(1) = '1' AND ((r_timer_mtimecmp_H_3_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_3_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00") then

				r_csr_cmp_3_val <= '1';
			
			end if;
			if( r_addr_mem_00(29 downto 0)  = c_TIMER_CMPCTL_4 and w_rw_mem_00 = '1') then

				r_csr_cmp_4_val <= r_data_in_mem_00(0);

			elsif(r_timer_cmpctl_4_val(1) = '1' AND ((r_timer_mtimecmp_H_4_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_4_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00") then

				r_csr_cmp_4_val <= '1';
			
			end if;
			if( r_addr_mem_00(29 downto 0)  = c_TIMER_CMPCTL_5 and w_rw_mem_00 = '1') then

				r_csr_cmp_5_val <= r_data_in_mem_00(0);

			elsif(r_timer_cmpctl_5_val(1) = '1' AND ((r_timer_mtimecmp_H_5_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_5_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00") then

				r_csr_cmp_5_val <= '1';
			
			end if;
			

			-- On Write
			if( w_rw_mem_00 = '1' ) then

				--Check the address to write
				case( r_addr_mem_00(29 downto 0) ) is

					--Handle writing TIMER Control Register
					when c_TIMER_CTL	 						=> 	r_timer_ctl_val(7 downto 0)			<= r_data_in_mem_00;

					--Handle writing TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_0						=> 	r_timer_cmpctl_0_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_1	 					=> 	r_timer_cmpctl_1_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Control Register 2
					when c_TIMER_CMPCTL_2						=> 	r_timer_cmpctl_2_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Control Register 3
					when c_TIMER_CMPCTL_3	 					=> 	r_timer_cmpctl_3_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Control Register 4
					when c_TIMER_CMPCTL_4						=> 	r_timer_cmpctl_4_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Control Register 5
					when c_TIMER_CMPCTL_5	 					=> 	r_timer_cmpctl_5_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Counter Low Register
					when c_TIMER_MTIME_L						=> r_timer_mtime_L_I_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Counter High Register
					when c_TIMER_MTIME_H						=> r_timer_mtime_H_I_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_0					=> r_timer_mtimecmp_L_0_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_0					=> r_timer_mtimecmp_H_0_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_1					=> r_timer_mtimecmp_L_1_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_1					=> r_timer_mtimecmp_H_1_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_2					=> r_timer_mtimecmp_L_2_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_2					=> r_timer_mtimecmp_H_2_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_3					=> r_timer_mtimecmp_L_3_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_3					=> r_timer_mtimecmp_H_3_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_4					=> r_timer_mtimecmp_L_4_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_4					=> r_timer_mtimecmp_H_4_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_5					=> r_timer_mtimecmp_L_5_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_5					=> r_timer_mtimecmp_H_5_val(7 downto 0)	<= r_data_in_mem_00;

					--Handle writing TIMER Vector Register
					when c_TIMER_VEC							=> r_timer_vec_val(7 downto 0)			<= r_data_in_mem_00;

					when others									=>

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_00(29 downto 0) ) is

					--Handle reading TIMER Control Register
					when c_TIMER_CTL							=> 	r_data_out_mem_00 <= r_timer_ctl_val(7 downto 0);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_0						=> 	r_data_out_mem_00 <= r_timer_cmpctl_0_val(7 downto 0);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_1						=> 	r_data_out_mem_00 <= r_timer_cmpctl_1_val(7 downto 0);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_2						=> 	r_data_out_mem_00 <= r_timer_cmpctl_2_val(7 downto 0);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_3						=> 	r_data_out_mem_00 <= r_timer_cmpctl_3_val(7 downto 0);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_4						=> 	r_data_out_mem_00 <= r_timer_cmpctl_4_val(7 downto 0);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_5						=> 	r_data_out_mem_00 <= r_timer_cmpctl_5_val(7 downto 0);

					--Handle reading TIMER Counter Low Register
					when c_TIMER_MTIME_L						=> r_data_out_mem_00 <= r_timer_mtime_L_I_val(7 downto 0);

					--Handle reading TIMER Counter High Register
					when c_TIMER_MTIME_H						=> r_data_out_mem_00 <= r_timer_mtime_H_I_val(7 downto 0);

					--Handle reading TIMER Compare Low Register 0
					when c_TIMER_MTIMECMP_L_0					=> r_data_out_mem_00 <= r_timer_mtimecmp_L_0_val(7 downto 0);
					
					--Handle reading TIMER Compare High Register 0
					when c_TIMER_MTIMECMP_H_0					=> r_data_out_mem_00 <= r_timer_mtimecmp_H_0_val(7 downto 0);

					--Handle reading TIMER Compare Low Register 1
					when c_TIMER_MTIMECMP_L_1					=> r_data_out_mem_00 <= r_timer_mtimecmp_L_1_val(7 downto 0);
					
					--Handle reading TIMER Compare High Register 1
					when c_TIMER_MTIMECMP_H_1					=> r_data_out_mem_00 <= r_timer_mtimecmp_H_1_val(7 downto 0);

					--Handle reading TIMER Compare Low Register 2
					when c_TIMER_MTIMECMP_L_2					=> r_data_out_mem_00 <= r_timer_mtimecmp_L_2_val(7 downto 0);
					
					--Handle reading TIMER Compare High Register 2
					when c_TIMER_MTIMECMP_H_2					=> r_data_out_mem_00 <= r_timer_mtimecmp_H_2_val(7 downto 0);

					--Handle reading TIMER Compare Low Register 3
					when c_TIMER_MTIMECMP_L_3					=> r_data_out_mem_00 <= r_timer_mtimecmp_L_3_val(7 downto 0);
					
					--Handle reading TIMER Compare High Register 3
					when c_TIMER_MTIMECMP_H_3					=> r_data_out_mem_00 <= r_timer_mtimecmp_H_3_val(7 downto 0);

					--Handle reading TIMER Compare Low Register 4
					when c_TIMER_MTIMECMP_L_4					=> r_data_out_mem_00 <= r_timer_mtimecmp_L_4_val(7 downto 0);
					
					--Handle reading TIMER Compare High Register 4
					when c_TIMER_MTIMECMP_H_4					=> r_data_out_mem_00 <= r_timer_mtimecmp_H_4_val(7 downto 0);

					--Handle reading TIMER Compare Low Register 5
					when c_TIMER_MTIMECMP_L_5					=> r_data_out_mem_00 <= r_timer_mtimecmp_L_5_val(7 downto 0);
					
					--Handle reading TIMER Compare High Register 5
					when c_TIMER_MTIMECMP_H_5					=> r_data_out_mem_00 <= r_timer_mtimecmp_H_5_val(7 downto 0);

					--Handle reading TIMER Interrupt Vector Register
					when c_TIMER_VEC							=> r_data_out_mem_00 <= r_timer_vec_val(7 downto 0);

					when others									=> 	r_data_out_mem_00 <= x"00";

				end case;


				--Automatically reset TCLR bit
				r_timer_ctl_val(2)	<= '0';

				--If interrupts enabled
				if (r_timer_ctl_val(1) = '1') then

					--Update TIMER Control IFG
					if (r_timer_cmpctl_0_val(0) = '1' OR r_timer_cmpctl_1_val(0) = '1' OR r_timer_cmpctl_2_val(0) = '1' OR r_timer_cmpctl_3_val(0) = '1' OR r_timer_cmpctl_4_val(0) = '1' OR r_timer_cmpctl_5_val(0) = '1') then

						r_timer_ctl_val(0) <= '1';

					end if;

					--Update TIMER Compare Control IFG
					r_timer_cmpctl_0_val(0) <= r_csr_cmp_0_val;
					r_timer_cmpctl_1_val(0) <= r_csr_cmp_1_val;
					r_timer_cmpctl_2_val(0) <= r_csr_cmp_2_val;
					r_timer_cmpctl_3_val(0) <= r_csr_cmp_3_val;
					r_timer_cmpctl_4_val(0) <= r_csr_cmp_4_val;
					r_timer_cmpctl_5_val(0) <= r_csr_cmp_5_val;

					--Update TIMER Vector Register
					r_timer_vec_val(7 downto 0) <= std_logic_vector(to_unsigned(v_mtime_vec, r_timer_vec_val'length/4));

					--Priority If-Else chain for the TIMER vector register
					--14 is lowest priority
					--0  is no interrupt pending
					if ( r_csr_cmp_5_val = '1') then
						v_mtimecmp_5 := 14;
					else
						v_mtimecmp_5 := 0;
					end if;

					if ( r_csr_cmp_4_val = '1') then
						v_mtimecmp_4 := 12;
					else
						v_mtimecmp_4 := v_mtimecmp_5;
					end if;

					if ( r_csr_cmp_3_val = '1') then
						v_mtimecmp_3 := 10;
					else
						v_mtimecmp_3 := v_mtimecmp_4;
					end if;

					if ( r_csr_cmp_2_val = '1') then
						v_mtimecmp_2 := 8;
					else
						v_mtimecmp_2 := v_mtimecmp_3;
					end if;

					if ( r_csr_cmp_1_val = '1') then
						v_mtimecmp_1 := 4;
					else
						v_mtimecmp_1 := v_mtimecmp_2;
					end if;

					if ( r_csr_cmp_0_val = '1') then
						v_mtime_vec := 2;
					else
						v_mtime_vec := v_mtimecmp_1;
					end if;

				end if;

			end if;

		end if;

	end process;

	--WRITE to Memory Device 01
	MEM_WRITE_01 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear TIMER
		if( i_reset_n = '0' ) then

			r_timer_ctl_val(15 downto 8)			<= x"00";
			r_timer_cmpctl_0_val(15 downto 8)		<= x"00";
			r_timer_cmpctl_1_val(15 downto 8)		<= x"00";
			r_timer_cmpctl_2_val(15 downto 8)		<= x"00";
			r_timer_cmpctl_3_val(15 downto 8)		<= x"00";
			r_timer_cmpctl_4_val(15 downto 8)		<= x"00";
			r_timer_cmpctl_5_val(15 downto 8)		<= x"00";
			r_timer_mtime_L_I_val(15 downto 8)		<= x"00";
			r_timer_mtime_H_I_val(15 downto 8)		<= x"00";
			r_timer_mtimecmp_L_0_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_H_0_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_L_1_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_H_1_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_L_2_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_H_2_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_L_3_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_H_3_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_L_4_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_H_4_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_L_5_val(15 downto 8)	<= x"00";
			r_timer_mtimecmp_H_5_val(15 downto 8)	<= x"00";
			r_timer_vec_val(15 downto 8)			<= x"00";
		
		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On Writr_addr_mem_00e
			if( w_rw_mem_01 = '1' ) then

				--Check the address to write
				case( r_addr_mem_01(29 downto 0) ) is

					--Handle writing TIMER Control Register
					when c_TIMER_CTL	 						=> 	r_timer_ctl_val(15 downto 8)		<= r_data_in_mem_01;

					--Handle writing TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_0						=> 	r_timer_cmpctl_0_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_1	 					=> 	r_timer_cmpctl_1_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Control Register 2
					when c_TIMER_CMPCTL_2						=> 	r_timer_cmpctl_2_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Control Register 3
					when c_TIMER_CMPCTL_3	 					=> 	r_timer_cmpctl_3_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Control Register 4
					when c_TIMER_CMPCTL_4						=> 	r_timer_cmpctl_4_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Control Register 5
					when c_TIMER_CMPCTL_5	 					=> 	r_timer_cmpctl_5_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Counter Low Register
					when c_TIMER_MTIME_L						=> r_timer_mtime_L_I_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Counter High Register
					when c_TIMER_MTIME_H						=> r_timer_mtime_H_I_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_0					=> r_timer_mtimecmp_L_0_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_0					=> r_timer_mtimecmp_H_0_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_1					=> r_timer_mtimecmp_L_1_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_1					=> r_timer_mtimecmp_H_1_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_2					=> r_timer_mtimecmp_L_2_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_2					=> r_timer_mtimecmp_H_2_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_3					=> r_timer_mtimecmp_L_3_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_3					=> r_timer_mtimecmp_H_3_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_4					=> r_timer_mtimecmp_L_4_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_4					=> r_timer_mtimecmp_H_4_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_5					=> r_timer_mtimecmp_L_5_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_5					=> r_timer_mtimecmp_H_5_val(15 downto 8)	<= r_data_in_mem_01;

					--Handle writing TIMER Vector Register
					when c_TIMER_VEC							=> r_timer_vec_val(15 downto 8)			<= r_data_in_mem_01;

					when others									=>

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_01(29 downto 0) ) is

					--Handle reading TIMER Control Register
					when c_TIMER_CTL							=> 	r_data_out_mem_01 <= r_timer_ctl_val(15 downto 8);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_0						=> 	r_data_out_mem_01 <= r_timer_cmpctl_0_val(15 downto 8);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_1						=> 	r_data_out_mem_01 <= r_timer_cmpctl_1_val(15 downto 8);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_2						=> 	r_data_out_mem_01 <= r_timer_cmpctl_2_val(15 downto 8);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_3						=> 	r_data_out_mem_01 <= r_timer_cmpctl_3_val(15 downto 8);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_4						=> 	r_data_out_mem_01 <= r_timer_cmpctl_4_val(15 downto 8);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_5						=> 	r_data_out_mem_01 <= r_timer_cmpctl_5_val(15 downto 8);

					--Handle reading TIMER Counter Low Register
					when c_TIMER_MTIME_L						=> r_data_out_mem_01 <= r_timer_mtime_L_O_val(15 downto 8);

					--Handle reading TIMER Counter High Register
					when c_TIMER_MTIME_H						=> r_data_out_mem_01 <= r_timer_mtime_H_O_val(15 downto 8);

					--Handle reading TIMER Compare Low Register 0
					when c_TIMER_MTIMECMP_L_0					=> r_data_out_mem_01 <= r_timer_mtimecmp_L_0_val(15 downto 8);
					
					--Handle reading TIMER Compare High Register 0
					when c_TIMER_MTIMECMP_H_0					=> r_data_out_mem_01 <= r_timer_mtimecmp_H_0_val(15 downto 8);

					--Handle reading TIMER Compare Low Register 1
					when c_TIMER_MTIMECMP_L_1					=> r_data_out_mem_01 <= r_timer_mtimecmp_L_1_val(15 downto 8);
					
					--Handle reading TIMER Compare High Register 1
					when c_TIMER_MTIMECMP_H_1					=> r_data_out_mem_01 <= r_timer_mtimecmp_H_1_val(15 downto 8);

					--Handle reading TIMER Compare Low Register 2
					when c_TIMER_MTIMECMP_L_2					=> r_data_out_mem_01 <= r_timer_mtimecmp_L_2_val(15 downto 8);
					
					--Handle reading TIMER Compare High Register 2
					when c_TIMER_MTIMECMP_H_2					=> r_data_out_mem_01 <= r_timer_mtimecmp_H_2_val(15 downto 8);

					--Handle reading TIMER Compare Low Register 3
					when c_TIMER_MTIMECMP_L_3					=> r_data_out_mem_01 <= r_timer_mtimecmp_L_3_val(15 downto 8);
					
					--Handle reading TIMER Compare High Register 3
					when c_TIMER_MTIMECMP_H_3					=> r_data_out_mem_01 <= r_timer_mtimecmp_H_3_val(15 downto 8);

					--Handle reading TIMER Compare Low Register 4
					when c_TIMER_MTIMECMP_L_4					=> r_data_out_mem_01 <= r_timer_mtimecmp_L_4_val(15 downto 8);
					
					--Handle reading TIMER Compare High Register 4
					when c_TIMER_MTIMECMP_H_4					=> r_data_out_mem_01 <= r_timer_mtimecmp_H_4_val(15 downto 8);

					--Handle reading TIMER Compare Low Register 5
					when c_TIMER_MTIMECMP_L_5					=> r_data_out_mem_01 <= r_timer_mtimecmp_L_5_val(15 downto 8);
					
					--Handle reading TIMER Compare High Register 5
					when c_TIMER_MTIMECMP_H_5					=> r_data_out_mem_01 <= r_timer_mtimecmp_H_5_val(15 downto 8);

					--Handle reading TIMER Interrupt Vector Register
					when c_TIMER_VEC							=> r_data_out_mem_01 <= r_timer_vec_val(15 downto 8);

					when others									=> 	r_data_out_mem_01 <= x"00";

				end case;

			end if;

		end if;
		
	end process;

	--WRITE to Memory Device 02
	MEM_WRITE_02 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear TIMER
		if( i_reset_n = '0' ) then

			r_timer_ctl_val(23 downto 16)			<= x"00";
			r_timer_cmpctl_0_val(23 downto 16)		<= x"00";
			r_timer_cmpctl_1_val(23 downto 16)		<= x"00";
			r_timer_cmpctl_2_val(23 downto 16)		<= x"00";
			r_timer_cmpctl_3_val(23 downto 16)		<= x"00";
			r_timer_cmpctl_4_val(23 downto 16)		<= x"00";
			r_timer_cmpctl_5_val(23 downto 16)		<= x"00";
			r_timer_mtime_L_I_val(23 downto 16)		<= x"00";
			r_timer_mtime_H_I_val(23 downto 16)		<= x"00";
			r_timer_mtimecmp_L_0_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_H_0_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_L_1_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_H_1_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_L_2_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_H_2_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_L_3_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_H_3_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_L_4_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_H_4_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_L_5_val(23 downto 16)	<= x"00";
			r_timer_mtimecmp_H_5_val(23 downto 16)	<= x"00";
			r_timer_vec_val(23 downto 16)			<= x"00";
		
		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On Write
			if( w_rw_mem_02 = '1' ) then

				--Check the address to write
				case( r_addr_mem_02(29 downto 0) ) is

					--Handle writing TIMER Control Register
					when c_TIMER_CTL	 						=> 	r_timer_ctl_val(23 downto 16)		<= r_data_in_mem_02;

					--Handle writing TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_0						=> 	r_timer_cmpctl_0_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_1	 					=> 	r_timer_cmpctl_1_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Control Register 2
					when c_TIMER_CMPCTL_2						=> 	r_timer_cmpctl_2_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Control Register 3
					when c_TIMER_CMPCTL_3	 					=> 	r_timer_cmpctl_3_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Control Register 4
					when c_TIMER_CMPCTL_4						=> 	r_timer_cmpctl_4_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Control Register 5
					when c_TIMER_CMPCTL_5	 					=> 	r_timer_cmpctl_5_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Counter Low Register
					when c_TIMER_MTIME_L						=> r_timer_mtime_L_I_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Counter High Register
					when c_TIMER_MTIME_H						=> r_timer_mtime_H_I_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_0					=> r_timer_mtimecmp_L_0_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_0					=> r_timer_mtimecmp_H_0_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_1					=> r_timer_mtimecmp_L_1_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_1					=> r_timer_mtimecmp_H_1_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_2					=> r_timer_mtimecmp_L_2_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_2					=> r_timer_mtimecmp_H_2_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_3					=> r_timer_mtimecmp_L_3_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_3					=> r_timer_mtimecmp_H_3_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_4					=> r_timer_mtimecmp_L_4_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_4					=> r_timer_mtimecmp_H_4_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_5					=> r_timer_mtimecmp_L_5_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_5					=> r_timer_mtimecmp_H_5_val(23 downto 16)	<= r_data_in_mem_02;

					--Handle writing TIMER Vector Register
					when c_TIMER_VEC							=> r_timer_vec_val(23 downto 16)			<= r_data_in_mem_02;

					when others									=>

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_02(29 downto 0) ) is

					--Handle reading TIMER Control Register
					when c_TIMER_CTL							=> 	r_data_out_mem_02 <= r_timer_ctl_val(23 downto 16);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_0						=> 	r_data_out_mem_02 <= r_timer_cmpctl_0_val(23 downto 16);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_1						=> 	r_data_out_mem_02 <= r_timer_cmpctl_1_val(23 downto 16);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_2						=> 	r_data_out_mem_02 <= r_timer_cmpctl_2_val(23 downto 16);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_3						=> 	r_data_out_mem_02 <= r_timer_cmpctl_3_val(23 downto 16);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_4						=> 	r_data_out_mem_02 <= r_timer_cmpctl_4_val(23 downto 16);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_5						=> 	r_data_out_mem_02 <= r_timer_cmpctl_5_val(23 downto 16);

					--Handle reading TIMER Counter Low Register
					when c_TIMER_MTIME_L						=> r_data_out_mem_02 <= r_timer_mtime_L_O_val(23 downto 16);

					--Handle reading TIMER Counter High Register
					when c_TIMER_MTIME_H						=> r_data_out_mem_02 <= r_timer_mtime_H_O_val(23 downto 16);

					--Handle reading TIMER Compare Low Register 0
					when c_TIMER_MTIMECMP_L_0					=> r_data_out_mem_02 <= r_timer_mtimecmp_L_0_val(23 downto 16);
					
					--Handle reading TIMER Compare High Register 0
					when c_TIMER_MTIMECMP_H_0					=> r_data_out_mem_02 <= r_timer_mtimecmp_H_0_val(23 downto 16);

					--Handle reading TIMER Compare Low Register 1
					when c_TIMER_MTIMECMP_L_1					=> r_data_out_mem_02 <= r_timer_mtimecmp_L_1_val(23 downto 16);
					
					--Handle reading TIMER Compare High Register 1
					when c_TIMER_MTIMECMP_H_1					=> r_data_out_mem_02 <= r_timer_mtimecmp_H_1_val(23 downto 16);

					--Handle reading TIMER Compare Low Register 2
					when c_TIMER_MTIMECMP_L_2					=> r_data_out_mem_02 <= r_timer_mtimecmp_L_2_val(23 downto 16);
					
					--Handle reading TIMER Compare High Register 2
					when c_TIMER_MTIMECMP_H_2					=> r_data_out_mem_02 <= r_timer_mtimecmp_H_2_val(23 downto 16);

					--Handle reading TIMER Compare Low Register 3
					when c_TIMER_MTIMECMP_L_3					=> r_data_out_mem_02 <= r_timer_mtimecmp_L_3_val(23 downto 16);
					
					--Handle reading TIMER Compare High Register 3
					when c_TIMER_MTIMECMP_H_3					=> r_data_out_mem_02 <= r_timer_mtimecmp_H_3_val(23 downto 16);

					--Handle reading TIMER Compare Low Register 4
					when c_TIMER_MTIMECMP_L_4					=> r_data_out_mem_02 <= r_timer_mtimecmp_L_4_val(23 downto 16);
					
					--Handle reading TIMER Compare High Register 4
					when c_TIMER_MTIMECMP_H_4					=> r_data_out_mem_02 <= r_timer_mtimecmp_H_4_val(23 downto 16);

					--Handle reading TIMER Compare Low Register 5
					when c_TIMER_MTIMECMP_L_5					=> r_data_out_mem_02 <= r_timer_mtimecmp_L_5_val(23 downto 16);
					
					--Handle reading TIMER Compare High Register 5
					when c_TIMER_MTIMECMP_H_5					=> r_data_out_mem_02 <= r_timer_mtimecmp_H_5_val(23 downto 16);

					--Handle reading TIMER Interrupt Vector Register
					when c_TIMER_VEC							=> r_data_out_mem_02 <= r_timer_vec_val(23 downto 16);

					when others									=> 	r_data_out_mem_02 <= x"00";

				end case;

			end if;

		end if;

	end process;

	--WRITE to Memory Device 03
	MEM_WRITE_03 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear TIMER
		if( i_reset_n = '0' ) then

			r_timer_ctl_val(31 downto 24)			<= x"00";
			r_timer_cmpctl_0_val(31 downto 24)		<= x"00";
			r_timer_cmpctl_1_val(31 downto 24)		<= x"00";
			r_timer_cmpctl_2_val(31 downto 24)		<= x"00";
			r_timer_cmpctl_3_val(31 downto 24)		<= x"00";
			r_timer_cmpctl_4_val(31 downto 24)		<= x"00";
			r_timer_cmpctl_5_val(31 downto 24)		<= x"00";
			r_timer_mtime_L_I_val(31 downto 24)		<= x"00";
			r_timer_mtime_H_I_val(31 downto 24)		<= x"00";
			r_timer_mtimecmp_L_0_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_H_0_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_L_1_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_H_1_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_L_2_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_H_2_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_L_3_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_H_3_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_L_4_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_H_4_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_L_5_val(31 downto 24)	<= x"00";
			r_timer_mtimecmp_H_5_val(31 downto 24)	<= x"00";
			r_timer_vec_val(31 downto 24)			<= x"00";
		
		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On Writr_addr_mem_00e
			if( w_rw_mem_03 = '1' ) then

				--Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					--Handle writing TIMER Control Register
					when c_TIMER_CTL	 						=> 	r_timer_ctl_val(31 downto 24)		<= r_data_in_mem_03;

					--Handle writing TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_0						=> 	r_timer_cmpctl_0_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_1	 					=> 	r_timer_cmpctl_1_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Control Register 2
					when c_TIMER_CMPCTL_2						=> 	r_timer_cmpctl_2_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Control Register 3
					when c_TIMER_CMPCTL_3	 					=> 	r_timer_cmpctl_3_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Control Register 4
					when c_TIMER_CMPCTL_4						=> 	r_timer_cmpctl_4_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Control Register 5
					when c_TIMER_CMPCTL_5	 					=> 	r_timer_cmpctl_5_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Counter Low Register
					when c_TIMER_MTIME_L						=> r_timer_mtime_L_I_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Counter High Register
					when c_TIMER_MTIME_H						=> r_timer_mtime_H_I_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_0					=> r_timer_mtimecmp_L_0_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_0					=> r_timer_mtimecmp_H_0_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_1					=> r_timer_mtimecmp_L_1_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_1					=> r_timer_mtimecmp_H_1_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_2					=> r_timer_mtimecmp_L_2_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_2					=> r_timer_mtimecmp_H_2_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_3					=> r_timer_mtimecmp_L_3_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_3					=> r_timer_mtimecmp_H_3_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_4					=> r_timer_mtimecmp_L_4_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_4					=> r_timer_mtimecmp_H_4_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare Low Register
					when c_TIMER_MTIMECMP_L_5					=> r_timer_mtimecmp_L_5_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Compare High Register
					when c_TIMER_MTIMECMP_H_5					=> r_timer_mtimecmp_H_5_val(31 downto 24)	<= r_data_in_mem_03;

					--Handle writing TIMER Vector Register
					when c_TIMER_VEC							=> r_timer_vec_val(31 downto 24)			<= r_data_in_mem_03;

					when others									=>

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_03(29 downto 0) ) is

					--Handle reading TIMER Control Register
					when c_TIMER_CTL							=> 	r_data_out_mem_03 <= r_timer_ctl_val(31 downto 24);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_0						=> 	r_data_out_mem_03 <= r_timer_cmpctl_0_val(31 downto 24);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_1						=> 	r_data_out_mem_03 <= r_timer_cmpctl_1_val(31 downto 24);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_2						=> 	r_data_out_mem_03 <= r_timer_cmpctl_2_val(31 downto 24);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_3						=> 	r_data_out_mem_03 <= r_timer_cmpctl_3_val(31 downto 24);

					--Handle reading TIMER Compare Control Register 0
					when c_TIMER_CMPCTL_4						=> 	r_data_out_mem_03 <= r_timer_cmpctl_4_val(31 downto 24);

					--Handle reading TIMER Compare Control Register 1
					when c_TIMER_CMPCTL_5						=> 	r_data_out_mem_03 <= r_timer_cmpctl_5_val(31 downto 24);

					--Handle reading TIMER Counter Low Register
					when c_TIMER_MTIME_L						=> r_data_out_mem_03 <= r_timer_mtime_L_O_val(31 downto 24);

					--Handle reading TIMER Counter High Register
					when c_TIMER_MTIME_H						=> r_data_out_mem_03 <= r_timer_mtime_H_O_val(31 downto 24);

					--Handle reading TIMER Compare Low Register 0
					when c_TIMER_MTIMECMP_L_0					=> r_data_out_mem_03 <= r_timer_mtimecmp_L_0_val(31 downto 24);
					
					--Handle reading TIMER Compare High Register 0
					when c_TIMER_MTIMECMP_H_0					=> r_data_out_mem_03 <= r_timer_mtimecmp_H_0_val(31 downto 24);

					--Handle reading TIMER Compare Low Register 1
					when c_TIMER_MTIMECMP_L_1					=> r_data_out_mem_03 <= r_timer_mtimecmp_L_1_val(31 downto 24);
					
					--Handle reading TIMER Compare High Register 1
					when c_TIMER_MTIMECMP_H_1					=> r_data_out_mem_03 <= r_timer_mtimecmp_H_1_val(31 downto 24);

					--Handle reading TIMER Compare Low Register 2
					when c_TIMER_MTIMECMP_L_2					=> r_data_out_mem_03 <= r_timer_mtimecmp_L_2_val(31 downto 24);
					
					--Handle reading TIMER Compare High Register 2
					when c_TIMER_MTIMECMP_H_2					=> r_data_out_mem_03 <= r_timer_mtimecmp_H_2_val(31 downto 24);

					--Handle reading TIMER Compare Low Register 3
					when c_TIMER_MTIMECMP_L_3					=> r_data_out_mem_03 <= r_timer_mtimecmp_L_3_val(31 downto 24);
					
					--Handle reading TIMER Compare High Register 3
					when c_TIMER_MTIMECMP_H_3					=> r_data_out_mem_03 <= r_timer_mtimecmp_H_3_val(31 downto 24);

					--Handle reading TIMER Compare Low Register 4
					when c_TIMER_MTIMECMP_L_4					=> r_data_out_mem_03 <= r_timer_mtimecmp_L_4_val(31 downto 24);
					
					--Handle reading TIMER Compare High Register 4
					when c_TIMER_MTIMECMP_H_4					=> r_data_out_mem_03 <= r_timer_mtimecmp_H_4_val(31 downto 24);

					--Handle reading TIMER Compare Low Register 5
					when c_TIMER_MTIMECMP_L_5					=> r_data_out_mem_03 <= r_timer_mtimecmp_L_5_val(31 downto 24);
					
					--Handle reading TIMER Compare High Register 5
					when c_TIMER_MTIMECMP_H_5					=> r_data_out_mem_03 <= r_timer_mtimecmp_H_5_val(31 downto 24);

					--Handle reading TIMER Interrupt Vector Register
					when c_TIMER_VEC							=> r_data_out_mem_03 <= r_timer_vec_val(31 downto 24);

					when others									=> 	r_data_out_mem_03 <= x"00";

				end case;

			end if;

		end if;
		
	end process;

	TIMER_CLOCK_0 : process(r_clk_src, i_reset_n)
	variable v_timer_cnt	: integer range 0 to 7 := 0;
	begin
		-- On reset, clear TIMER
		if( i_reset_n = '0' ) then
			r_div_0		<= '0';
			v_timer_cnt	:= 0;
		elsif(rising_edge( r_clk_src )) then
			if ( r_timer_div_0 /= "000") then
				if(v_timer_cnt >= r_timer_div_0) then
					v_timer_cnt := 0;
					r_div_0 	<= not r_div_0;
				else
				v_timer_cnt := v_timer_cnt + 1;
				end if;
			else
				r_div_0 	<= not r_div_0;
			end if;
		end if;
	end process;

	TIMER_CLOCK_1 : process(r_clk_div_0, i_reset_n)
	variable v_timer_cnt	: integer range 0 to 7 := 0;
	begin
		-- On reset, clear TIMER
		if( i_reset_n = '0' ) then
			r_div_1		<= '0';
			v_timer_cnt		:= 0;
		elsif(rising_edge( r_clk_div_0 )) then
			if ( r_timer_div_1 /= "000") then
				if(v_timer_cnt = r_timer_div_1) then
					v_timer_cnt := 0;
					r_div_1 	<= not r_div_1;
				else
				v_timer_cnt := v_timer_cnt + 1;
				end if;
			else
				r_div_1		<= not r_div_1;
			end if;
		end if;
	end process;

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	--o_timer_irq		<=	r_timer_ctl_val(0);
	o_timer_irq		<=	'1' when r_timer_cmpctl_0_val(1) = '1' AND ((r_timer_mtimecmp_H_0_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_0_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00" else
						'1' when r_timer_cmpctl_1_val(1) = '1' AND ((r_timer_mtimecmp_H_1_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_1_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00" else
						'1' when r_timer_cmpctl_2_val(1) = '1' AND ((r_timer_mtimecmp_H_2_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_2_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00" else
						'1' when r_timer_cmpctl_3_val(1) = '1' AND ((r_timer_mtimecmp_H_3_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_3_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00" else
						'1' when r_timer_cmpctl_4_val(1) = '1' AND ((r_timer_mtimecmp_H_4_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_4_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00" else
						'1' when r_timer_cmpctl_5_val(1) = '1' AND ((r_timer_mtimecmp_H_5_val = r_timer_mtime_H_O_val) AND (r_timer_mtimecmp_L_5_val = r_timer_mtime_L_O_val)) AND r_timer_ctl_val(5 downto 4) /= "00" else
						'1' when r_timer_ctl_val(0) = '1' else
						'0';

	r_clk_div_0		<=	r_clk_src	when r_timer_ctl_val(7 downto 6)	= "00" else
						r_div_0;

	r_timer_clk		<=	r_clk_div_0	when r_timer_ctl_val(12 downto 10)	= "000" else
						r_div_1;

	r_clk_src		<=	i_clk		when r_timer_ctl_val(9 downto 8)	= "11" else
						i_clk		when r_timer_ctl_val(9 downto 8)	= "10" else
						i_clk		when r_timer_ctl_val(9 downto 8)	= "01" else
						i_clk;

	r_timer_div_0	<=	"011"		when r_timer_ctl_val(7 downto 6)	= "11" else		--1/8
						"001"		when r_timer_ctl_val(7 downto 6)	= "10" else		--1/4
						"000"		when r_timer_ctl_val(7 downto 6)	= "01" else		--1/2
						"000";															--1/1

	r_timer_div_1	<=	"111"		when r_timer_ctl_val(12 downto 10)	= "111" else	--1/16
						"110"		when r_timer_ctl_val(12 downto 10)	= "110" else	--1/14
						"101"		when r_timer_ctl_val(12 downto 10)	= "101" else	--1/12
						"100"		when r_timer_ctl_val(12 downto 10)	= "100" else	--1/10
						"011"		when r_timer_ctl_val(12 downto 10)	= "011" else	--1/8
						"010"		when r_timer_ctl_val(12 downto 10)	= "010" else	--1/4
						"001"		when r_timer_ctl_val(12 downto 10)	= "001" else	--1/2
						"000";															--1/1
	

end architecture;
	----------------------------------------------------------------------------------------------------------------------------------------
	-- END OF CODE
	----------------------------------------------------------------------------------------------------------------------------------------