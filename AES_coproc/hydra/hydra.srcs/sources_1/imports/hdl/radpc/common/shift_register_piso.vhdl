----------------------------------------------------------------------------------------------------------------------------------------
--
--	SHIFT REGISTER
--  PARALLEL IN SERIAL OUT (SPSO)
--
--	Created by Chris Major
-- 	3/26/24
--
--	A component for a Parallel In Serial Out (PISO) Shift Register, designed in VHDL.
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
entity shift_register_piso is
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
end shift_register_piso;


----------------------------------------------------------------------------------------------------------------------------------------
--  ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture shift_register_piso_arch of shift_register_piso is

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

    -- Process to handle PISO shift process
    PISO_SHIFT : process( i_clk, i_reset_n, i_data_in )
    begin

        -- On Reset, clear values
        if( i_reset_n = '0' ) then

            r_stages        <= ( others     => '0' );
            o_data_out      <= '0';


        -- On rising clock edge ...
        elsif( rising_edge( i_clk )) then


            -- If Clear is set, clear internal registers 
            if( i_clr = '1' ) then

                -- Clear all registers
                for i in 1 to (g_PARALLEL_SIZE-1) loop

                    r_stages(i)   <= '0';

                end loop;

                -- Clear output
                o_data_out      <= '0';


            -- If Enable is set, shift values
            elsif( i_en = '1' ) then 

                -- Handle shifting bit across internal register
                for i in 1 to (g_PARALLEL_SIZE-1) loop

                    r_stages(i-1)   <= r_stages(i);

                end loop;

                -- Feed data input into shift register
                o_data_out      <= r_stages(0);


            -- If Enable and Clear are clear, load data into registers
            else

                -- Feed input into shift register
                for i in 0 to (g_PARALLEL_SIZE-1) loop

                    r_stages(i)   <= i_data_in(i);

                end loop;

            end if;

        end if;

    end process;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------