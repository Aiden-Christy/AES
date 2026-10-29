----------------------------------------------------------------------------------------------------------------------------------------
--
--	RISCV PROCESSOR CORE
--	IMMEDIATE VALUE GENERATION
--
--	Created by Chris Major
-- 	6/21/2022
--
--	A handwritten attempt at a functional RISC-V core in VHDL.
--
-- 	The Immediate Value Generation component (Imm Gen) generates the immediate values needed for instructions
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
entity imm_gen is
port(
    i_inst                      : in 	std_logic_vector(31 downto 7);                      -- Input Instruction
    i_imm_sel                   : in	std_logic_vector(2 downto 0);                       -- Imm Mode Select

	o_imm_val			        : out	std_logic_vector(31 downto 0)						-- Immediate Value
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture imm_gen_arch of imm_gen is

    ------------------------------------------------------------------------------------------------------------------------------------
	-- CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    constant c_I_IMM            : std_logic_vector(2 downto 0)      := "000";               --! I-Type Immediate Generation Code 
    --constant c_I_SHAMT          : std_logic_vector(2 downto 0)      := "001";               --! I-Type (Shift) Immediate Generation Code
    constant c_S_IMM            : std_logic_vector(2 downto 0)      := "010";               --! S-Type Immediate Generation Code
    constant c_B_IMM            : std_logic_vector(2 downto 0)      := "011";               --! B-Type Immediate Generation Code
    constant c_J_IMM            : std_logic_vector(2 downto 0)      := "100";               --! J-Type Immediate Generation Code
    constant c_U_IMM            : std_logic_vector(2 downto 0)      := "101";               --! U-Type Immediate Generation Code
    constant c_SYS_IMM          : std_logic_vector(2 downto 0)      := "110";               --! SYS-Type Immediate Generation Code


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_i_imm_val          : std_logic_vector(31 downto 0);                            --! I-Instruction Immediate Value
    --signal r_i_shamt_val        : std_logic_vector(31 downto 0);                            --! I-Instruction Shift Immediate Value
    signal r_s_imm_val          : std_logic_vector(31 downto 0);                            --! S-Instruction Immediate Value
    signal r_b_imm_val          : std_logic_vector(31 downto 0);                            --! B-Instruction Immediate Value
    signal r_j_imm_val          : std_logic_vector(31 downto 0);                            --! J-Instruction Immediate Value
    signal r_u_imm_val          : std_logic_vector(31 downto 0);                            --! U-Instruction Immediate Value
    signal r_csr_imm_val        : std_logic_vector(31 downto 0);                            --! SYSTEM-Instruction (CSR) Immediate Value


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Create immediate value for I instruction
    r_i_imm_val     <=  x"FFFFF" & i_inst(31 downto 20)                                             when i_inst(31) = '1' else
                        x"00000" & i_inst(31 downto 20);


    -- Create immediate value for I instruction Shift Value
    --r_i_shamt_val   <=  x"000000" & i_inst(27 downto 20);


    -- Create immediate value for S instruction
    r_s_imm_val     <=  x"FFFFF" & i_inst(31 downto 25) & i_inst(11 downto 7)                       when i_inst(31) = '1' else
                        x"00000" & i_inst(31 downto 25) & i_inst(11 downto 7);


    -- Create immediate value for B instruction
    r_b_imm_val     <=  x"FFFFF" & i_inst(7) & i_inst(30 downto 25) & i_inst(11 downto 8) & '0'     when i_inst(31) = '1' else
                        x"00000" & i_inst(7) & i_inst(30 downto 25) & i_inst(11 downto 8) & '0';


    -- Create immediate value for J instruction
    r_j_imm_val     <=  x"FFF" & i_inst(19 downto 12) & i_inst(20) & i_inst(30 downto 21) & '0'     when i_inst(31) = '1' else
                        x"000" & i_inst(19 downto 12) & i_inst(20) & i_inst(30 downto 21) & '0';


    -- Create immediate value for U instruction
    r_u_imm_val     <=  i_inst(31 downto 12) & x"000";


    -- Create immediate value for SYSTEM CSR instruction
    r_csr_imm_val   <= X"00000" & i_inst(31 downto 20); 



    -- Assign immediate output value
    o_imm_val       <=  r_i_imm_val                         when i_imm_sel = c_I_IMM            else           --i_imm_sel = "000" else
                        --r_i_shamt_val                       when i_imm_sel = c_I_SHAMT          else           --i_imm_sel = "001" else
                        r_s_imm_val                         when i_imm_sel = c_S_IMM            else           --i_imm_sel = "010" else
                        r_b_imm_val                         when i_imm_sel = c_B_IMM            else           --i_imm_sel = "011" else
                        r_j_imm_val                         when i_imm_sel = c_J_IMM            else           --i_imm_sel = "100" else
                        r_u_imm_val                         when i_imm_sel = c_U_IMM            else           --i_imm_sel = "101" else
                        r_csr_imm_val                       when i_imm_sel = c_SYS_IMM          else           --i_imm_sel = "110" else
                        x"00000000";


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------