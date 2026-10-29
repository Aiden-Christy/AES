----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  MEMORY MANAGEMENT UNIT (MMU)
--	I2C MEMORY DEVICE
--
--	CREATED BY TRISTAN RUNNING CRANE
--  RESILIENT COMPUTING
-- 	07/22/2024
--
--!	@file
--!	@brief A memory map for SPI memory device.
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
entity mem_spi is
generic (
    g_CLK_RATE                  : integer           := 100_000_000                             	-- Clock Rate [MHz]
);
port(
	i_clk						: in	std_logic;												-- Clock
	i_reset_n					: in	std_logic;												-- Reset (Active Low)

	i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
	i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
	i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
	i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
	o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

	i_miso						: in	std_logic;												-- SPI Input Master In Slave Out (MISO)
	o_miso						: out	std_logic;												-- SPI Output Master In Slave Out (MISO)
	i_mosi						: in	std_logic;												-- SPI Input Master Out Slave In (MOSI)
	o_mosi						: out	std_logic;												-- SPI Output Master Out Slave In (MOSI)
	i_sclk						: in	std_logic;												-- SPI Incoming Serial Clock (SCLK)
	o_sclk						: out	std_logic;												-- SPI Outgoing Serial Clock (SCLK)
	i_cs						: in	std_logic;												-- SPI Incoming Serial Data (CS)
	o_cs						: out	std_logic;												-- SPI Outgoing Serial Data (CS)

	o_spi_mode					: out	std_logic;												-- SPI Mode

	o_spi_irq					: out	std_logic												-- SPI Interrupt Request Signal
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture mem_spi_arch of mem_spi is

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the SPI component
	component spi is
	generic(
		g_CLK_RATE                 	: integer						:= 100_000_000      					--! Clock Rate [MHz]
	);
	port(
		i_clk						: in	std_logic;														--! SPI Clock
		i_reset_n					: in	std_logic;														--! Active Low Reset

		-- SPI CLK CTL Register
		i_clk_div                   : in    std_logic_vector(15 downto 0 );             					--! Clock Divider Selector
		
		-- SPI CTL Register inputs
		i_soft_reset				: in	std_logic;														--! Software Reset
		i_mode					    : in	std_logic;														--! Main Mode (Master/Slave)
		i_bit_mode					: in	std_logic;														--! Bit Mode
		i_msb_mode					: in	std_logic;														--! MSB/LSB Mode
		i_cpol						: in	std_logic;														--! Clock Polarity
		i_cspol                     : in    std_logic;                                                      --! Chip Select Polarity
		i_cpha						: in	std_logic;														--! Clock Phase
		i_pin_mode                  : in    std_logic;                                                      --! 3/4 Pin Mode
		-- SPI packet Size Register
		i_pkt_size               	: in    std_logic_vector(15 downto 0);                                    --! Packet Size Register for 4 pin mode
		-- Transmit trigger from mem_spi
		i_tx_write				    : in 	std_logic;														--! SPI ready-to-transmit(This goes High when something gets loaded into the TX buffer from the memory bus)

		-- Buffers
		o_rx_buf					: out	std_logic_vector(7 downto 0);									--! SPI Receive (RX) Buffer Value
		i_tx_buf					: in	std_logic_vector(7 downto 0);									--! SPI Transmit (TX) TX Buffer


		o_mode						: out	std_logic;														--! Main Mode (Master/Slave) Flag 
		o_spi_reset					: out	std_logic;														--! SPI Reset Flag
		o_busy                  	: out	std_logic;                                  					--! SPI Busy Flag
		o_done						: out	std_logic;														--! SPI Done Flag

		i_miso						: in	std_logic;														--! SPI Input Master In Slave Out (MISO)
		o_miso						: out	std_logic;														--! SPI Output Master In Slave Out (MISO)
		i_mosi						: in	std_logic;														--! SPI Input Master Out Slave In (MOSI)
		o_mosi						: out	std_logic;														--! SPI Output Master Out Slave In (MOSI)
		i_sclk						: in	std_logic;														--! SPI Incoming Serial Clock (SCLK)
		o_sclk						: out	std_logic;														--! SPI Outgoing Serial Clock (SCLK)
		i_cs						: in	std_logic;														--! SPI Incoming Serial Data (CS)
		o_cs						: out	std_logic														--! SPI Outgoing Serial Data (CS)
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

	constant c_ADDR_SPACE				: integer							
										:= 20;

	constant c_SPI_CLK					: std_logic_vector(29 downto 0)		:= "00" & x"0000000";	--! SPI Clock Control
	constant c_SPI_CTRL					: std_logic_vector(29 downto 0)		:= "00" & x"0000001";	--! SPI Control Signals
	constant c_SPI_BUFF					: std_logic_vector(29 downto 0)		:= "00" & x"0000002";	--! SPI TX/RX Buffers
	constant c_SPI_STAT					: std_logic_vector(29 downto 0)		:= "00" & x"0000003";	--! SPI Status
	constant c_SPI_PKT 					: std_logic_vector(29 downto 0) 	:= "00" & x"0000004"; 	--! SPI Packet Size Register
	
	-- constant c_SPI_IE				: std_logic_vector(29 downto 0)		:= "00" & x"0000005";	--! SPI Interrupt Enable Address
	-- constant c_SPI_IFG				: std_logic_vector(29 downto 0)		:= "00" & x"0000006";	--! SPI Interrupt Flag Address
	-- constant c_SPI_VEC				: std_logic_vector(29 downto 0)		:= "00" & x"0000007";	--! SPI Interrupt Vector Address


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_clk_ctrl					: std_logic_vector(15 downto 0);							--! SPI Clock Control Bits

	signal w_soft_reset					: std_logic;												--! SPI Software Reset
	signal w_main_mode					: std_logic;												--! SPI Main Mode (Master/Slave)
	signal w_bit_mode					: std_logic;												--! SPI Bit Mode
	signal w_msb_mode					: std_logic;												--! SPI MSB/LSB Mode

	signal w_mode						: std_logic;												--! SPI Main Mode (Master/Slave) Flag 
	signal w_spi_reset					: std_logic;												--! SPI Reset Flag
	signal w_busy                  		: std_logic;                                				--! SPI Busy Flag
	signal w_done						: std_logic;												--! SPI Done Flag

	signal r_rx_buf						: std_logic_vector(7 downto 0);								--! SPI Receive (RX) Buffer Value
	signal r_tx_buf						: std_logic_vector(7 downto 0);								--! SPI Transmit (TX) TX Buffer

	signal w_tx_en						: std_logic;												--! SPI Transmit (TX) Enable

	signal r_spi_ctrl					: std_logic_vector(7 downto 0);								--! SPI Control
	signal r_spi_status					: std_logic_vector(7 downto 0);								--! SPI Status
	signal r_pkt_size 					: std_logic_vector(15 downto 0);							--! SPI Packet Size(4 pin)

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

	-- -- SPI Registers (For Future Use)
	signal w_cpol						: std_logic;			--! SPI Clock Polarity
	signal w_cspol						: std_logic;			--! SPI Chip Select Polarity
	signal w_cpha						: std_logic;			--! SPI Clock Phase
	signal w_pin_mode					: std_logic;
	signal w_o_spi_mode 				: std_logic;
	
	
	-- --signal r_spi_ctl_val					: std_logic_vector(31 downto 0)			:= x"00000001";		--! SPI Control Register

	-- signal r_spi_ctl_val						: std_logic_vector(15 downto 0)			:= x"0001";			--! SPI Control Register

	-- --signal r_spi_brw_val					: std_logic_vector(31 downto 0)			:= x"00000000";		--! SPI Bit Rate Control Register

	-- signal r_spi_brw_val						: std_logic_vector(15 downto 0)			:= x"0000";			--! SPI Bit Rate Control Register
	-- signal r_spi_stat_val					: std_logic_vector(31 downto 0)			:= x"00000000";		--! SPI Status Register
	-- signal r_spi_rxbuf_val					: std_logic_vector(31 downto 0)			:= x"00000000";		--! SPI RX Buffer Register

	-- --signal r_spi_txbuf_val					: std_logic_vector(31 downto 0)			:= x"00000000";		--! SPI TX Buffer Register

	-- signal r_spi_txbuf_val					: std_logic_vector(7 downto 0)			:= x"00";			--! SPI TX Buffer Register
	-- signal r_spi_ie_val						: std_logic_vector(31 downto 0)			:= x"00000000";		--! SPI Interrupt Enable Register
	-- signal r_spi_ifg_val						: std_logic_vector(31 downto 0)			:= x"00000000";		--! SPI Interrupt Flag Register
	-- signal r_spi_vec_val						: std_logic_vector(31 downto 0)			:= x"00000000";		--! SPI Interrupt Vector Register

	-- signal r_clk_src							: std_logic								:= '0';
	-- signal r_status							: std_logic_vector(31 downto 0)			:= x"00000000";
	-- signal r_rxbuf							: std_logic_vector(31 downto 0)			:= x"00000000";

	-- signal r_clk								: std_logic;
	-- signal spi_clk							: std_logic;
	-- signal w_spi_write						: std_logic := '0';
	signal w_o_spi_miso : std_logic;
	

begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------
	SPI_00	: spi
	generic map(
		g_CLK_RATE                 			=> g_CLK_RATE
	)
	port map(
		i_clk								=> i_clk,
		i_reset_n							=> i_reset_n,
		-- SPI CLK CTL Register
		i_clk_div                   		=> r_clk_ctrl,														--! SPI Clock Divider Selector
		-- SPI CTL Register inputs
		i_soft_reset						=> w_soft_reset,														--! Software Reset
		i_mode					    		=> w_mode,														--! Main Mode (Master/Slave)
		i_bit_mode							=> w_bit_mode,														--! Bit Mode
		i_msb_mode							=> w_msb_mode,														--! MSB/LSB Mode
		i_cpol								=> w_cpol,															--! Clock Polarity
		i_cspol                    			=> w_cspol,															--! Chip Select Polarity
		i_cpha								=> w_cpha,															--! Clock Phase
		i_pin_mode                  		=> w_pin_mode,														--! 3/4 Pin Mode
		-- SPI packet Size Register
		i_pkt_size               			=>r_pkt_size,                                    				--! Packet Size Register for 4 pin mode
		-- Transmit trigger from mem_spi
		i_tx_write				    		=> w_tx_en,														--! SPI ready-to-transmit(This goes High when something gets loaded into the TX buffer from the memory bus)

		-- Buffers
		o_rx_buf							=> r_rx_buf,
		i_tx_buf							=> r_tx_buf,
		-- SPI Status Register outputs
		o_mode								=> w_o_spi_mode,
		o_spi_reset							=> w_spi_reset,
		o_busy                  			=> w_busy,
		o_done								=> w_done,

		i_miso								=> i_miso,
		o_miso								=> o_miso,
		i_mosi								=> i_mosi,
		o_mosi								=> o_mosi,
		i_sclk								=> i_sclk,
		o_sclk								=> o_sclk,
		i_cs								=> i_cs,
		o_cs								=> o_cs
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
	begin

		-- On reset, clear registers
		if ( i_reset_n = '0') then

			-- Reset all signals and signals
			r_clk_ctrl(7 downto 0)		<= ( others => '0' );
			r_spi_ctrl					<= ( others => '0' );
			r_tx_buf					<= ( others => '0' );
			r_pkt_size(7 downto 0)		<= ( others => '0' );
			-- w_soft_reset				<= '0';
			-- w_main_mode					<= '0';
			-- w_bit_mode					<= '0';
			-- w_msb_mode					<= '0';


		-- On rising clock edge
		elsif( rising_edge(i_clk) ) then

			w_tx_en <= '0';
			-- On Write
			if( w_rw_mem_00 = '1' ) then

				--Check the address to write
				case( r_addr_mem_00(29 downto 0) ) is

					-- Write SPI Clock Control (Lower Byte)
					when c_SPI_CLK							=>	r_clk_ctrl(7 downto 0)				<= r_data_in_mem_00;

					-- Write SPI Control Signals
					when c_SPI_CTRL							=> 	r_spi_ctrl							<= r_data_in_mem_00;


					-- Write SPI TX Buffer
					when c_SPI_BUFF							=>	r_tx_buf							<= r_data_in_mem_00;
																w_tx_en <= '1';						-- If we write to the Tx buffer, start SPI transmit

					-- No Write Access to SPI Status
					when c_SPI_STAT							=>	-- (No Write Access)

					when c_SPI_PKT							=> 	r_pkt_size(7 downto 0)				<= r_data_in_mem_00 ; -- Set Packet Size Register
					-- (Default Case)
					when others								=> 	-- (Do nothing) 

				end case;


			else

				--Check the address to read
				case( r_addr_mem_00(29 downto 0) ) is

					-- Read SPI Clock Control (Lower Byte)
					when c_SPI_CLK							=>	r_data_out_mem_00					<= r_clk_ctrl(7 downto 0);

					-- Read SPI Control Signals
					when c_SPI_CTRL							=> 	r_data_out_mem_00					<= r_spi_ctrl; --"0000" & w_msb_mode & w_bit_mode & w_main_mode & w_soft_reset;

					-- Read SPI TX Buffer
					when c_SPI_BUFF							=>	r_data_out_mem_00					<= r_tx_buf;

					-- Read SPI Status
					when c_SPI_STAT							=>	r_data_out_mem_00					<= r_spi_status; --"0000" & w_done & w_busy & w_mode & w_spi_reset;
					
					when c_SPI_PKT							=> 	r_data_out_mem_00					<= r_pkt_size(7 downto 0); -- Read Packet Size Register
					-- (Default Case)
					when others								=> 	r_data_out_mem_00 					<= x"00";

				end case;
				
				-- Pulled from Tristan's code, this allows us to be rid of the 'SPI Enable' problems
				-- if(r_spi_status(2)= '1') then	-- Reset the SPI Transmit Enable Flag after one clock cycle if we are busy (i.e. the SPI is transmitting)
				-- 	w_tx_en <= '0';

				-- end if;

			end if;
		end if;

	end process;


	--WRITE to Memory Device 01
	MEM_WRITE_01 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear registers
		if ( i_reset_n = '0') then

			-- Reset all registers and signals
			r_clk_ctrl(15 downto 8)			<= ( others => '0' );
			r_pkt_size(15 downto 8)			<= ( others => '0' );
			--
			--w_tx_en							<= '0';


		-- On rising clock edge
		elsif( rising_edge(i_clk) ) then

			-- On Write
			if( w_rw_mem_01 = '1' ) then

				--Check the address to write
				case( r_addr_mem_01(29 downto 0) ) is

					-- Write SPI Clock Control (Upper Byte)
					when c_SPI_CLK							=>	r_clk_ctrl(15 downto 8)				<= r_data_in_mem_01;

					-- Write SPI Control Signals
					when c_SPI_CTRL							=> 	-- r_spi_ctrl						<= r_data_in_mem_01;

					-- No Write Access to SPI RX Buffer
					when c_SPI_BUFF							=>	-- (No Write Access)

					-- (Empty Address)
					when c_SPI_STAT							=>	-- (Do nothing) 
					
					when c_SPI_PKT							=> 	r_pkt_size(15 downto 8)				<= r_data_in_mem_01 ; -- Set Packet Size Register
					-- (Default Case)
					when others								=> 	-- (Do nothing)

				end case;

			else

				--Check the address to read
				case( r_addr_mem_01(29 downto 0) ) is

					-- Read SPI Clock Control (Upper Byte)
					when c_SPI_CLK							=>	r_data_out_mem_01					<= r_clk_ctrl(15 downto 8);

					-- Read SPI Control Signals
					when c_SPI_CTRL							=> 	--r_data_out_mem_01					<= "0000000" & w_tx_en;

					-- Read SPI RX Buffer
					when c_SPI_BUFF							=>	r_data_out_mem_01					<= r_rx_buf;

					-- (Empty Address)
					when c_SPI_STAT							=>	r_data_out_mem_01 					<= x"00";

					when c_SPI_PKT							=> 	r_data_out_mem_01					<= r_pkt_size(15 downto 8); -- Read Packet Size Register

					-- (Default Case)
					when others								=>	r_data_out_mem_01 					<= x"00";

				end case;

			end if;

		end if;

	end process;


	--WRITE to Memory Device 02
	MEM_WRITE_02 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear registers
		if ( i_reset_n = '0') then

			-- (Do Nothing)

		-- On rising clock edge
		elsif( rising_edge(i_clk) ) then

			-- On Write
			if( w_rw_mem_02 = '1' ) then

				--Check the address to write
				case( r_addr_mem_02(29 downto 0) ) is

					-- (Empty Address)
					when c_SPI_CLK							=>	-- (Do nothing)

					-- (Empty Address)
					when c_SPI_CTRL							=> 	-- (Do nothing)

					-- (Empty Address)
					when c_SPI_BUFF							=> 	-- (Do nothing)

					-- (Empty Address)
					when c_SPI_STAT							=>	-- (Do nothing) 

					-- (Default Case)
					when others								=> 	-- (Do nothing)

				end case;

			else

				--Check the address to read
				case( r_addr_mem_02(29 downto 0) ) is

					-- (Empty Address)
					when c_SPI_CLK							=>	r_data_out_mem_02 					<= x"00";

					-- (Empty Address)
					when c_SPI_CTRL							=> 	r_data_out_mem_02 					<= x"00";

					-- (Empty Address)
					when c_SPI_BUFF							=> 	r_data_out_mem_02 					<= x"00";

					-- (Empty Address)
					when c_SPI_STAT							=>	r_data_out_mem_02 					<= x"00";

					-- (Default Case)
					when others								=>	r_data_out_mem_02 					<= x"00";

				end case;

			end if;

		end if;

	end process;

	--WRITE to Memory Device 03
	MEM_WRITE_03 : process( i_clk, i_reset_n )
	begin

		-- On reset, clear registers
		if ( i_reset_n = '0') then

			-- (Do Nothing)

		-- On rising clock edge
		elsif( rising_edge(i_clk) ) then
		
			-- On Write
			if( w_rw_mem_03 = '1' ) then
		
				--Check the address to write
				case( r_addr_mem_03(29 downto 0) ) is

					-- (Empty Address)
					when c_SPI_CLK							=>	-- (Do nothing)

					-- (Empty Address)
					when c_SPI_CTRL							=> 	-- (Do nothing)
					
					--(Empty Address)
					when c_SPI_BUFF							=> 	-- (Do nothing)

					-- (Empty Address)
					when c_SPI_STAT							=>	-- (Do nothing) 

					-- (Default Case)
					when others								=> 	-- (Do nothing)

				end case;

			else

				--Check the address to read
				case( r_addr_mem_03(29 downto 0) ) is

					-- (Empty Address)
					when c_SPI_CLK							=>	r_data_out_mem_03 					<= x"00";

					-- (Empty Address)
					when c_SPI_CTRL							=> 	r_data_out_mem_03 					<= x"00";

					--(Empty Address)
					when c_SPI_BUFF							=> 	r_data_out_mem_03 					<= x"00";

					-- (Empty Address)
					when c_SPI_STAT							=>	r_data_out_mem_03 					<= x"00";

					-- (Default Case)
					when others								=>	r_data_out_mem_03 					<= x"00";

				end case;

			end if;

		end if;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- -- Assign SPI mode
	o_spi_mode		<= 	w_o_spi_mode;

	-- Assign SPI Control register
	w_pin_mode		<= r_spi_ctrl(7);
	w_cpha			<= r_spi_ctrl(6);	
	w_cpol			<= r_spi_ctrl(5);
	w_cspol			<= r_spi_ctrl(4);
	w_msb_mode		<= r_spi_ctrl(3);
	w_bit_mode		<= r_spi_ctrl(2);
	w_mode			<= r_spi_ctrl(1);
	w_soft_reset	<= r_spi_ctrl(0);

	-- Assign SPI status register
	r_spi_status 	<= 	"0000" & w_done & w_busy & w_o_spi_mode & w_spi_reset;


	-- Temporarily disable interrupts
	o_spi_irq 		<=	--'1' 		when (r_spi_ie_val AND r_spi_ifg_val) /= x"00000000" 				else
						'0';

	
end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- 	END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------