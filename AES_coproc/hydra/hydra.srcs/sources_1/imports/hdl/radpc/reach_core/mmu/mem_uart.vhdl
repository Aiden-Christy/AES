----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  MEMORY MANAGEMENT UNIT (MMU)
--	UART MEMORY DEVICE
--
--	CREATED BY CHRIS MAJOR
--  RESILIENT COMPUTING
-- 	07/03/2024
--
--!	@file
--!	@brief A memory map for the new Universal Asynchronous Receive/Transmit (UART) peripheral
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
entity mem_uart is
generic (
    g_CLK_RATE                  : integer           := 100_000_000                             	--! Clock Rate [MHz]
);
port(
	i_clk						: in	std_logic;												--! Clock
	i_reset_n					: in	std_logic;												--! Active Low Reset

	i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
	i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
	i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
	i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
	o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

	i_uart_rx					: in	std_logic;			                                    --! UART RX
	o_uart_tx					: out	std_logic;			                                    --! UART TX
	o_uart_en					: out	std_logic;												--! UART EN
	o_uart_irq					: out	std_logic												--! UART Interrupt Request Signal
);
end mem_uart;
	

----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture mem_uart_arch of mem_uart is

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the UART component
	component uart is
		generic(
			g_CLK_RATE                  : integer 	:= 100_000_000      					-- Clock Rate [MHz]
		);
		port(
			i_clk                           : in        std_logic;                                  -- Clock
			i_reset_n                       : in        std_logic;                                  -- Reset (Active Low)

			i_soft_reset				    : in	    std_logic;									-- Software Reset
			i_clk_div                       : in        std_logic_vector(15 downto 0 );             -- Clock Divider Selector
			i_bit_mode						: in		std_logic;									-- Bit Mode
			i_stop_bits						: in		std_logic;									-- Stop Bits
			i_parity_mode					: in		std_logic_vector(1 downto 0);				-- Parity Mode

			i_tx_en                         : in        std_logic;                                  -- TX Enable

			i_tx_buffer                     : in        std_logic_vector(7 downto 0 );              -- TX Input Data
			o_rx_buffer                     : out       std_logic_vector(7 downto 0 );              -- RX Received Data

			o_parity_bit					: out		std_logic;									-- Parity Bit

			o_tx_idle                  		: out       std_logic;                                  -- TX Idle Flag
			o_tx_busy                       : out       std_logic;                                  -- TX Busy Flag
			o_tx_done                       : out       std_logic;                                  -- TX Done Flag
			o_rx_idle                       : out       std_logic;                                  -- RX Idle Flag
			o_rx_busy                       : out       std_logic;                                  -- RX Busy Flag
			o_rx_done                       : out       std_logic;                                  -- RX Done Flag

			i_rx                            : in        std_logic;                                  -- UART Receive (RX)
			o_tx                            : out       std_logic                                   -- UART Transmit (TX)
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

	constant c_UART_CLK					: std_logic_vector(29 downto 0)		:= "00" & x"0000000";	--! UART Clock Control
	constant c_UART_EN					: std_logic_vector(29 downto 0)		:= "00" & x"0000001";	--! UART Enable
	constant c_UART_RX					: std_logic_vector(29 downto 0)		:= "00" & x"0000002";	--! UART Receive Status
	constant c_UART_TX					: std_logic_vector(29 downto 0)		:= "00" & x"0000003";	--! UART Transmit Buffer
	constant c_UART_IE					: std_logic_vector(29 downto 0)		:= "00" & x"0000004";	--! UART Interrupt Enable
	constant c_UART_IFG					: std_logic_vector(29 downto 0)		:= "00" & x"0000005";	--! UART Interrupt Flags
	constant c_UART_VEC					: std_logic_vector(29 downto 0)		:= "00" & x"0000006";	--! UART Interrupt Flags


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal w_soft_reset					: std_logic;												-- Software Reset

	signal r_rx_status					: std_logic_vector(7 downto 0);								-- RX Status Bits
	signal r_tx_status					: std_logic_vector(7 downto 0);								-- TX Status Bits

	signal r_clk_div					: std_logic_vector(15 downto 0);							-- UART Clock Control Bits
	signal w_bit_mode					: std_logic;												-- Bit Mode
	signal w_stop_bits					: std_logic;												-- Stop Mode
	signal r_parity_mode				: std_logic_vector(1 downto 0);								-- Parity Mode
	
	signal w_parity_bit					: std_logic;												-- Parity Bit

	signal r_rx_ctrl					: std_logic_vector(7 downto 0);								-- RX Control Bits
	signal r_tx_ctrl					: std_logic_vector(7 downto 0);								-- TX Control Bits

	signal r_uart_en					: std_logic;												-- UART Enable

	signal r_tx_buffer                  : std_logic_vector(7 downto 0 );              				-- TX Buffer
	signal r_rx_buffer                  : std_logic_vector(7 downto 0 );              				-- RX Buffer

	signal w_tx_en                      : std_logic;                                  				-- TX Enable

	signal w_tx_idle                    : std_logic;                                  				-- TX Idle
	signal w_tx_busy                    : std_logic;                                  				-- TX Busy
	signal w_tx_done                    : std_logic;                                  				-- TX Done

	signal w_rx_idle                    : std_logic;                                  				-- RX Idle
	signal w_rx_busy                    : std_logic;                                  				-- RX Busy
	signal w_rx_done                    : std_logic;                                  				-- RX Done


	signal r_uart_ie_val				: std_logic_vector(31 downto 0);							-- UART Interrupt Enable Register
	signal r_uart_ifg_val				: std_logic_vector(31 downto 0);							-- UART Interrupt Flag Register
	signal r_uart_vec_val				: std_logic_vector(31 downto 0);							-- UART Interrupt Vector Register

	signal r_uart_ifg_write				: std_logic_vector(31 downto 0);							-- UART Interrupt Flag Write Value
	signal r_uart_ifg_rw				: std_logic;												-- UART Interrupt Flag Read/Write Enable


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
	-- COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate UART 00
	UART_00 : uart
		generic map(
			g_CLK_RATE                      => g_CLK_RATE
		)
		port map(
			i_clk                           => i_clk,
			i_reset_n                       => i_reset_n,

			i_soft_reset				    => w_soft_reset,
			i_clk_div                      	=> r_clk_div,
			i_bit_mode						=> w_bit_mode,
			i_stop_bits						=> w_stop_bits,
			i_parity_mode					=> r_parity_mode,

			i_tx_en                         => w_tx_en,

			i_tx_buffer                     => r_tx_buffer,
			o_rx_buffer                     => r_rx_buffer,

			o_parity_bit					=> w_parity_bit,

			o_tx_idle                  		=> w_tx_idle,
			o_tx_busy                       => w_tx_busy,
			o_tx_done                       => w_tx_done,
			o_rx_idle                       => w_rx_idle,
			o_rx_busy                       => w_rx_busy,
			o_rx_done                       => w_rx_done,

			i_rx                            => i_uart_rx,
			o_tx                            => o_uart_tx 
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
	begin

		-- On reset ...
		if( i_reset_n = '0' ) then

			-- Reset control signals
			r_clk_div(7 downto 0)				<= ( others => '0' );
			--r_uart_en							<= '0';

			-- Reset interrupt signals
			r_uart_ie_val(7 downto 0)			<= ( others => '0' );
			r_uart_ifg_val(7 downto 0)			<= ( others => '0' );


		-- On rising clock edge ...
		elsif( rising_edge( i_clk )) then

			-- WRITE Condition
			if( w_rw_mem_00 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_00(29 downto 0) ) is

					-- Write UART Clock Control
					when c_UART_CLK							=>	r_clk_div(7 downto 0)			<= r_data_in_mem_00;

					-- Write UART Enable
					when c_UART_EN							=> 	r_uart_en						<= r_data_in_mem_00(0);

					-- Write UART Receive (Status)
					when c_UART_RX							=> 	-- (No Write Access)

					-- Write UART Transmit (Status)
					when c_UART_TX							=> 	-- (No Write Access)

					-- Write UART Interrupt Enable Register
					when c_UART_IE							=> 	r_uart_ie_val(7 downto 0)		<= r_data_in_mem_00;

					-- Write UART Interrupt Flags
					when c_UART_IFG							=> 	if( r_uart_ifg_rw = '1' ) then
																	r_uart_ifg_val(7 downto 0)		<= r_uart_ifg_write(7 downto 0);

																else
																	r_uart_ifg_val(7 downto 0)		<= r_data_in_mem_00;

																end if;

					-- Write UART Interrupt Vector
					when c_UART_VEC							=> 	-- (No Write Access)

					-- Handle defaults
					when others								=> 	-- (Do nothing)

				end case;

			-- READ Condition
			else

				-- Check the address to read
				case( r_addr_mem_00(29 downto 0) ) is

					-- Read UART Clock Control
					when c_UART_CLK							=> 	r_data_out_mem_00 	<= r_clk_div(7 downto 0);
					
					-- Write UART Enable
					when c_UART_EN							=> 	r_data_out_mem_00 	<= "0000000" & r_uart_en;

					-- Read UART Receive (Status)
					when c_UART_RX							=> 	r_data_out_mem_00 	<= r_rx_status;

					-- Read UART Transmit (Status)
					when c_UART_TX							=> 	r_data_out_mem_00 	<= r_tx_status;

					-- Read UART Interrupt Enable
					when c_UART_IE							=> 	r_data_out_mem_00	<= r_uart_ie_val(7 downto 0);

					-- Read UART Interrupt Flags
					when c_UART_IFG							=> 	r_data_out_mem_00	<= r_uart_ifg_val(7 downto 0);

					-- Read UART Interrupt Vector
					when c_UART_VEC							=> 	r_data_out_mem_00 	<= r_uart_vec_val(7 downto 0);

					-- Handle defaults
					when others								=> 	r_data_out_mem_00 	<= x"00";

				end case;

				if( r_uart_ifg_rw = '1' ) then
					r_uart_ifg_val(7 downto 0)		<= r_uart_ifg_write(7 downto 0);

				end if;

			end if;

		end if;

	end process;


	-- WRITE to Memory Device 01
	MEM_WRITE_01 : process( i_clk, i_reset_n )
	begin

		-- On reset ...
		if( i_reset_n = '0' ) then

			-- Reset control signals
			r_clk_div(15 downto 8)				<= ( others => '0' );
			r_rx_ctrl							<= ( others => '0' );
			r_tx_ctrl							<= ( others => '0' );

			-- Reset interrupt signals
			r_uart_ie_val(15 downto 8)			<= ( others => '0' );
			r_uart_ifg_val(15 downto 8)			<= ( others => '0' );


		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_01 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_01(29 downto 0) ) is

					-- Write UART Clock Control
					when c_UART_CLK							=> 	r_clk_div(15 downto 8)			<= r_data_in_mem_01;

					-- Write UART Receive (Control)
					when c_UART_RX							=>	r_rx_ctrl						<= r_data_in_mem_01;

					-- Write UART Transmit (Control)
					when c_UART_TX							=>	r_tx_ctrl						<= r_data_in_mem_01;

					-- Write UART Interrupt Enable
					when c_UART_IE							=> 	r_uart_ie_val(15 downto 8)		<= r_data_in_mem_01;

					-- Write UART Interrupt FLags
					when c_UART_IFG							=> 	r_uart_ifg_val(15 downto 8)		<= r_data_in_mem_01;

					-- Write UART Interrupt Vector
					when c_UART_VEC							=> 	-- (No Write Access)

					-- Handle defaults
					when others								=> 	-- (Do nothing)

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_01(29 downto 0) ) is

					-- Read UART Clock Control
					when c_UART_CLK							=> 	r_data_out_mem_01 	<= r_clk_div(15 downto 8);

					-- Read UART Receive (Control)
					when c_UART_RX							=> 	r_data_out_mem_01 	<= r_rx_ctrl;

					-- Read UART Transmit (Control)
					when c_UART_TX							=> 	r_data_out_mem_01 	<= r_tx_ctrl;

					-- Read UART Interrupt Enable
					when c_UART_IE							=> 	r_data_out_mem_01	<= r_uart_ie_val(15 downto 8);

					-- Write UART Interrupt FLags
					when c_UART_IFG							=> 	r_data_out_mem_01	<= r_uart_ifg_val(15 downto 8);

					-- Read UART Interrupt Vector
					when c_UART_VEC							=> 	r_data_out_mem_01 	<= r_uart_vec_val(15 downto 8);

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

			-- Reset control signals
			w_soft_reset						<= '0';		
			w_tx_en								<= '0';	
			r_tx_buffer							<= ( others => '0' );

			-- Reset interrupt signals
			r_uart_ie_val(23 downto 16)			<= ( others => '0' );
			r_uart_ifg_val(23 downto 16)		<= ( others => '0' );


		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_02 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_02(29 downto 0) ) is

					-- Write UART Clock Control
					when c_UART_CLK							=> 	w_soft_reset					<= r_data_in_mem_02(0);
																w_tx_en							<= '0';
					-- Write UART Receive (Buffer)
					when c_UART_RX							=> 	-- (No Write Access)
																w_tx_en							<= '0';

					-- Write UART Transmit (Buffer)
					when c_UART_TX							=> 	r_tx_buffer						<= r_data_in_mem_02;
																w_tx_en							<= '1';

					-- Write UART Interrupt Enable
					when c_UART_IE							=> 	r_uart_ie_val(23 downto 16)		<= r_data_in_mem_02;
																w_tx_en							<= '0';

					-- Write UART Interrupt FLags
					when c_UART_IFG							=> 	r_uart_ifg_val(23 downto 16)	<= r_data_in_mem_02;
																w_tx_en							<= '0';

					-- Write UART Interrupt Vector
					when c_UART_VEC							=> 	-- (No Write Access)
																w_tx_en							<= '0';

					-- Handle defaults
					when others								=> 	-- (Do nothing)
																w_tx_en							<= '0';

				end case;

			else

				-- Check the address to read
				case( r_addr_mem_02(29 downto 0) ) is

					-- Read UART Clock Control ()
					when c_UART_CLK							=> 	r_data_out_mem_02 	<= "0000000" & w_soft_reset;

					-- Read UART Receive (Buffer)
					when c_UART_RX							=> 	r_data_out_mem_02 	<= r_rx_buffer;

					-- Read UART Transmit (Buffer)
					when c_UART_TX							=> 	r_data_out_mem_02 	<= r_tx_buffer;

					-- Read UART Interrupt Enable
					when c_UART_IE							=> 	r_data_out_mem_02	<= r_uart_ie_val(23 downto 16);

					-- Write UART Interrupt FLags
					when c_UART_IFG							=> 	r_data_out_mem_02	<= r_uart_ifg_val(23 downto 16);

					-- Read UART Interrupt Vector
					when c_UART_VEC							=> 	r_data_out_mem_02 	<= r_uart_vec_val(23 downto 16);

					-- Handle defaults
					when others								=> 	r_data_out_mem_02 	<= x"00";

				end case;

				w_tx_en							<= '0';

			end if;

		end if;

	end process;	


	-- WRITE to Memory Device 03
	MEM_WRITE_03 : process( i_clk, i_reset_n )
	begin

		-- On reset ...
		if( i_reset_n = '0' ) then

			w_stop_bits		<= '0';
			w_bit_mode		<= '0';
			r_parity_mode	<= "00";

			-- Reset interrupt signals
			r_uart_ie_val(31 downto 24)			<= ( others => '0' );
			r_uart_ifg_val(31 downto 24)		<= ( others => '0' );


		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			-- On WRITE ...
			if( w_rw_mem_03 = '1' ) then

				-- Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					-- Write UART Clock Control ()
					when c_UART_CLK							=> 	r_parity_mode(1)				<= r_data_in_mem_03(3);
																r_parity_mode(0)				<= r_data_in_mem_03(2);
																w_stop_bits						<= r_data_in_mem_03(1);
																w_bit_mode						<= r_data_in_mem_03(0);

					-- Write UART Receive ()
					when c_UART_RX							=> 	-- (Empty Address)

					-- Write UART Transmit ()
					when c_UART_TX							=> 	-- (Empty Address)

					-- Write UART Interrupt Enable
					when c_UART_IE							=> 	r_uart_ie_val(31 downto 24)		<= r_data_in_mem_03;

					-- Write UART Interrupt FLags
					when c_UART_IFG							=> 	r_uart_ifg_val(31 downto 24)	<= r_data_in_mem_03;

					-- Write UART Interrupt Vector
					when c_UART_VEC							=> 	-- (No Write Access)

					-- Handle defaults
					when others								=> 	-- (Do nothing)

				end case;

			else

				-- Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					-- Read UART Clock Control ()
					when c_UART_CLK							=> 	r_data_out_mem_03 	<= "0000" & r_parity_mode & w_stop_bits & w_bit_mode;

					-- Read UART Receive ()
					when c_UART_RX							=> 	r_data_out_mem_03 	<= "0000000" & w_parity_bit;

					-- Read UART Transmit ()
					when c_UART_TX							=> 	r_data_out_mem_03 	<= x"00";

					-- Read UART Interrupt Enable
					when c_UART_IE							=> 	r_data_out_mem_03	<= r_uart_ie_val(31 downto 24);

					-- Write UART Interrupt FLags
					when c_UART_IFG							=> 	r_data_out_mem_03	<= r_uart_ifg_val(31 downto 24);

					-- Read UART Interrupt Vector
					when c_UART_VEC							=> 	r_data_out_mem_03 	<= r_uart_vec_val(31 downto 24);

					-- Handle defaults
					when others								=> 	r_data_out_mem_03 	<= x"00";

				end case;

			end if;

		end if;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- INTERRUPT VECTOR HANDLING
	------------------------------------------------------------------------------------------------------------------------------------

	-- n/a


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign UART Enable to component output port
	o_uart_en		<= r_uart_en;

	-- Assign TX Control Register to UART TX Enable
	--w_tx_en			<= 	r_tx_ctrl(0);

	-- Assign UART RX flags to the RX Status Register 
	r_rx_status		<= 	"00000" & w_rx_done & w_rx_busy & w_rx_idle;

	-- Assign UART TX flags to the TX Status Register 
	r_tx_status		<= 	"00000" & w_tx_done & w_tx_busy & w_tx_idle;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------