----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC MULTI-PROCESSOR CORE
--
--	Created by Chris Major
-- 	12/7/2022
--
--	A wrapper for the RadPC RISCV "Reach" processing cores.
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
-- LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity voter is
generic(
    g_VOTE_SIZE                 : integer       := 8		                                    -- Size of voted values
);
port(
    i_val_00                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );         -- Vote value 0
    i_val_01                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );         -- Vote value 1
    i_val_02                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );         -- Vote value 2
    i_val_03                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );         -- Vote value 3

    o_result                    : out   std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );         -- Voted result
    o_syndrome                  : out   std_logic_vector( 3 downto 0 )                          -- Faulty value syndrome
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture voter_arch of voter is

    ------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------ 

    signal r_00_and_01          : std_logic;                                                                -- Value 00 = Value 01 flag
    signal r_00_and_02          : std_logic;                                                                -- Value 00 = Value 02 flag
    signal r_00_and_03          : std_logic;                                                                -- Value 00 = Value 03 flag
    signal r_01_and_02          : std_logic;                                                                -- Value 01 = Value 02 flag
    signal r_01_and_03          : std_logic;                                                                -- Value 01 = Value 03 flag
    signal r_02_and_03          : std_logic;                                                                -- Value 02 = Value 03 flag

	signal r_result				: std_logic_vector( (g_VOTE_SIZE - 1) downto 0) := (others => '0');         -- Intermediate signal
    signal r_syndrome           : std_logic_vector( 3 downto 0 )                := (others => '0');         -- Intermediate signal
    
begin

    ------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    r_00_and_01 <= '1' when (i_val_00 = i_val_01) else '0';                                                             -- Val 00 = Val 01?
    r_00_and_02 <= '1' when (i_val_00 = i_val_02) else '0';                                                             -- Val 00 = Val 02?
    r_00_and_03 <= '1' when (i_val_00 = i_val_03) else '0';                                                             -- Val 00 = Val 03?
    r_01_and_02 <= '1' when (i_val_01 = i_val_02) else '0';                                                             -- Val 01 = Val 02?
    r_01_and_03 <= '1' when (i_val_01 = i_val_03) else '0';                                                             -- Val 01 = Val 03?
    r_02_and_03 <= '1' when (i_val_02 = i_val_03) else '0';                                                             -- Val 02 = Val 03?

    -- Output the correct value
    r_result            <=  i_val_00 when   (r_00_and_01 = '1') and (r_00_and_02 = '1') and (r_00_and_03 = '1') and     -- Full Agreement
                                            (r_01_and_02 = '1') and (r_01_and_03 = '1') and (r_02_and_03 = '1') else                                                        


                            i_val_01 when   (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 00 Error
                                            (r_01_and_02 = '1') and (r_01_and_03 = '1') and (r_02_and_03 = '1') else  

                            i_val_00 when   (r_00_and_01 = '0') and (r_00_and_02 = '1') and (r_00_and_03 = '1') and     -- Val 01 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '1') else  

                            i_val_00 when   (r_00_and_01 = '1') and (r_00_and_02 = '0') and (r_00_and_03 = '1') and     -- Val 02 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '1') and (r_02_and_03 = '0') else  

                            i_val_00 when   (r_00_and_01 = '1') and (r_00_and_02 = '1') and (r_00_and_03 = '0') and     -- Val 03 Error
                                            (r_01_and_02 = '1') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else  


                            i_val_02 when   (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 00/01 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '1') else 

                            i_val_01 when   (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 00/02 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '1') and (r_02_and_03 = '0') else 

                            i_val_01 when   (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 00/03 Error
                                            (r_01_and_02 = '1') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else 
                                            
                            i_val_00 when   (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '1') and     -- Val 01/02 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else 

                            i_val_00 when   (r_00_and_01 = '0') and (r_00_and_02 = '1') and (r_00_and_03 = '0') and     -- Val 01/03 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else 

                            i_val_00 when   (r_00_and_01 = '1') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 02/03 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else 


                            (others => '0');                                                                            -- (Default)


    -- Diagnose the bad values
    r_syndrome          <=  "0000"  when    (r_00_and_01 = '1') and (r_00_and_02 = '1') and (r_00_and_03 = '1') and     -- Full Agreement
                                            (r_01_and_02 = '1') and (r_01_and_03 = '1') and (r_02_and_03 = '1') else                    


                            "0001"  when    (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 00 Error
                                            (r_01_and_02 = '1') and (r_01_and_03 = '1') and (r_02_and_03 = '1') else  

                            "0010"  when    (r_00_and_01 = '0') and (r_00_and_02 = '1') and (r_00_and_03 = '1') and     -- Val 01 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '1') else  

                            "0100"  when    (r_00_and_01 = '1') and (r_00_and_02 = '0') and (r_00_and_03 = '1') and     -- Val 02 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '1') and (r_02_and_03 = '0') else  

                            "1000"  when    (r_00_and_01 = '1') and (r_00_and_02 = '1') and (r_00_and_03 = '0') and     -- Val 03 Error
                                            (r_01_and_02 = '1') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else  


                            "0011"  when    (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 00/01 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '1') else 

                            "0101"  when    (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 00/02 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '1') and (r_02_and_03 = '0') else 

                            "1001"  when    (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 00/03 Error
                                            (r_01_and_02 = '1') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else 
                                            
                            "0110"  when    (r_00_and_01 = '0') and (r_00_and_02 = '0') and (r_00_and_03 = '1') and     -- Val 01/02 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else 

                            "1010"  when    (r_00_and_01 = '0') and (r_00_and_02 = '1') and (r_00_and_03 = '0') and     -- Val 01/03 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else 

                            "1100"  when    (r_00_and_01 = '1') and (r_00_and_02 = '0') and (r_00_and_03 = '0') and     -- Val 02/03 Error
                                            (r_01_and_02 = '0') and (r_01_and_03 = '0') and (r_02_and_03 = '0') else 


                            "1111";                                                                                     -- (Default)


    -- Route intermediates to outputs
    o_result    <= r_result;
    o_syndrome  <= r_syndrome;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------
