--------------------------------------------------------------------------------------------------------------------------------
--	
--	RADPC
--	UART PERIPHERAL	
--
--	ENGINEER:		CHRIS MAJOR
--	COMPANY:		RESILIENT COMPUTING
--	DATE:			06/03/2026
--
--	A FULL-DUPLEX UNIVERSAL ASYNCHRONOUS RECEIVE/TRANSMIT (UART) PERIPHERAL WITH THE FOLLOWING CAPABILITIES
--		- BAUD RATE SUPPORT
--		- 7/8 DATA BIT MODES
--		- 1/2 STOP BIT MODES
--	
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
--	LIBRARIES
--------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	--! IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;

	--! IEEE Numeric Standard Library
	use IEEE.NUMERIC_STD.ALL;


--------------------------------------------------------------------------------------------------------------------------------
--	ENTITY
--------------------------------------------------------------------------------------------------------------------------------
entity uart is
	generic(
		g_CLK_RATE                      : integer                           := 100_000_000      -- Clock Rate [MHz]
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
end entity;

--------------------------------------------------------------------------------------------------------------------------------
--	ARCHITECTURE
--------------------------------------------------------------------------------------------------------------------------------
architecture uart_arch of uart is

    ----------------------------------------------------------------------------------------------------------------------------
    --  COMPONENT DECLARATIONS
    ----------------------------------------------------------------------------------------------------------------------------

	-- Declare the UART Transmit (TX) Component
	component uart_tx is
	generic (
		g_CLK_RATE              : integer 	:= 100_000_000     				-- Clock Rate [MHz]
	);
	port (
		i_clk       			: in  	std_logic;							-- Clock
		i_reset_n				: in	std_logic;							-- Reset (Active Low)

		i_soft_reset	 		: in	std_logic;							-- Software Reset
		i_clk_div               : in 	std_logic_vector(15 downto 0 );     -- Clock Division Value
		i_bit_mode				: in	std_logic;							-- Bit Mode
		i_stop_bits				: in	std_logic;							-- Stop Bits
		i_parity_mode			: in	std_logic_vector(1 downto 0);		-- Parity Mode

		i_en     				: in  	std_logic;							-- Enable
		i_buffer   				: in  	std_logic_vector(7 downto 0);		-- Buffer

		o_tx 					: out 	std_logic;							-- Transmit (TX) Pin
		o_idle					: out	std_logic;							-- Idle Flag
		o_busy 					: out 	std_logic;							-- Busy Flag
		o_done   				: out 	std_logic							-- Done Flag
	);
	end component;


	-- Declare the UART Receive (RX) Component
	component uart_rx is
	generic (
		g_CLK_RATE              : integer 	:= 100_000_000     				-- Clock Rate [MHz]
	);
	port (
		i_clk       			: in  	std_logic;							-- Clock
		i_reset_n				: in	std_logic;							-- Reset (Active Low)

		i_soft_reset	 		: in	std_logic;							-- Software Reset
		i_clk_div               : in 	std_logic_vector(15 downto 0 );     -- Clock Division Value
		i_bit_mode				: in	std_logic;							-- Bit Mode
		i_stop_bits				: in	std_logic;							-- Stop Bits
		i_parity_mode			: in	std_logic_vector(1 downto 0);		-- Parity Mode

		i_rx 					: in 	std_logic;							-- Receive (RX) Pin

		o_buffer   				: out  	std_logic_vector(7 downto 0);		-- Buffer
		o_parity_bit			: out	std_logic;							-- Parity Bit
		
		o_idle					: out	std_logic;							-- Idle Flag
		o_busy 					: out 	std_logic;							-- Busy Flag
		o_done   				: out 	std_logic							-- Done Flag
	);
	end component;


    ----------------------------------------------------------------------------------------------------------------------------
    --  SIGNAL DECLARATIONS
    ----------------------------------------------------------------------------------------------------------------------------

	-- n/a


begin

    ----------------------------------------------------------------------------------------------------------------------------
    --  COMPONENT INSTANTIATIONS
    ----------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the UART Transmit (TX) Component
	UART_TX_00 : uart_tx
	generic map (
		g_CLK_RATE				=> g_CLK_RATE
	)
	port map (
		i_clk       			=> i_clk,
		i_reset_n				=> i_reset_n,

		i_soft_reset			=> i_soft_reset,
		i_clk_div               => i_clk_div,
		i_bit_mode				=> i_bit_mode,
		i_stop_bits				=> i_stop_bits,
		i_parity_mode			=> i_parity_mode,

		i_en     				=> i_tx_en,
		i_buffer   				=> i_tx_buffer,

		o_tx 					=> o_tx,

		o_idle					=> o_tx_idle,
		o_busy 					=> o_tx_busy,
		o_done   				=> o_tx_done
	);


	-- Instantiate the UART Receive (RX) Component
	UART_RX_00 : uart_rx
	generic map (
		g_CLK_RATE				=> g_CLK_RATE
	)
	port map (
		i_clk       			=> i_clk,
		i_reset_n				=> i_reset_n,

		i_soft_reset			=> i_soft_reset,
		i_clk_div               => i_clk_div,
		i_bit_mode				=> i_bit_mode,
		i_stop_bits				=> i_stop_bits,
		i_parity_mode			=> i_parity_mode,

		i_rx 					=> i_rx,

		o_buffer   				=> o_rx_buffer,
		o_parity_bit			=> o_parity_bit,

		o_idle					=> o_rx_idle,
		o_busy 					=> o_rx_busy,
		o_done   				=> o_rx_done
	);


end architecture;
--------------------------------------------------------------------------------------------------------------------------------
--	END OF CODE
--------------------------------------------------------------------------------------------------------------------------------
