----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	HARDWARE ACCELERATOR (HWA) CORES
--  TIMER
--
--	ENGINEER:		BEN MACHT, CHRIS MAJOR
--	COMPANY:		RESILIENT COMPUTING
--	DATE:			1/6/2026
--	
--	A BASIC TIMER TO MONITOR TIME PASSED SINCE LAST RESET
--	INTENDED FOR USE AS A HARDWARE ACCELERATOR WITHIN RADPC
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
--  LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	--! IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;

	--! IEEE Numeric Standard Library
	use IEEE.NUMERIC_STD.ALL;


	-- RadPC Reach Core Package
	use WORK.REACH_CORE_PKG.all;


----------------------------------------------------------------------------------------------------------------------------------------
--  ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity hwa is
port(
    i_clk						: in		std_logic;										-- Input Clock
    i_reset_n					: in		std_logic;										-- Reset (Active Low)

    o_hwa_id					: out		std_logic_vector(7 downto 0);					-- Hardware Accelerator ID

    i_data_A					: in		std_logic_vector(31 downto 0);					-- Input Data A
    i_data_B					: in		std_logic_vector(31 downto 0);					-- Input Data B
    i_data_C					: in		std_logic_vector(31 downto 0);					-- Input Data C
    i_data_D					: in		std_logic_vector(31 downto 0);					-- Input Data D
    i_data_E					: in		std_logic_vector(31 downto 0);					-- Input Data E
    i_data_F					: in		std_logic_vector(31 downto 0);					-- Input Data F
    i_data_G					: in		std_logic_vector(31 downto 0);					-- Input Data G
    i_data_H					: in		std_logic_vector(31 downto 0);					-- Input Data H

    o_data_A					: out		std_logic_vector(31 downto 0);					-- Output Data A
    o_data_B					: out		std_logic_vector(31 downto 0);					-- Output Data B
    o_data_C					: out		std_logic_vector(31 downto 0);					-- Output Data C
    o_data_D					: out		std_logic_vector(31 downto 0);					-- Output Data D
    o_data_E					: out		std_logic_vector(31 downto 0);					-- Output Data E
    o_data_F					: out		std_logic_vector(31 downto 0);					-- Output Data F
    o_data_G					: out		std_logic_vector(31 downto 0);					-- Output Data G
    o_data_H					: out		std_logic_vector(31 downto 0);					-- Output Data H

    i_hwa_ctrl					: in		std_logic_vector(7 downto 0);					-- Hardware Accelerator Control (CTRL)
    o_hwa_stat					: out		std_logic_vector(15 downto 0);					-- Hardware Accelerator Status (STAT)

    i_hwaio_in					: in		std_logic_vector(31 downto 0);					-- Hardware Accelerator I/O (Read)
    o_hwaio_out					: out		std_logic_vector(31 downto 0);					-- Hardware Accelerator I/O (Write)
    o_hwaio_dir					: out		std_logic_vector(31 downto 0)					-- Hardware Accelerator I/O (Direction)
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
--  ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture hwa_arch of hwa is

	---------------------------------------------------------------------------------------------------------------------------
	--	SIGNAL DECLARATIONS
	---------------------------------------------------------------------------------------------------------------------------

    signal r_sec                        : std_logic_vector(31 downto 0);                    -- Second Counter
    signal r_hwa_stat                   : std_logic_vector(15 downto 0);                    -- HWA Status


begin

	---------------------------------------------------------------------------------------------------------------------------
	--	SECOND COUNTER PROCESS
	---------------------------------------------------------------------------------------------------------------------------

    -- Process to track seconds since last reset
    SEC_COUNTER : process( i_clk, i_reset_n )

        variable v_clk_div_count            : integer       := 0;                       -- Clock Divider Counter Variable
        variable v_sec_counter              : integer       := 0;                       -- Second Counter Variable

    begin

        -- On reset ...
        if( i_reset_n = '0' ) then

            v_clk_div_count             := 0;
            v_sec_counter               := 0;

            r_sec                       <= (others => '0');


        -- On rising clock edge ...
        elsif( rising_edge( i_clk ) ) then

             -- Bound-check the clock divider count
            if( v_clk_div_count = c_CLK_RATE ) then

                -- Reset clock divider counter
                v_clk_div_count := 0;

                -- Increment second counter
                v_sec_counter  := v_sec_counter + 1;

            else

                -- Increment clock divider counter
                v_clk_div_count := v_clk_div_count + 1;

            end if;

            -- Assign second count to output
            r_sec    <= std_logic_vector( to_unsigned( v_sec_counter, 32 ));


        end if;

    end process;


    ---------------------------------------------------------------------------------------------------------------------------
	--	HARDWARE ACCELERATOR STATUS PROCESS
	---------------------------------------------------------------------------------------------------------------------------

    HWA_STAT: process( i_clk, i_reset_n )
    begin

        -- On reset ...
        if( i_reset_n = '0' ) then

            r_hwa_stat  <= x"0000";


        -- On rising clock edge ...
        elsif( rising_edge( i_clk ) ) then

            r_hwa_stat  <= x"0001";

        end if;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--  SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign HWA ID
	o_hwa_id	    <= x"01";


    -- Assign HWA Outputs
    o_data_A		<= r_sec; 
    o_data_B		<= (others => '0'); 
    o_data_C		<= (others => '0'); 
    o_data_D		<= (others => '0'); 
    o_data_E		<= (others => '0'); 
    o_data_F		<= (others => '0'); 
    o_data_G		<= (others => '0'); 
    o_data_H		<= (others => '0'); 


    -- Assign HWA Status
    o_hwa_stat		<= r_hwa_stat; 


    -- Assign HWA Ports
    o_hwaio_out     <= r_sec; 
    o_hwaio_dir	    <= x"FFFFFFFF";



end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
--  END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------