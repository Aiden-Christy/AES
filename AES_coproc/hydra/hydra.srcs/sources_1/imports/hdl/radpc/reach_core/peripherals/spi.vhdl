----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  PERIPHERALS
--	SPI PERIPHERAL DEVICE
--
--	CREATED BY Garrett Perkins and Kris Allick
--  RESILIENT COMPUTING
-- 	09/09/2025
--
--!	@file
--!	@brief A SPI transceiver device with Master/Slave mode capabilities
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
-- LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- IEEE Numeric Standard Library
use IEEE.NUMERIC_STD.ALL;

-- -- UNISIM Standard Library
-- library UNISIM;
-- use UNISIM.vcomponents.all;


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity spi is
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
    i_pkt_size                  : in    std_logic_vector(15 downto 0):=(others => '0') ;                --! Packet Size Register for 4 pin mode
    -- Transmit trigger from mem_spi
    i_tx_write				    : in 	std_logic;														--! SPI ready-to-transmit(This goes High when something gets loaded into the TX buffer from the memory bus)

    -- Buffers
	o_rx_buf					: out	std_logic_vector(7 downto 0):= (others => '0');									--! SPI Receive (RX) Buffer Value
	i_tx_buf					: in	std_logic_vector(7 downto 0):= (others => '0');									--! SPI Transmit (TX) TX Buffer

    -- Output Status Register
	o_mode					    : out	std_logic;														--! Main Mode (Master/Slave) Flag 
	o_spi_reset					: out	std_logic;														--! SPI Reset Flag
	o_busy                  	: out	std_logic;                                  					--! SPI Busy Flag
	o_done						: out	std_logic;		

    i_miso						: in	std_logic;														--! SPI Input Master In Slave Out (MISO)
    o_miso						: out	std_logic;														--! SPI Output Master In Slave Out (MISO)
    i_mosi						: in	std_logic;														--! SPI Input Master Out Slave In (MOSI)
    o_mosi						: out	std_logic;														--! SPI Output Master Out Slave In (MOSI)
    i_sclk						: in	std_logic;														--! SPI Incoming Serial Clock (SCLK)
    o_sclk						: out	std_logic;														--! SPI Outgoing Serial Clock (SCLK)
    i_cs						: in	std_logic;														--! SPI Incoming Serial Data (CS)
    o_cs						: out	std_logic														--! SPI Outgoing Serial Data (CS)
	);
end entity;

-- SPI CTL Register
--------------------------------------------------------------
--|BIT15|BIT14|BIT13|BIT12|BIT11|BIT10|BIT9|BIT8|
--|  x |  x  |  x  |  x  |  x  |  x  |  x  |  x |
--|BIT7|BIT6|BIT5|BIT4|BIT3|BIT2|BIT1|BIT0|
--|PIN|CPHA|CPOL|CSPOL|MSB| BIT|MODE |RST|

-- MODE: 0=Master; 1=Slave
-- BIT: 0=8-bit; 1=7-bit
-- MSB: 0=MSB first; 1=LSB first
-- CSPOL: 0=Active Low CS; 1=Active High CS
-- CPOL: 0=Starts Low, 1=Starts High
-- CPHA: 0=Not Implemented, 1=Not Implemented
-- PIN: 0=3-pin SPI, 1=4-pin SPI
-------------------------------------------------------------
-- SPI STAT Register
--------------------------------------------------------------
--|BIT7|BIT6|BIT5|BIT4|BIT3|BIT2|BIT1|BIT0|
-- |  X |  X |  X|  X |DONE|BUSY|MODE|RST|
--------------------------------------------------------------
-- CLK div is weird so idk what the equation actually is but i do know that
-- if you set i_clk_div=0x000E the SPI clock will be ~1Mhz
----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture spi_arch of spi is

------------------------------------------------------------------------------------------------------------------------------------
--  COMPONENT DECLARATIONS
------------------------------------------------------------------------------------------------------------------------------------

    -- Declare the Counter component
    component counter_up_down is
    generic(
        g_MAX_COUNT                     : integer                                   := 256;                 --! Maximum Count Value
        g_SIZE_COUNT                    : integer                                   := 8                    --! Output Count Vector Size
    );
    port(
        i_clk                           : in    std_logic;                                                  --! Input Clock
        i_reset_n                       : in    std_logic;                                                  --! Reset (Active Low)

        i_en                            : in    std_logic;                                                  --! Enable Line
        i_clr                           : in    std_logic;                                                  --! Clear Line

        i_up_down_sel                   : in    std_logic;                                                  --! Up/Down Count Select

        o_count                         : out   std_logic_vector( (g_SIZE_COUNT -1) downto 0)               --! Output Count Value
    );
    end component;


    -- Declare the PISO Shift Register component
    component shift_register_piso is
    generic(
        g_PARALLEL_SIZE                 : integer                                   := 8                    --! Parallel Data Size
    );
    port(
        i_clk                           : in    std_logic;                                                  --! Input Clock
        i_reset_n                       : in    std_logic;                                                  --! Reset (Active Low)

        i_en                            : in    std_logic;                                                  --! Enable Flag
        i_clr                           : in    std_logic;                                                  --! Clear Flag

        i_data_in                       : in    std_logic_vector( (g_PARALLEL_SIZE-1) downto 0 );           --! Input Data

        o_data_out                      : out   std_logic                                                   --! Output Data
    );
    end component;


    -- Instantiate the SIPO component
    component shift_register_sipo is
    generic(
        g_PARALLEL_SIZE                 : integer                                   := 8                    --! Parallel Data Size
    );
    port(
        i_clk                           : in    std_logic;                                                  --! Input Clock
        i_reset_n                       : in    std_logic;                                                  --! Reset (Active Low)
    
        i_en                            : in    std_logic;                                                  --! Enable Line
    
        i_data_in                       : in    std_logic;                                                  --! Input Data
    
        o_data_out                      : out   std_logic_vector( (g_PARALLEL_SIZE-1) downto 0 )            --! Input Data
    );
    end component;


------------------------------------------------------------------------------------------------------------------------------------
-- TYPE DECLARATIONS
------------------------------------------------------------------------------------------------------------------------------------

	--Type for Transmit (TX) States
	type t_state is(
		s_MTR_IDLE, -- Master Idle
		s_MTR_START, -- Master Start
        s_MTR_SETUP, -- Master Setup
		s_MTR_DATA, -- Master Data Transaction
		s_MTR_DONE, -- Master Done
		s_SLV_IDLE, -- Slave Idle
		s_SLV_START, -- Slave Start
		s_SLV_DATA, -- Slave Data Transaction
		s_SLV_DONE -- Slave Done
	);


------------------------------------------------------------------------------------------------------------------------------------
-- SIGNAL DECLARATIONS
------------------------------------------------------------------------------------------------------------------------------------

    signal w_reset              : std_logic;                                                    -- Internal Reset

    signal mtr_state            : t_state                           := s_MTR_IDLE;              -- mtr_state set to default IDLE
	signal slv_state 			: t_state							:= s_SLV_IDLE;

    signal r_clk_max          	: integer range 0 to g_CLK_RATE    	:= 0;                   	--! Clock count maximum value
    signal r_clk_cnt        	: integer range 0 to g_CLK_RATE    	:= 0;                   	--! Clock counter value

    signal w_spi_clk            : std_logic;                                                    --! Transmit (TX) Divided Clock
	

	signal r_mtr_tx_en			: std_logic;													--! Transmit (TX) Enable (Master Mode)
	signal r_mtr_tx_clr			: std_logic;													--! Transmit (TX) Clear (Master Mode)

	signal r_mtr_rx_en			: std_logic;													--! Receive (RX) Enable (Master Mode)
	signal r_mtr_rx_clr			: std_logic;													--! Receive (RX) Clear (Master Mode)

	signal r_mtr_cnt_en			: std_logic;													--! Count Enable (Master Mode)
	signal r_mtr_cnt_clr		: std_logic;													--! Count Clear (Master Mode)

	signal r_mtr_cnt			: std_logic_vector(7 downto 0);									--! Count (Master Mode)

    signal r_mtr_count       	: integer range 0 to 9            	:= 0;                   	--! Transmit (TX) Bit Count (Converted) (Master Mode)   


	signal r_rx_mtr_buf			: std_logic_vector(7 downto 0);									--! Receive (RX) Read Byte (Master Mode)
	signal r_rx_mtr_buf_MSB		: std_logic_vector(7 downto 0);									--! Receive (RX) Read Byte (Master Mode)

	signal r_rx_slv_buf			: std_logic_vector(7 downto 0);									--! Receive (RX) Read Byte (Slave Mode)
    signal r_rx_slv_buf_MSB     : std_logic_vector(7 downto 0);

	signal r_mtr_clk_div_cnt_en : std_logic;
	

	signal r_slv_rx_en			: std_logic;													--! Receive (RX) Enable (Slave Mode)
	signal r_slv_cnt_en			: std_logic;
	signal r_slv_cnt_clr		: std_logic;
	signal r_slv_cnt			: std_logic_vector(7 downto 0);
	signal r_slv_rx_clr			: std_logic;

    signal r_slv_out_count      : integer range 0 to 8            	:= 0;                   	--! Transmit (TX) Bit Count (Converted) (Slave Mode) 
    signal r_slv_in_count       : integer range 0 to 8            	:= 0;                   	--! Transmit (TX) Bit Count (Converted) (Slave Mode) 
	signal r_slv_indx       	: integer range 0 to 8            	:= 0;                   	--! Transmit (TX) Bit Count (Converted) (Slave Mode)    

	signal r_bit_mode			: integer range 0 to 8            	:= 8;						--! Number of bits to transmit/receive

	signal r_tx_buf				: std_logic_vector(7 downto 0);									--! Transmit (TX) Read Byte

    signal w_spi_reset_slv      : std_logic;
    signal w_spi_reset_mtr      : std_logic;
    
	signal w_busy				: std_logic;													--! Busy Flag for Master mode
	signal w_done				: std_logic;													--! Done Flag for Master mode

	signal w_busy_slv			: std_logic;													--! Busy Flag for Slave mode
	signal w_done_slv			: std_logic;													--! Done Flag for Slave mode
	
    
    signal r_tx_buf_slv         : std_logic_vector(7 downto 0);
    signal r_packet_size        : unsigned(15 downto 0);
    signal r_packet_count       : unsigned(15 downto 0) := (others => '0');

    signal test_cs              : std_logic;
    signal w_pkt_continue       : std_logic;
    signal staller_count        : integer := 0;
    constant staller_limit      : integer := 7; -- CS needs to be held active for a max of 250 ns. we use this to stall the rest of the SPI transmission
    signal w_o_sclk           : std_logic;
    signal done_confirm_count : integer := 0;


begin


------------------------------------------------------------------------------------------------------------------------------------
--  MASTER (MTR) COMPONENT INSTANTIATIONS
------------------------------------------------------------------------------------------------------------------------------------

    -- Instantiate the Master State Machine Counter
    MTR_COUNT_00 : counter_up_down
    generic map(
        g_MAX_COUNT                     => 8,
        g_SIZE_COUNT                    => 8
    )
    port map(
        i_clk                           => w_spi_clk,
        i_reset_n                       => w_reset, --not r_mtr_cnt_clr,

        i_en                            => r_mtr_cnt_en,
        i_clr                           => '0',-- Don't Care, the way this module works required the clearing to happen via Reset

        i_up_down_sel                   => '1',

        o_count                         => r_mtr_cnt
    );

	-- Convert counter outputs to integer
    r_mtr_count		<= to_integer( unsigned( r_mtr_cnt ) );

	r_clk_max       <= to_integer( unsigned( i_clk_div ) );	
	r_bit_mode		<= 8 when i_bit_mode='0' else 7;

    w_reset         <= not r_mtr_cnt_clr;


------------------------------------------------------------------------------------------------------------------------------------
--  CLOCK DIVISION PROCESSES
------------------------------------------------------------------------------------------------------------------------------------

    CLOCK_DIV_00 : process(i_clk, i_reset_n)
    begin
        if (i_reset_n = '0') then
            r_clk_cnt  <= 0;
            w_spi_clk  <= i_cpol;

        elsif rising_edge(i_clk) then
            -- When enabled
            if (r_mtr_clk_div_cnt_en = '1') then
                if (r_clk_cnt < r_clk_max) then
                    r_clk_cnt <= r_clk_cnt + 1;
                else
                    r_clk_cnt <= 0;
                    w_spi_clk <= not w_spi_clk;
                end if;

            -- When disabled, reset synchronously
            else
                r_clk_cnt <= 0;
                w_spi_clk <= i_cpol;
            end if;
        end if;
    end process;

    

    MASTER_RX: process(w_o_sclk, i_reset_n)
    begin
        if(rising_edge(w_o_sclk)) then
            if(i_reset_n='0') then
                r_rx_mtr_buf <= (others => '0');
            else
                r_rx_mtr_buf(r_mtr_count) <= i_miso;
            end if;

        end if;
    end process;

    MASTER_NEXT_STATE_LOGIC: process(i_clk)
    begin
        if(rising_edge(i_clk)) then
            if(i_reset_n='0') then
                mtr_state <= s_MTR_IDLE;
                -- Default output logic
                o_sclk <= i_cpol;                               -- idle state based on cpol
                w_o_sclk <= i_cpol;
                w_spi_reset_mtr			<= '1';
				r_mtr_cnt_en		<= '0';
				r_mtr_cnt_clr		<= '1';
                w_busy <= '0';
                w_done <= '0';
                w_pkt_continue<='0';
                r_packet_count<=(others => '0');
                if(i_pin_mode='1') then
                    o_cs  <= not i_cspol;                       -- chip select inactive
                    test_cs <= not i_cspol;
                end if;
                done_confirm_count<=0;
                o_mosi <= i_cpol;                               -- MOSI idle state based on cpol 
                                                                -- NOTE: Nothing says MOSI needs to be in a "known state" before and after transmissions, it is just nice
            elsif(i_soft_reset='1') then
                mtr_state <= s_MTR_IDLE;
                -- Default output logic
                o_sclk <= i_cpol;                               -- idle state based on cpol
                w_o_sclk <= i_cpol;
                w_spi_reset_mtr			<= '1';
                r_mtr_cnt_en		<= '0';
                r_mtr_cnt_clr		<= '1';
                w_busy <= '0';
                w_done <= '0';
                w_pkt_continue<='0';
                r_packet_count<=(others => '0');
                if(i_pin_mode='1') then
                    o_cs  <= not i_cspol;                           -- chip select inactive
                    test_cs <= not i_cspol;
                end if;
                done_confirm_count<=0;
                o_mosi <= i_cpol;                               -- MOSI idle state based on cpol
                                                                -- NOTE: Nothing says MOSI needs to be in a "known state" before and after transmissions, it is just nice                                         
            else
                case mtr_state is
                    when s_MTR_IDLE =>
                    -- output logic for IDLE
						r_mtr_clk_div_cnt_en    <= '0';
						o_sclk                  <= i_cpol;                               -- idle state based on cpol
                        w_o_sclk                <= i_cpol;
                        w_busy                  <= '0';
                        if(done_confirm_count<4) then
                            w_done                  <= '0';
                            done_confirm_count<=done_confirm_count+1;
                        else
                            w_done                  <= '1';
                        end if;
                        if(i_pin_mode='1') then
                            -- if (r_packet_count /= 0) then
                            if(w_pkt_continue='1') then
                                o_cs                <= i_cspol; 
                                test_cs             <= i_cspol;
                            else
                                o_cs                <= not i_cspol;                       -- chip select inactive
                                test_cs             <= not i_cspol;
                            end if; 
                            -- o_cs                <= not i_cspol;                       -- chip select inactive
                            -- test_cs             <= not i_cspol;
                        end if;
                        o_mosi                  <= i_cpol;                               -- MOSI idle state based on cpol 
                                                                        -- NOTE: Nothing says MOSI needs to be in a "known state" before and after transmissions, it is just nice
                        w_spi_reset_mtr			    <= '0';
                    -- if (mode = '1' and i_rx_write= '1') then
                    --     add states for slave
                        if (i_mode = '0' and i_tx_write = '1') then        -- If in Master mode and something has been written to the TX buffer
                            mtr_state <= s_MTR_SETUP;
                        else 
                            mtr_state <= s_MTR_IDLE;
                        end if;
                    when s_MTR_SETUP =>
                        w_done              <='0';
                        o_cs                <= i_cspol;                       -- chip select active
                        if( i_msb_mode = '0') then  -- if MSB mode
                            o_mosi<= i_tx_buf((r_bit_mode-1) - r_mtr_count); -- Send MSB first
                        else                        -- if LSB mode
                            o_mosi<= i_tx_buf(r_mtr_count); -- Send LSB first 
                        end if;
                        if(w_pkt_continue='1') then
                            mtr_state<=s_MTR_START;
                        elsif(staller_count<staller_limit)then
                            staller_count<=staller_count+1;
                            mtr_state<=s_MTR_SETUP;
                        else
                            staller_count<=0;
                            mtr_state           <= s_MTR_START;
                        end if;
                    when s_MTR_START =>
                    -- output logic for START
                        o_sclk				<= i_cpol;
                        w_o_sclk            <= i_cpol;
                        -- if(i_pin_mode='1') then
                        --     if(r_packet_count<r_packet_size-1) then
                        --         o_cs                <= i_cspol; 
                        --     else
                        --         o_cs                <= not i_cspol;                       -- chip select inactive
                        --     end if; 
                            -- o_cs                <= i_cspol;                       -- chip select active
                            -- test_cs             <= i_cspol;
                        -- end if;					
                        o_cs                <= i_cspol;                       -- chip select active
                        w_spi_reset_mtr			<= '0';

						w_busy				<= '1';
						w_done				<= '0';

						r_mtr_rx_en			<= '1';
						r_mtr_rx_clr 		<= '0';

						r_mtr_cnt_en		<= '1';
						r_mtr_cnt_clr		<= '0';

						r_mtr_clk_div_cnt_en <= '1';

						mtr_state<= s_MTR_DATA;
                    when s_MTR_DATA =>
                    -- output logic for DATA
                        o_sclk <= not w_spi_clk;    -- clock out
                        w_o_sclk <= not w_spi_clk;

                        w_spi_reset_mtr			<= '0';
						w_busy              <= '1';              -- set busy
                        w_done              <= '0';              -- clear done
                        
                        if(i_pin_mode='1') then
                            o_cs                <= i_cspol;                       -- chip select active
                            test_cs             <= i_cspol;
                        end if;
						
                        r_mtr_rx_en         <= '1';         -- enable RX Master shift register     
                        r_mtr_rx_clr        <= '0';

						r_mtr_cnt_en        <= '1';        -- enable counter
						r_mtr_cnt_clr       <= '0';

						r_mtr_clk_div_cnt_en <= '1';
						
                        if( r_mtr_count < r_bit_mode ) then
                            if( i_msb_mode = '0') then  -- if MSB mode
                                o_mosi<= i_tx_buf((r_bit_mode-1) - r_mtr_count); -- Send MSB first
                            else                        -- if LSB mode
                                o_mosi<= i_tx_buf(r_mtr_count); -- Send LSB first 
                            end if;
							mtr_state <= s_MTR_DATA;
                        else
                            o_sclk 				<= i_cpol;   -- clock out
                            w_o_sclk            <= i_cpol;
							r_mtr_cnt_clr<='1';	
                            w_done                <= '0';
                            mtr_state <= s_MTR_DONE;
							
                        end if;
                    when s_MTR_DONE =>
                    -- output logic for DONE
						-- o_sclk 				<= not w_spi_clk;   -- clock out
                        o_sclk 				<= i_cpol;   -- clock out
                        w_o_sclk            <= i_cpol;

						w_spi_reset_mtr			<= '0';
						w_done				<= '0';
						w_busy				<= '1';

						r_mtr_rx_en			<= '0';
						r_mtr_rx_clr		<= '1';

						r_mtr_cnt_en		<= '0';
						r_mtr_cnt_clr		<= '1';
						
						r_mtr_clk_div_cnt_en <= '0';
                        done_confirm_count  <=0;
                        if(i_pin_mode='1') then
                            r_packet_count <= r_packet_count + 1;
                            if(r_packet_count >= r_packet_size-1) then
                                r_packet_count <= (others => '0');
                                -- o_cs                <= not i_cspol;                       -- chip select inactive
                                -- test_cs             <= not i_cspol;
                                w_pkt_continue <= '0';
                                mtr_state <= s_MTR_IDLE;
                            -- elsif(r_packet_size=0) then
                            --     o_cs                <= not i_cspol;                       -- chip select inactive
                            elsif(r_packet_count<r_packet_size) then
                                w_pkt_continue <= '1';
                                o_cs                <= i_cspol;                       -- chip select active
                                test_cs             <= i_cspol;
                                mtr_state <= s_MTR_IDLE;
                            end if;
                        else
                            mtr_state <= s_MTR_IDLE;    
                        end if;

						
					when others =>
						mtr_state <= s_MTR_IDLE;
                end case;
            end if;
            r_rx_mtr_buf_MSB<=  r_rx_mtr_buf(0)&r_rx_mtr_buf(1)&r_rx_mtr_buf(2)&r_rx_mtr_buf(3)
                                &r_rx_mtr_buf(4)&r_rx_mtr_buf(5)&r_rx_mtr_buf(6)&r_rx_mtr_buf(7);
        end if;

        r_tx_buf <= i_tx_buf;
    end process;

    SLAVE_DATA_OUTPUT:process(i_sclk,i_cs, i_soft_reset)
    begin
        -- If we are in slave mode...
        if(i_mode='1') then
            if(i_soft_reset='1') then
                
                o_miso<=i_cpol;
                r_slv_out_count<=0;
            -- And If chip select is whatever the mode is
            elsif(i_cs=i_cspol) then
                if(r_slv_out_count=0) then
                    -- if(i_msb_mode='0') then --if MSB mode
                    --     o_miso<= i_tx_buf((r_bit_mode-1)); -- Send MSB first
                    -- else
                    --     o_miso<=i_tx_buf(0); --send LSB first
                    -- end if;
                        if(i_msb_mode='0') then --if MSB mode
                            o_miso<= i_tx_buf((r_bit_mode-1) - r_slv_out_count); -- Send MSB first
                        else
                            o_miso<=i_tx_buf(r_slv_out_count); --send LSB first
                        end if;
                        r_slv_out_count<=r_slv_out_count+1;
                    -- r_slv_out_count<=1;
                        -- slv_state<=s_SLV_DATA;
                -- end if;
                -- On the falling edge of the incoming Master clock  
                elsif(falling_edge(i_sclk))then

                    -- If the counter has "maxed out"...
                    if(r_slv_out_count<r_bit_mode-1)then
                        -- Send out whatever is in the Tx Buffer
                        if(i_msb_mode='0') then --if MSB mode
                            o_miso<= i_tx_buf((r_bit_mode-1) - r_slv_out_count); -- Send MSB first
                        else
                            o_miso<=i_tx_buf(r_slv_out_count); --send LSB first
                        end if;
                        
                        r_slv_out_count<=r_slv_out_count+1;

                    else
                        if(i_msb_mode='0') then --if MSB mode
                            o_miso<= i_tx_buf((r_bit_mode-1) - r_slv_out_count); -- Send MSB first
                        else
                            o_miso<=i_tx_buf(r_slv_out_count); --send LSB first
                        end if;
                        
                    end if;
                end if;
            else
                r_slv_out_count<=0;
            end if;
        end if;
    end process;
    
    SLAVE_DATA_INPUT:process(i_sclk,i_cs, i_soft_reset)
    begin
        -- If we are in slave mode...
        if(i_mode='1') then
            if(i_soft_reset='1') then
                slv_state<=s_SLV_IDLE;
                r_slv_in_count<=1;
            elsif(i_cs=i_cspol) then
                if(rising_edge(i_sclk))then
                    slv_state<=s_SLV_DATA;
                    -- If the counter has "maxed out"...
                    if(r_slv_in_count<r_bit_mode)then
                        -- Grab whatever is on the mosi line and assemble in the Rx Buffer
                        r_rx_slv_buf(r_slv_in_count-1)<=i_mosi;
                        r_slv_in_count<=r_slv_in_count+1;
                    else
                        r_rx_slv_buf(r_slv_in_count-1)<=i_mosi;
                        r_slv_in_count<=1;
                        slv_state<=s_SLV_DONE;
                    end if;
                end if;
            end if;
        end if;
    end process;


    SLAVE_STATE_FLAG_TRACKER:process (i_clk)
    begin
        if(rising_edge(i_clk)) then
            case slv_state is
            when s_SLV_IDLE =>
                w_done_slv			<= '0';
                w_busy_slv			<= '0';
                if i_soft_reset='1' then
                    w_spi_reset_slv            <= '1';
                else
                    w_spi_reset_slv            <= '0';
                end if;
            when s_SLV_DATA =>
                w_busy_slv          <= '1';
                w_done_slv          <= '0';
            when s_SLV_DONE=>
                w_busy_slv          <= '0';
                w_done_slv          <= '1';

            when others =>
                null;
            end case;
            r_rx_slv_buf_MSB    <= r_rx_slv_buf(0)&r_rx_slv_buf(1)&r_rx_slv_buf(2)&r_rx_slv_buf(3)
                    &r_rx_slv_buf(4)&r_rx_slv_buf(5)&r_rx_slv_buf(6)&r_rx_slv_buf(7);
        end if;
    end process;
------------------------------------------------------------------------------------------------------------------------------------
    
BUFFER_UPDATE:process(i_clk, i_soft_reset, i_reset_n)
begin
    if(rising_edge(i_clk)) then
        if(i_reset_n='0') then
            r_packet_size       <= (others => '0');
            o_mode              <= '0';
            o_spi_reset         <= '1';
            o_busy				<= 	'0';
            o_done				<= 	'0';
            o_rx_buf			<=  (others => '0');
        elsif(i_soft_reset='1') then
            r_packet_size        <= (others => '0');
            r_packet_size       <= (others => '0');
            o_mode              <= '0';
            o_spi_reset         <= '1';
            o_busy				<= 	'0';
            o_done				<= 	'0';
            o_rx_buf			<=  (others => '0');
        end if;
        r_packet_size <= resize(unsigned(i_pkt_size), 16);                       -- Packet size register value
        
        o_mode                <= i_mode;

        -- o_spi_reset            <= w_spi_reset_mtr when(i_mode='0') else
        --                             w_spi_reset_slv when(i_mode='1');
        if(i_mode='0') then
            o_spi_reset         <= w_spi_reset_mtr;
        else
            o_spi_reset         <= w_spi_reset_slv;
        end if;													

        -- Set Busy Flag depending on mode
        -- o_busy				<= 	w_busy when( i_mode = '0' )	else
        --                         w_busy_slv when(i_mode = '1');
        if(i_mode='0') then
            o_busy				<= 	w_busy;
        else
            o_busy				<= 	w_busy_slv;
        end if;

        -- Set Done Flag depending on mode
        -- o_done				<= 	w_done when( i_mode = '0' ) else
        --                         w_done_slv when(i_mode='1');
        if(i_mode='0') then
            o_done				<= 	w_done;
        else
            o_done				<= 	w_done_slv;
        end if;
        
        -- Set Receive Buffer depending on mode and being in the "DONE" State
        -- o_rx_buf			<=  r_rx_mtr_buf when(i_mode='0' and i_msb_mode='1' and (w_done='1')) else
        --                         r_rx_mtr_buf_MSB when(i_mode='0' and i_msb_mode='0' and (w_done='1')) else
        --                         r_rx_slv_buf when(i_mode='1' and w_done_slv='1' and i_msb_mode='1') else
        --                         r_rx_slv_buf_MSB when(i_mode='1' and w_done_slv='1' and i_msb_mode='0');
        --                     --    r_rx_slv_buf when(mode= '1' and state= s_SLV_DONE;
        if(i_mode='0') and (i_msb_mode='1') and (r_mtr_count>=(r_bit_mode)) then
            o_rx_buf <= r_rx_mtr_buf;
        elsif(i_mode='0') and (i_msb_mode='0') and (r_mtr_count>=(r_bit_mode)) then
            o_rx_buf <= r_rx_mtr_buf_MSB;
        elsif(i_mode='1') and (i_msb_mode='1') and (w_busy_slv='0') then
            o_rx_buf <= r_rx_slv_buf;
        elsif(i_mode='1') and (i_msb_mode='0') and (w_busy_slv='0') then
            o_rx_buf <= r_rx_slv_buf_MSB;
        end if;
    end if;
end process;
end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- 	END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------
