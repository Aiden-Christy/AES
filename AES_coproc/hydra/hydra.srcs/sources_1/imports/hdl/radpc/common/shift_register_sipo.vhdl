----------------------------------------------------------------------------------------------------------------------------------------
--
--	SHIFT REGISTER
--  SERIAL IN PARALLEL OUT (SIPO)
--
--	Created by Chris Major
-- 	3/27/24
--
--	A component for a Serial In Parallel Out (SIPO) Shift Register, designed in VHDL.
--
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
--  LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


----------------------------------------------------------------------------------------------------------------------------------------
--  ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity shift_register_sipo is
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
end shift_register_sipo;


----------------------------------------------------------------------------------------------------------------------------------------
--  ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture shift_register_sipo_arch of shift_register_sipo is

    ------------------------------------------------------------------------------------------------------------------------------------
	--  TYPE DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    type t_shift_stages is array( 0 to (g_PARALLEL_SIZE-1) ) of std_logic;                              --! Type for Array of Stages


    ------------------------------------------------------------------------------------------------------------------------------------
	--  SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    signal r_stages                 : t_shift_stages;                                                   --! SISO Stages

    
begin

    ------------------------------------------------------------------------------------------------------------------------------------
	--  PROCESSES
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle SIPO shift process
    SIPO_SHIFT : process( i_clk, i_reset_n, i_data_in )
    begin

        -- On Reset, clear values
        if( i_reset_n = '0' ) then

            r_stages        <= ( others     => '0' );
            --o_data_out      <= ( others     => '0' );


        -- On rising clock edge ...
        elsif( rising_edge( i_clk )) then

            -- If Enable is set ...
            if( i_en = '1' ) then 

                -- Feed data input into shift register
                r_stages(0)     <= i_data_in;

                -- Handle shifting bit across internal register
                for i in 1 to (g_PARALLEL_SIZE-1) loop

                    r_stages(i)     <= r_stages(i-1);

                end loop;

            end if;

        end if;

    end process;


    -- Comment this out when it causes issues lol
    OUTPUT_SHIFT : process( r_stages )
    begin

        -- Concatenate shift register into output
        for i in (g_PARALLEL_SIZE-1) downto 0 loop

            o_data_out(i)   <= r_stages( (g_PARALLEL_SIZE-1)-i);

        end loop;
        
    end process;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------