----------------------------------------------------------------------------------------------------------------------------------------
--
--	RISCV PROCESSOR CORE
--	ARITHMETIC LOGIC UNIT (ALU)
--
--	Created by Chris Major
-- 	6/17/2022
--
--	A handwritten attempt at a functional RISC-V core in VHDL.
--
-- 	The Arithmetic Logic Unit (ALU) calculates basic operations based on the inputs.
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


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity alu is
port(
    i_data_A                    : in 	std_logic_vector(31 downto 0);                      -- Register A Data
    i_data_B                    : in	std_logic_vector(31 downto 0);                      -- Register B Data

    i_alu_sel                   : in    std_logic_vector(2 downto 0);                       -- ALU operation select
    i_data_pass                 : in    std_logic_vector(1 downto 0);                       -- Passthrough flag
    i_funct7                    : in    std_logic_vector(6 downto 0);                       -- ALU function 7 select

	o_alu_output			    : out	std_logic_vector(31 downto 0)						-- ALU Output
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture alu_arch of alu is

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_alu_output         : signed(31 downto 0);                                      -- ALU Output 


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Perform the requested ALU operation
    r_alu_output        <=  signed( i_data_A ) + signed( i_data_B )                                                                                     -- ADD
                                when (i_alu_sel = "000" and i_funct7 = "0000000" and i_data_pass = "00" ) else                 

                            signed( i_data_A ) - signed( i_data_B )                                                                                     -- SUB
                                when (i_alu_sel = "000" and i_funct7 = "0100000" and i_data_pass = "00") else                 

                            signed( shift_left(unsigned( i_data_A ), natural( to_integer( unsigned( i_data_B(4 downto 0) )))))                          -- SLL         
                                when (i_alu_sel = "001" and i_data_pass = "00") else                 

                            x"00000001" when (i_alu_sel = "010" and (signed( i_data_A ) < signed( i_data_B )) and i_data_pass = "00") else              -- SLT
                            x"00000000" when (i_alu_sel = "010" and (signed( i_data_A ) >= signed( i_data_B )) and i_data_pass = "00") else

                            x"00000001" when (i_alu_sel = "011" and (unsigned( i_data_A ) < unsigned( i_data_B )) and i_data_pass = "00") else          -- SLTU
                            x"00000000" when (i_alu_sel = "011" and (unsigned( i_data_A ) >= unsigned( i_data_B )) and i_data_pass = "00") else                                 

                            signed( i_data_A xor i_data_B )                                                                                             -- XOR
                                when (i_alu_sel = "100" and i_data_pass = "00") else                 

                            signed( shift_right(unsigned( i_data_A ), natural( to_integer( unsigned( i_data_B(4 downto 0) )))))                         -- SRL     
                                when (i_alu_sel = "101" and i_funct7 = "0000000" and i_data_pass = "00") else             

                            signed( shift_right(signed( i_data_A ), natural( to_integer( unsigned( i_data_B(4 downto 0) )))))                           -- SRA      
                                when (i_alu_sel = "101" and i_funct7 = "0100000" and i_data_pass = "00") else               

                            signed( i_data_A or i_data_B )                                                                                              -- OR
                                when (i_alu_sel = "110" and i_data_pass = "00") else                 

                            signed( i_data_A and i_data_B )                                                                                             -- AND
                                when (i_alu_sel = "111" and i_data_pass = "00") else                 

                            signed( i_data_B )                                                                                                          -- Data B
                                when (i_data_pass = "01") else                                                                                          
                            
                            signed( i_data_A )                                                                                                          -- Data A
                                when (i_data_pass = "10") else                                                                                          

                            x"00000000";                                                                                                                -- (Default Case)


	-- Send intermediate ALU output to actual output
    o_alu_output        <= std_logic_vector( r_alu_output );
	

end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------