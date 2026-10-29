----------------------------------------------------------------------------------------------------------------------------------------
--
--  SEVEN SEGMENT DISPLAY
--
--	Created by Chris Major
-- 	5/31/2021
--
--	A general, parameterized state machine for handling Seven Segment Display devices.
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

-- IEEE Real Math Library
use IEEE.MATH_REAL.ALL;


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity seven_seg is
generic(
    g_SEG_NUM                   : integer                               := 4                -- Number of Seven Segment Displays
);
port (  
	i_clk						: in	std_logic;											-- Clock
	i_reset_n					: in	std_logic;											-- Active Low Reset
        
    i_input_val                 : in    std_logic_vector(((g_SEG_NUM * 4) - 1) downto 0);   -- Binary input number
	i_radix                     : in    std_logic_vector((g_SEG_NUM - 1) downto 0);         -- Radix Point input

    o_anode_act            		: out   std_logic_vector((g_SEG_NUM - 1) downto 0);         -- Active Anode Flag
    o_led_out                   : out   std_logic_vector(7 downto 0)                        -- BCD Value LED Output
);
end seven_seg;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture seven_seg_arch of seven_seg is

	------------------------------------------------------------------------------------------------------------------------------------
	-- CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------ 

    constant c_ANODE_SIZE                       : integer := integer( ceil( real(g_SEG_NUM) / real(4) ) );  -- Number of Possible Anodes


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------ 

    signal r_val_refresh_counter                : unsigned(19 downto 0);							        -- Value Refresh Counter	
	 
    signal r_displayed_number                   : std_logic_vector(((g_SEG_NUM * 4) - 1) downto 0);			-- Number to be displayed
    signal r_led_bcd                            : std_logic_vector(3 downto 0);				                -- Binary Decimal Value
    signal r_radix                              : std_logic;                                                -- Radix point
    
    signal r_anode                    			: integer range 0 to (g_SEG_NUM - 1);                       -- Active anode flags


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- PROCESSES
	------------------------------------------------------------------------------------------------------------------------------------

    -- CLOCKING PROCESS
    -- Handle clock and reset signals through counter
    CLOCK_01 : process( i_clk, i_reset_n )
    begin 
    
		-- On reset, set the Value Refresh Counter to 0
        if( i_reset_n = '0' ) then
            r_val_refresh_counter <= (others => '0');
        
		-- On clock rising edge, increment Value Refresh Counter
        elsif( rising_edge(i_clk) ) then
            r_val_refresh_counter <= r_val_refresh_counter + 1;
            
        end if;
    
	end process;


    -- SEVEN SEGMENT PROCESS
    -- Process for Binary Count Decimal (BCD) 7-segment display
    SEVEN_SEG_01 : process( r_led_bcd, r_radix )
    begin
	
		-- Assign BCD value to 7 segment display given binary input
        case( r_led_bcd ) is

            when "0000" => o_led_out(7 downto 1) <= "0000001";  
            when "0001" => o_led_out(7 downto 1) <= "1001111";
            when "0010" => o_led_out(7 downto 1) <= "0010010";
            when "0011" => o_led_out(7 downto 1) <= "0000110";
            
            when "0100" => o_led_out(7 downto 1) <= "1001100";
            when "0101" => o_led_out(7 downto 1) <= "0100100";
            when "0110" => o_led_out(7 downto 1) <= "0100000";
            when "0111" => o_led_out(7 downto 1) <= "0001111";
            
            when "1000" => o_led_out(7 downto 1) <= "0000000";
            when "1001" => o_led_out(7 downto 1) <= "0000100";
            when "1010" => o_led_out(7 downto 1) <= "0000010";
            when "1011" => o_led_out(7 downto 1) <= "1100000";
            
            when "1100" => o_led_out(7 downto 1) <= "0110001";
            when "1101" => o_led_out(7 downto 1) <= "1000010";
            when "1110" => o_led_out(7 downto 1) <= "0110000";
            when "1111" => o_led_out(7 downto 1) <= "0111000";

            when others => o_led_out(7 downto 1) <= "1111111";

        end case;

        -- Assign radix point to 7 segment display given radix input
        case( r_radix ) is

            when '1'    => o_led_out(0)         <= '0';
            
            when others => o_led_out(0)         <= '1';

        end case;
		
    end process;


    -- Generate Statment to handle a varying number of 7-segment displays with their anodes
    g_GENERATE_DISPLAYS: for i in (g_SEG_NUM - 1) downto 0 generate
    
        o_anode_act(i)  <=  '0' when (r_anode = i ) else
                            '1';

    end generate g_GENERATE_DISPLAYS;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Assign hex value to output depending on current 7-segment display
    r_led_bcd                   <=  r_displayed_number( ((4 * r_anode) + 3) downto (4 * r_anode));

    -- Assign radix point to output depending on current radix position
    r_radix                     <=  i_radix( r_anode );

    -- Assign signals to route processes
    r_anode           			<= to_integer( r_val_refresh_counter(19 downto (19 - c_ANODE_SIZE ) ) );
    r_displayed_number          <= i_input_val;
    

end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------