----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  MEMORY MANAGEMENT UNIT (MMU)
--	I2C MEMORY DEVICE
--
--	CREATED BY TRISTAN RUNNING CRANE, BEN MACHT
--  RESILIENT COMPUTING
-- 	06/11/2024
--
--	A memory map for I2C memory device.
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
	

----------------------------------------------------------------------------------------------------------------------------------------
-- 	ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity mem_i2c is
port(
	i_clk						: in	std_logic;												--! Clock
	i_reset_n					: in	std_logic;												--! Actvece Low Reset

	i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
	i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
	i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
	i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
	o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

	i_scl						: in	std_logic;												--! I2C Incoming Serial Clock
	i_sda						: in	std_logic;												--! I2C Incoming Serial Data
	o_scl						: out	std_logic;												--! I2C Outgoing Serial Clock
	o_sda						: out	std_logic;												--! I2C Outgoing Serial Data
	o_I2C_mode					: out	std_logic_vector(1 downto 0);							--! I2C Transceiver INOUT Signal

	o_i2c_irq					: out	std_logic												--! I2C Interrupt Request Signal
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- 	ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture mem_i2c_arch of mem_i2c is

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the I2C component
	component i2c is
	port(
		i_clk						: in	std_logic;
		i_reset_n					: in	std_logic;

		i_ctl						: in	std_logic_vector(15 downto 0);
		o_status					: out	std_logic_vector(31 downto 0);
		i_brw						: in 	std_logic_vector(15 downto 0);
		i_bcount					: in	std_logic_vector(7 downto 0);
		o_rxbuf						: out	std_logic_vector(7 downto 0);
		i_txbuf						: in	std_logic_vector(7 downto 0);
		i_oaddr						: in	std_logic_vector(15 downto 0);
		i_taddr						: in	std_logic_vector(15 downto 0);
		o_raddr						: out	std_logic_vector(31 downto 0);

		i_scl						: in	std_logic;
		i_sda						: in	std_logic;
		o_scl						: out	std_logic;
		o_sda						: out	std_logic;
		o_i2c_mode					: out	std_logic_vector(1 downto 0)
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
	-- 	CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	constant c_ADDR_SPACE					: integer							:= 48;

	constant c_I2C_CTL						: std_logic_vector(29 downto 0)		:= "00" & x"0000000";	--! I2C Control Address
	constant c_I2C_STATUS					: std_logic_vector(29 downto 0)		:= "00" & x"0000001";	--! I2C Status Address
	constant c_I2C_BRW						: std_logic_vector(29 downto 0)		:= "00" & x"0000002";	--! I2C Bit Rate Control Address
	constant c_I2C_BCOUNT					: std_logic_vector(29 downto 0)		:= "00" & x"0000003";	--! I2C Bit Count Threshold Address
	constant c_I2C_RXBUF					: std_logic_vector(29 downto 0)		:= "00" & x"0000004";	--! I2C RX Buffer Address
	constant c_I2C_TXBUF					: std_logic_vector(29 downto 0)		:= "00" & x"0000005";	--! I2C TX Buffer Address
	constant c_I2C_OADDR					: std_logic_vector(29 downto 0)		:= "00" & x"0000006";	--! I2C Own Address
	constant c_I2C_TADDR					: std_logic_vector(29 downto 0)		:= "00" & x"0000007";	--! I2C Target Address
	constant c_I2C_RADDR					: std_logic_vector(29 downto 0)		:= "00" & x"0000008";	--! I2C Received Address
	constant c_I2C_IE						: std_logic_vector(29 downto 0)		:= "00" & x"0000009";	--! I2C Interupt Enable Address
	constant c_I2C_IFG						: std_logic_vector(29 downto 0)		:= "00" & x"000000A";	--! I2C Interrupt Flag Address
	constant c_I2C_VEC						: std_logic_vector(29 downto 0)		:= "00" & x"000000B";	--! I2C Interrupt Vector Address


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_i2c_ctl_val					: std_logic_vector(15 downto 0)		:= x"0001";				--! I2C Control Register
	signal r_i2c_status_val					: std_logic_vector(31 downto 0)		:= x"00000000";			--! I2C Status Register
	signal r_i2c_brw_val					: std_logic_vector(15 downto 0)		:= x"0000";			   	--! I2C Bit Rate Word Control Register
	signal r_i2c_bcount_val					: std_logic_vector(7 downto 0)		:= x"00";				--! I2C Bit Count Threshold Register
	signal r_i2c_rxbuf_val					: std_logic_vector(7 downto 0)		:= x"00";				--! I2C RX Buffer Register
	signal r_i2c_txbuf_val					: std_logic_vector(7 downto 0)		:= x"00";				--! I2C TX BUffer Register
	signal r_i2c_raddr_val					: std_logic_vector(31 downto 0)		:= x"00000000";			--! I2C Received Adress Register
	signal r_i2c_oaddr_val					: std_logic_vector(15 downto 0)		:= x"0000";				--! I2C Own Adress Register
	signal r_i2c_taddr_val					: std_logic_vector(15 downto 0)		:= x"0000";				--! I2C Target Adress Register
	
	signal r_i2c_ie_val						: std_logic_vector(31 downto 0)		:= x"00000000";			--! I2C Interrupt Enable Register
	signal r_i2c_ifg_val					: std_logic_vector(31 downto 0)		:= x"00000000";			--! I2C Interrupt Flag Register
	--signal r_i2c_vec_val					: std_logic_vector(31 downto 0)		:= x"00000000";			--! I2C Interrupt Vector Register

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

	signal w_rw_mem_00						: std_logic;												--! Memory Device Read/Write 00
	signal w_rw_mem_01						: std_logic;												--! Memory Device Read/Write 01
	signal w_rw_mem_02						: std_logic;												--! Memory Device Read/Write 02
	signal w_rw_mem_03						: std_logic;												--! Memory Device Read/Write 03
	
	signal r_status							: std_logic_vector(31 downto 0)		:= x"00000000";
	signal r_rxbuf							: std_logic_vector(7 downto 0)		:= x"00";
	signal r_raddr							: std_logic_vector(31 downto 0)		:= x"00000000";

	--signal r_rx_ifg_delay					: std_logic;

	signal w_scl							: std_logic;
	signal w_sda							: std_logic;
	signal w_i2c_mode						: std_logic_vector(1 downto 0);


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------	

	-- Instantiate the I2C
	I2C_00 : i2c
	port map(
		i_clk								=> i_clk,
		i_reset_n							=> i_reset_n,
		
		i_ctl								=> r_i2c_ctl_val,
		o_status							=> r_status,
		i_brw								=> r_i2c_brw_val,
		i_bcount							=> r_i2c_bcount_val,
		o_rxbuf								=> r_rxbuf,
		i_txbuf								=> r_i2c_txbuf_val,
		i_oaddr								=> r_i2c_oaddr_val,
		i_taddr								=> r_i2c_taddr_val,
		o_raddr								=> r_raddr,

		i_scl								=> i_scl,
		i_sda								=> i_sda,
		o_scl								=> w_scl,
		o_sda								=> w_sda,
		o_i2c_mode							=> w_i2c_mode
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
	-- 	MEMORY READ/WRITE
	------------------------------------------------------------------------------------------------------------------------------------

	--WRITE to Memory Device 00
	MEM_WRITE_00 : process( i_clk, i_reset_n )

		variable v_i2c_vec_0			: integer range 0 to 31;
		variable v_i2c_vec_1			: integer range 0 to 31;
		variable v_i2c_vec_2			: integer range 0 to 31;
		variable v_i2c_vec_3			: integer range 0 to 31;
		variable v_i2c_vec_4			: integer range 0 to 31;
		variable v_i2c_vec_5			: integer range 0 to 31;
		variable v_i2c_vec_6			: integer range 0 to 31;
		variable v_i2c_vec_7			: integer range 0 to 31;
		variable v_i2c_vec_8			: integer range 0 to 31;
		variable v_i2c_vec_9			: integer range 0 to 31;
		variable v_i2c_vec_10			: integer range 0 to 31;
		variable v_i2c_vec_11			: integer range 0 to 31;
		variable v_i2c_vec_12			: integer range 0 to 31;
		variable v_i2c_vec_13			: integer range 0 to 31;
		variable v_i2c_vec_14			: integer range 0 to 31;

	begin

		-- On reset, clear registers
		if ( i_reset_n = '0') then

			r_i2c_ctl_val		(7 downto 0)	<= x"01";
			r_i2c_status_val	(7 downto 0)	<= x"00";
			r_i2c_brw_val		(7 downto 0)	<= x"00";
			r_i2c_bcount_val	(7 downto 0)	<= x"00";
			-- r_i2c_rxbuf_val		(7 downto 0)	<= x"00";
			r_i2c_txbuf_val		(7 downto 0)	<= x"00";
			r_i2c_oaddr_val		(7 downto 0)	<= x"00";
			r_i2c_taddr_val		(7 downto 0)	<= x"00";
			r_i2c_raddr_val		(7 downto 0)	<= x"00";
			r_i2c_ie_val		(7 downto 0)	<= x"00";
			r_i2c_ifg_val		(7 downto 0)	<= x"00";
			--r_i2c_vec_val		(7 downto 0)	<= x"00";

		-- On rising clock edge
		elsif ( rising_edge(i_clk) ) then

			--r_rx_ifg_delay <= r_i2c_ifg_val(0);

			-- On Write
			if( w_rw_mem_00 = '1' ) then
				--Check the address to write
				case( r_addr_mem_00(29 downto 0) ) is

					--Handle writing I2C Control Register
					when c_I2C_CTL	 						=>	r_i2c_ctl_val(7 downto 0)			<= r_data_in_mem_00;

					--Handle writing I2C  Bit Rate Word Control Register
					when c_I2C_BRW	 						=>	r_i2c_brw_val(7 downto 0)			<= r_data_in_mem_00;

					--Handle writing  I2C Bit Count Threshold Register
					when c_I2C_BCOUNT						=>	r_i2c_bcount_val(7 downto 0)		<= r_data_in_mem_00;

					--Handle writing I2C TX Buff Register
					when c_I2C_TXBUF						=>	r_i2c_txbuf_val(7 downto 0)			<= r_data_in_mem_00;
																r_i2c_ifg_val(1) <= '0';

					--Handle writing I2C Own Address Register
					when c_I2C_OADDR						=>	r_i2c_oaddr_val(7 downto 0)			<= r_data_in_mem_00;

					--Handle writing I2C Target Address Register
					when c_I2C_TADDR						=>	r_i2c_taddr_val(7 downto 0)			<= r_data_in_mem_00;

					--Handle writing I2C Interrupt Enable Register
					when c_I2C_IE							=>	r_i2c_ie_val(7 downto 0)			<= r_data_in_mem_00;

					--Handle writing I2C Interrupt Flag Register
					when c_I2C_IFG							=>	r_i2c_ifg_val(7 downto 0)			<= r_data_in_mem_00;

					-- Handle defaults
					when others								=>

				end case;

			else

				--Check the address to read
				case( r_addr_mem_00(29 downto 0) ) is

					--Handle reading I2C Control Register
					when c_I2C_CTL	 						=>	r_data_out_mem_00					<= r_i2c_ctl_val(7 downto 0);

					--Handle reading I2C Status Register
					when c_I2C_STATUS						=>	r_data_out_mem_00					<= r_i2c_status_val(7 downto 0);

					--Handle reading I2C Bit Rate Word Control Register
					when c_I2C_BRW	 						=>	r_data_out_mem_00					<= r_i2c_brw_val(7 downto 0);

					--Handle reading I2C Bit Count Threshold Register
					when c_I2C_BCOUNT						=>	r_data_out_mem_00					<= r_i2c_bcount_val(7 downto 0);

					--Handle reading I2C RX Buff Register
					when c_I2C_RXBUF						=>	r_data_out_mem_00					<= r_rxbuf(7 downto 0); --changed to avoid delay in loading received data
					-- 											--r_i2c_ifg_val(0) <= '0';

					-- when c_I2C_RXBUF						=>	r_data_out_mem_00					<= r_i2c_rxbuf_val(7 downto 0);
																--r_i2c_ifg_val(0) <= '0';

					--Handle reading I2C TX Buff Register
					when c_I2C_TXBUF						=>	r_data_out_mem_00					<= r_i2c_txbuf_val(7 downto 0);

					--Handle reading I2C Own Address Register
					when c_I2C_OADDR						=>	r_data_out_mem_00					<= r_i2c_oaddr_val(7 downto 0);

					--Handle reading I2C Target Address Register
					when c_I2C_TADDR						=>	r_data_out_mem_00					<= r_i2c_taddr_val(7 downto 0);

					--Handle reading I2C Recieve Address Register
					when c_I2C_RADDR						=>	r_data_out_mem_00					<= r_i2c_raddr_val(7 downto 0);

					--Handle reading I2C Interrupt Enable Register
					when c_I2C_IE							=>	r_data_out_mem_00					<= r_i2c_ie_val(7 downto 0);

					--Handle reading I2C Interrupt Flag Register
					when c_I2C_IFG							=>	r_data_out_mem_00					<= r_i2c_ifg_val(7 downto 0);

					--Handle reading I2C Interrupt Vector Register
					when c_I2C_VEC							=>	--r_data_out_mem_00					<= r_i2c_vec_val(7 downto 0);

					-- Handle defaults
					when others								=> 	r_data_out_mem_00 					<= x"00";

				end case;

				--Update Status Register with status of I2C State Machine
				r_i2c_status_val(7 downto 0)	<= r_status(7 downto 0);

				--Update Recieved Address Register with State Machines Last Recieved Address
				r_i2c_raddr_val(7 downto 0)		<= r_raddr(7 downto 0);


				--Clear Start bit when address transmit is complete
				if (r_i2c_status_val(3) = '1') then
					r_i2c_ctl_val(1)	<= '0';
				end if;

				--When RX Buf IE is set and RX Buf has data set TX Buf IFG
				if(r_i2c_status_val(6) = '1') then
					r_i2c_ifg_val(0) <= '1';
					r_i2c_rxbuf_val(7 downto 0)		<= r_rxbuf(7 downto 0);
				elsif(r_i2c_ifg_val(0) = '0' ) then 									--AND r_rx_ifg_delay = '1') then
					r_i2c_rxbuf_val(7 downto 0)		<= x"00";
				end if;

				--When TX Buf IE is set and TX Buf is ready for more data set TX Buf IFG
				if(r_i2c_status_val(4) = '1' AND r_i2c_ctl_val(4) = '1') then
					r_i2c_ifg_val(1) <= '1';
				end if;

				--When a Stop is detected on the bus stop IFG is set if IE is set
				if(r_i2c_status_val(17) = '1') then
					r_i2c_ifg_val(3) <= '1';
				end if;

				--When in Controller Mode and a NACK is detected on the line set IFG if IE is set
				if(r_i2c_status_val(18) = '1') then
					r_i2c_ifg_val(5) <= '1';
				end if;

				--When TX Buf has transfered byte to shift register reset TX Buf Regiser
				if(r_i2c_status_val(5) = '1' AND r_i2c_txbuf_val /= x"00") then
					r_i2c_txbuf_val(7 downto 0) <= x"00";
				end if;

				--When in Byte Count Threshold is reached set IFG if IE is set
				if(r_i2c_status_val(19) = '1') then
					r_i2c_ifg_val(6) <= '1';
				end if;

				--r_i2c_vec_val(7 downto 0) <= std_logic_vector(to_unsigned(v_i2c_vec_0, r_i2c_vec_val'length/4));

				if(r_i2c_ifg_val(14) = '1' AND r_i2c_ie_val(14) = '1') then
					v_i2c_vec_14 := 30;
				else
					v_i2c_vec_14 := 0;
				end if;

				if(r_i2c_ifg_val(7) = '1' AND r_i2c_ie_val(7) = '1') then
					v_i2c_vec_13 := 28;
				else
					v_i2c_vec_13 := v_i2c_vec_14;
				end if;

				if(r_i2c_ifg_val(6) = '1' AND r_i2c_ie_val(6) = '1') then
					v_i2c_vec_12 := 26;
				else
					v_i2c_vec_12 := v_i2c_vec_13;
				end if;

				if(r_i2c_ifg_val(1) = '1' AND r_i2c_ie_val(1) = '1') then
					v_i2c_vec_11 := 24;
				else
					v_i2c_vec_11 := v_i2c_vec_12;
				end if;

				if(r_i2c_ifg_val(0) = '1' AND r_i2c_ie_val(0) = '1') then
					v_i2c_vec_10 := 22;
				else
					v_i2c_vec_10 := v_i2c_vec_11;
				end if;

				if(r_i2c_ifg_val(9) = '1' AND r_i2c_ie_val(9) = '1') then
					v_i2c_vec_9 := 20;
				else
					v_i2c_vec_9 := v_i2c_vec_10;
				end if;

				if(r_i2c_ifg_val(8) = '1' AND r_i2c_ie_val(8) = '1') then
					v_i2c_vec_8 := 18;
				else
					v_i2c_vec_8 := v_i2c_vec_9;
				end if;

				if(r_i2c_ifg_val(11) = '1' AND r_i2c_ie_val(11) = '1') then
					v_i2c_vec_7 := 16;
				else
					v_i2c_vec_7 := v_i2c_vec_8;
				end if;

				if(r_i2c_ifg_val(10) = '1' AND r_i2c_ie_val(10) = '1') then
					v_i2c_vec_6 := 14;
				else
					v_i2c_vec_6 := v_i2c_vec_7;
				end if;

				if(r_i2c_ifg_val(13) = '1' AND r_i2c_ie_val(13) = '1') then
					v_i2c_vec_5 := 12;
				else
					v_i2c_vec_5 := v_i2c_vec_6;
				end if;

				if(r_i2c_ifg_val(12) = '1' AND r_i2c_ie_val(12) = '1') then
					v_i2c_vec_4 := 10;
				else
					v_i2c_vec_4 := v_i2c_vec_5;
				end if;

				if(r_i2c_ifg_val(3) = '1' AND r_i2c_ie_val(13) = '1') then
					v_i2c_vec_3 := 8;
				else
					v_i2c_vec_3 := v_i2c_vec_4;
				end if;

				if(r_i2c_ifg_val(2) = '1' AND r_i2c_ie_val(2) = '1') then
					v_i2c_vec_2 := 6;
				else
					v_i2c_vec_2 := v_i2c_vec_3;
				end if;

				if(r_i2c_ifg_val(5) = '1' AND r_i2c_ie_val(5) = '1') then
					v_i2c_vec_1 := 4;
				else
					v_i2c_vec_1 := v_i2c_vec_2;
				end if;

				if(r_i2c_ifg_val(4) = '1' AND r_i2c_ie_val(4) = '1') then
					v_i2c_vec_0 := 2;
				else
					v_i2c_vec_0 := v_i2c_vec_1;
				end if;


			end if;

		end if;

	end process;

	--WRITE to Memory Device 01
	MEM_WRITE_01 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear registers
		if ( i_reset_n = '0') then
			
			r_i2c_ctl_val		(15 downto 8)	<= x"00";
			r_i2c_status_val	(15 downto 8)	<= x"00";
			r_i2c_brw_val		(15 downto 8)	<= x"00";
			--r_i2c_bcount_val	(15 downto 8)	<= x"00";
			--r_i2c_rxbuf_val		(15 downto 8)	<= x"00";
			--r_i2c_txbuf_val		(15 downto 8)	<= x"00";
			r_i2c_oaddr_val		(15 downto 8)	<= x"00";
			r_i2c_taddr_val		(15 downto 8)	<= x"00";
			r_i2c_raddr_val		(15 downto 8)	<= x"00";
			r_i2c_ie_val		(15 downto 8)	<= x"00";
			r_i2c_ifg_val		(15 downto 8)	<= x"00";
			--r_i2c_vec_val		(15 downto 8)	<= x"00";

		-- On rising clock edge
		elsif ( rising_edge(i_clk) ) then

			-- On Write
			if( w_rw_mem_01 = '1' ) then
				--Check the address to write
				case( r_addr_mem_01(29 downto 0) ) is

					--Handle writing I2C Control Register
					when c_I2C_CTL	 						=>	r_i2c_ctl_val(15 downto 8)			<= r_data_in_mem_01;

					--Handle writing I2C  Bit Rate Word Control Register
					when c_I2C_BRW	 						=>	r_i2c_brw_val(15 downto 8)			<= r_data_in_mem_01;

					--Handle writing  I2C Bit Count Threshold Register
					when c_I2C_BCOUNT						=>	--r_i2c_bcount_val(15 downto 8)		<= r_data_in_mem_01;
					
					--Handle writing I2C RX Buff Register
					when c_I2C_RXBUF						=>	--r_i2c_rxbuf_val(15 downto 8)		<= r_data_in_mem_01;

					--Handle writing I2C TX Buff Register
					when c_I2C_TXBUF						=>	--r_i2c_txbuf_val(15 downto 8)		<= r_data_in_mem_01;

					--Handle writing I2C Own Address Register
					when c_I2C_OADDR						=>	r_i2c_oaddr_val(15 downto 8)		<= r_data_in_mem_01;

					--Handle writing I2C Target Address Register
					when c_I2C_TADDR						=>	r_i2c_taddr_val(15 downto 8)		<= r_data_in_mem_01;

					--Handle writing I2C Interrupt Enable Register
					when c_I2C_IE							=>	r_i2c_ie_val(15 downto 8)			<= r_data_in_mem_01;

					--Handle writing I2C Interrupt Flag Register
					when c_I2C_IFG							=>	r_i2c_ifg_val(15 downto 8)			<= r_data_in_mem_01;

					-- Handle defaults
					when others								=>

				end case;

			else

				--Check the address to read
				case( r_addr_mem_01(29 downto 0) ) is

					--Handle reading I2C Control Register
					when c_I2C_CTL	 						=>	r_data_out_mem_01					<= r_i2c_ctl_val(15 downto 8);

					--Handle reading I2C Status Register
					when c_I2C_STATUS						=>	r_data_out_mem_01					<= r_i2c_status_val(15 downto 8);

					--Handle reading I2C Bit Rate Word Control Register
					when c_I2C_BRW	 						=>	r_data_out_mem_01					<= r_i2c_brw_val(15 downto 8);

					--Handle reading I2C Bit Count Threshold Register
					when c_I2C_BCOUNT						=>	--r_data_out_mem_01					<= r_i2c_bcount_val(15 downto 8);

					--Handle reading I2C RX Buff Register
					when c_I2C_RXBUF						=>	--r_data_out_mem_01					<= r_i2c_rxbuf_val(15 downto 8);

					--Handle reading I2C TX Buff Register
					when c_I2C_TXBUF						=>	--r_data_out_mem_01					<= r_i2c_txbuf_val(15 downto 8);

					--Handle reading I2C Own Address Register
					when c_I2C_OADDR						=>	r_data_out_mem_01					<= r_i2c_oaddr_val(15 downto 8);

					--Handle reading I2C Target Address Register
					when c_I2C_TADDR						=>	r_data_out_mem_01					<= r_i2c_taddr_val(15 downto 8);

					--Handle reading I2C Recieve Address Register
					when c_I2C_RADDR						=>	r_data_out_mem_01					<= r_i2c_raddr_val(15 downto 8);

					--Handle reading I2C Interrupt Enable Register
					when c_I2C_IE							=>	r_data_out_mem_01					<= r_i2c_ie_val(15 downto 8);

					--Handle reading I2C Interrupt Flag Register
					when c_I2C_IFG							=>	r_data_out_mem_01					<= r_i2c_ifg_val(15 downto 8);

					--Handle reading I2C Interrupt Vector Register
					when c_I2C_VEC							=>	--r_data_out_mem_01					<= r_i2c_vec_val(15 downto 8);

					-- Handle defaults
					when others								=> 	r_data_out_mem_01					<= x"00";

				end case;

				--Update Status Register with status of I2C State Machine
				r_i2c_status_val(15 downto 8)	<= r_status(15 downto 8);

				--Update Recieved Address Register with State Machines Last Recieved Address
				r_i2c_raddr_val(15 downto 8)		<= r_raddr(15 downto 8);

				--When TX Buf has transfered byte to shift register reset TX Buf Regiser
				-- if(r_i2c_status_val(5) = '1') then
				-- 	r_i2c_txbuf_val(15 downto 8) <= x"00";
				-- end if;

			end if;

		end if;

	end process;

	--WRITE to Memory Device 02
	MEM_WRITE_02 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear registers
		if ( i_reset_n = '0') then
			
			--r_i2c_ctl_val		(23 downto 16)	<= x"00";
			r_i2c_status_val	(23 downto 16)	<= x"00";
			--r_i2c_brw_val		(23 downto 16)	<= x"00";
			--r_i2c_bcount_val	(23 downto 16)	<= x"00";
			--r_i2c_rxbuf_val		(23 downto 16)	<= x"00";
			--r_i2c_txbuf_val		(23 downto 16)	<= x"00";
			--r_i2c_oaddr_val		(23 downto 16)	<= x"00";
			--r_i2c_taddr_val		(23 downto 16)	<= x"00";
			r_i2c_raddr_val		(23 downto 16)	<= x"00";
			r_i2c_ie_val		(23 downto 16)	<= x"00";
			r_i2c_ifg_val		(23 downto 16)	<= x"00";
			--r_i2c_vec_val		(23 downto 16)	<= x"00";

		-- On rising clock edge
		elsif ( rising_edge(i_clk) ) then

			-- On Write
			if( w_rw_mem_02 = '1' ) then
				--Check the address to write
				case( r_addr_mem_02(29 downto 0) ) is

					--Handle writing I2C Control Register
					when c_I2C_CTL	 						=>	-- r_i2c_ctl_val(23 downto 16)			<= r_data_in_mem_02;

					--Handle writing I2C  Bit Rate Word Control Register
					when c_I2C_BRW	 						=>	-- r_i2c_brw_val(23 downto 16)			<= r_data_in_mem_02;

					--Handle writing  I2C Bit Count Threshold Register
					when c_I2C_BCOUNT						=>	--r_i2c_bcount_val(23 downto 16)		<= r_data_in_mem_02;
					
					--Handle writing I2C RX Buff Register
					when c_I2C_RXBUF						=>	--r_i2c_rxbuf_val(23 downto 16)		<= r_data_in_mem_02;

					--Handle writing I2C TX Buff Register
					when c_I2C_TXBUF						=>	--r_i2c_txbuf_val(23 downto 16)		<= r_data_in_mem_02;

					--Handle writing I2C Own Address Register
					when c_I2C_OADDR						=>	--r_i2c_oaddr_val(23 downto 16)		<= r_data_in_mem_02;

					--Handle writing I2C Target Address Register
					when c_I2C_TADDR						=>	--r_i2c_taddr_val(23 downto 16)		<= r_data_in_mem_02;

					--Handle writing I2C Interrupt Enable Register
					when c_I2C_IE							=>	r_i2c_ie_val(23 downto 16)			<= r_data_in_mem_02;

					--Handle writing I2C Interrupt Flag Register
					when c_I2C_IFG							=>	r_i2c_ifg_val(23 downto 16)			<= r_data_in_mem_02;

					-- Handle defaults
					when others								=>

				end case;

			else

				--Check the address to read
				case( r_addr_mem_02(29 downto 0) ) is

					--Handle reading I2C Control Register
					when c_I2C_CTL	 						=>	-- r_data_out_mem_02					<= r_i2c_ctl_val(23 downto 16);

					--Handle reading I2C Status Register
					when c_I2C_STATUS						=>	r_data_out_mem_02					<= r_i2c_status_val(23 downto 16);

					--Handle reading I2C Bit Rate Word Control Register
					when c_I2C_BRW	 						=>	-- r_data_out_mem_02					<= r_i2c_brw_val(23 downto 16);

					--Handle reading I2C Bit Count Threshold Register
					when c_I2C_BCOUNT						=>	--r_data_out_mem_02					<= r_i2c_bcount_val(23 downto 16);

					--Handle reading I2C RX Buff Register
					when c_I2C_RXBUF						=>	--r_data_out_mem_02					<= r_i2c_rxbuf_val(23 downto 16);

					--Handle reading I2C TX Buff Register
					when c_I2C_TXBUF						=>	--r_data_out_mem_02					<= r_i2c_txbuf_val(23 downto 16);

					--Handle reading I2C Own Address Register
					when c_I2C_OADDR						=>	--r_data_out_mem_02					<= r_i2c_oaddr_val(23 downto 16);

					--Handle reading I2C Target Address Register
					when c_I2C_TADDR						=>	--r_data_out_mem_02					<= r_i2c_taddr_val(23 downto 16);

					--Handle reading I2C Recieve Address Register
					when c_I2C_RADDR						=>	r_data_out_mem_02					<= r_i2c_raddr_val(23 downto 16);

					--Handle reading I2C Interrupt Enable Register
					when c_I2C_IE							=>	r_data_out_mem_02					<= r_i2c_ie_val(23 downto 16);

					--Handle reading I2C Interrupt Flag Register
					when c_I2C_IFG							=>	r_data_out_mem_02					<= r_i2c_ifg_val(23 downto 16);

					--Handle reading I2C Interrupt Vector Register
					when c_I2C_VEC							=>	--r_data_out_mem_02					<= r_i2c_vec_val(23 downto 16);

					-- Handle defaults
					when others								=> 	r_data_out_mem_02 					<= x"00";

				end case;

				--Update Status Register with status of I2C State Machine
				r_i2c_status_val(23 downto 16)	<= r_status(23 downto 16);

				--Update Recieved Address Register with State Machines Last Recieved Address
				r_i2c_raddr_val(23 downto 16)		<= r_raddr(23 downto 16);

				--When TX Buf has transfered byte to shift register reset TX Buf Regiser
				-- if(r_i2c_status_val(5) = '1') then
				-- 	r_i2c_txbuf_val(23 downto 16) <= x"00";
				-- end if;

			end if;

		end if;

	end process;

	--WRITE to Memory Device 03
	MEM_WRITE_03 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear registers
		if ( i_reset_n = '0') then
			
			-- r_i2c_ctl_val		(31 downto 24)	<= x"00";
			r_i2c_status_val	(31 downto 24)	<= x"00";
			-- r_i2c_brw_val		(31 downto 24)	<= x"00";
			--r_i2c_bcount_val	(31 downto 24)	<= x"00";
			--r_i2c_rxbuf_val		(31 downto 24)	<= x"00";
			--r_i2c_txbuf_val		(31 downto 24)	<= x"00";
			--r_i2c_oaddr_val		(31 downto 24)	<= x"00";
			--r_i2c_taddr_val		(31 downto 24)	<= x"00";
			r_i2c_raddr_val		(31 downto 24)	<= x"00";
			r_i2c_ie_val		(31 downto 24)	<= x"00";
			r_i2c_ifg_val		(31 downto 24)	<= x"00";
			--r_i2c_vec_val		(31 downto 24)	<= x"00";

		-- On rising clock edge
		elsif ( rising_edge(i_clk) ) then

			-- On Write
			if( w_rw_mem_03 = '1' ) then
				--Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					--Handle writing I2C Control Register
					when c_I2C_CTL	 						=>	-- r_i2c_ctl_val(31 downto 24)			<= r_data_in_mem_03;

					--Handle writing I2C  Bit Rate Word Control Register
					when c_I2C_BRW	 						=>	-- r_i2c_brw_val(31 downto 24)			<= r_data_in_mem_03;

					--Handle writing  I2C Bit Count Threshold Register
					when c_I2C_BCOUNT						=>	--r_i2c_bcount_val(31 downto 24)		<= r_data_in_mem_03;
					
					--Handle writing I2C RX Buff Register
					when c_I2C_RXBUF						=>	--r_i2c_rxbuf_val(31 downto 24)		<= r_data_in_mem_03;

					--Handle writing I2C TX Buff Register
					when c_I2C_TXBUF						=>	--r_i2c_txbuf_val(31 downto 24)		<= r_data_in_mem_03;

					--Handle writing I2C Own Address Register
					when c_I2C_OADDR						=>	--r_i2c_oaddr_val(31 downto 24)		<= r_data_in_mem_03;

					--Handle writing I2C Target Address Register
					when c_I2C_TADDR						=>	--r_i2c_taddr_val(31 downto 24)		<= r_data_in_mem_03;

					--Handle writing I2C Interrupt Enable Register
					when c_I2C_IE							=>	r_i2c_ie_val(31 downto 24)			<= r_data_in_mem_03;

					--Handle writing I2C Interrupt Flag Register
					when c_I2C_IFG							=>	r_i2c_ifg_val(31 downto 24)			<= r_data_in_mem_03;

					-- Handle defaults
					when others								=>

				end case;

			else

				--Check the address to read
				case( r_addr_mem_03(29 downto 0) ) is

					--Handle reading I2C Control Register
					when c_I2C_CTL	 						=>	-- r_data_out_mem_03					<= r_i2c_ctl_val(31 downto 24);

					--Handle reading I2C Status Register
					when c_I2C_STATUS						=>	r_data_out_mem_03					<= r_i2c_status_val(31 downto 24);

					--Handle reading I2C Bit Rate Word Control Register
					when c_I2C_BRW	 						=>	-- r_data_out_mem_03					<= r_i2c_brw_val(31 downto 24);

					--Handle reading I2C Bit Count Threshold Register
					when c_I2C_BCOUNT						=>	--r_data_out_mem_03					<= r_i2c_bcount_val(31 downto 24);

					--Handle reading I2C RX Buff Register
					when c_I2C_RXBUF						=>	--r_data_out_mem_03					<= r_i2c_rxbuf_val(31 downto 24);

					--Handle reading I2C TX Buff Register
					when c_I2C_TXBUF						=>	--r_data_out_mem_03					<= r_i2c_txbuf_val(31 downto 24);

					--Handle reading I2C Own Address Register
					when c_I2C_OADDR						=>	--r_data_out_mem_03					<= r_i2c_oaddr_val(31 downto 24);

					--Handle reading I2C Target Address Register
					when c_I2C_TADDR						=>	--r_data_out_mem_03					<= r_i2c_taddr_val(31 downto 24);

					--Handle reading I2C Recieve Address Register
					when c_I2C_RADDR						=>	r_data_out_mem_03					<= r_i2c_raddr_val(31 downto 24);

					--Handle reading I2C Interrupt Enable Register
					when c_I2C_IE							=>	r_data_out_mem_03					<= r_i2c_ie_val(31 downto 24);

					--Handle reading I2C Interrupt Flag Register
					when c_I2C_IFG							=>	r_data_out_mem_03					<= r_i2c_ifg_val(31 downto 24);

					--Handle reading I2C Interrupt Vector Register
					when c_I2C_VEC							=>	--r_data_out_mem_03					<= r_i2c_vec_val(31 downto 24);

					-- Handle defaults
					when others								=> 	r_data_out_mem_03 <= x"00";

				end case;

				--Update Status Register with status of I2C State Machine
				r_i2c_status_val(31 downto 24)	<= r_status(31 downto 24);

				--Update Recieved Address Register with State Machines Last Recieved Address
				r_i2c_raddr_val(31 downto 24)		<= r_raddr(31 downto 24);

				--When TX Buf has transfered byte to shift register reset TX Buf Regiser
				-- if(r_i2c_status_val(5) = '1') then
				-- 	r_i2c_txbuf_val(31 downto 24) <= x"00";
				-- end if;

			end if;

		end if;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign I2C interrupt request signal when interrupts are enabled and interrupt flags are raised
	o_i2c_irq 		<=	'1' 	when ( (r_i2c_ie_val AND r_i2c_ifg_val) /= x"00000000" ) else
						'0';

	o_scl			<= w_scl;
	o_sda			<= w_sda;
	o_I2C_mode		<= w_i2c_mode;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- 	END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------