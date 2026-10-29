----------------------------------------------------------------------------------------------------------------------------------------
--
--	UP/DOWN COUNTER
--
--	Created by Chris Major
-- 	3/24/24
--
--	A counter component designed in VHDL with Up/Down Capability
--
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
--  LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- IEEE Numeric Standard
use IEEE.NUMERIC_STD.ALL;

-- IEEE Real-Type Math Operations
use IEEE.MATH_REAL.ALL;


----------------------------------------------------------------------------------------------------------------------------------------
--  ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity counter_up_down is
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
end counter_up_down;


----------------------------------------------------------------------------------------------------------------------------------------
--  ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture counter_up_down_arch of counter_up_down is

    ------------------------------------------------------------------------------------------------------------------------------------
	--  SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    signal r_count                  : integer range 0 to g_MAX_COUNT        := 0;                       --! Count Value


begin

    ------------------------------------------------------------------------------------------------------------------------------------
	--  PROCESSES
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to run count value
    CNT_00 : process( i_clk, i_reset_n, i_en, i_up_down_sel, r_count )
    begin

        -- On Reset, set count value to 0
        if( i_reset_n = '0' ) then

            r_count     <= 0;

        -- On Clock Edge, increment or reset count value
        elsif( rising_edge( i_clk )) then

            -- If Clear is set ...
            if( i_clr = '1' ) then

                r_count     <= 0;

            -- If Enable is set ...
            elsif( i_en = '1' ) then

                -- If select is UP (1), increment
                if( i_up_down_sel = '1' ) then

                    -- If the count value is less than the clock rate, increment by 1
                    if( r_count < g_MAX_COUNT ) then

                        r_count     <= r_count + 1;

                    -- Else, reset count value
                    else

                        r_count     <= 0;

                    end if;


                else

                    -- If the count value is less than the clock rate, increment by 1
                    if( r_count > 0 ) then

                        r_count     <= r_count - 1;

                    -- Else, reset count value
                    else

                        r_count     <= g_MAX_COUNT;

                    end if;

                end if;

            end if;

        end if;

    end process;


    ------------------------------------------------------------------------------------------------------------------------------------
	--  SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Assign count to output
    o_count     <= std_logic_vector( to_unsigned( r_count, g_SIZE_COUNT ) );


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
--  END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------