----------------------------------------------------------------------------------------------------------------------------------------
--
--	RISCV PROCESSOR CORE
--	PROGRAM COUNTER (PC)
--
--	Created by Chris Major
-- 	6/16/2022
--
--	A handwritten attempt at a functional RISC-V core in VHDL.
--
-- 	The Program Counter (PC) tracks the current instruction being executed within the RISCV processor.
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
-- LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	-- IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;

	-- IEEE Numeric Standard Library
	use IEEE.NUMERIC_STD.ALL;


	-- RadPC Reach Core Package
	use WORK.REACH_CORE_PKG.all;


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity program_counter is
generic(
	g_PC_RESET					: integer 			:= 0									-- Program Count Reset Value
);
port(
	i_clk						: in	std_logic;											-- Clock
	i_reset_n					: in	std_logic;											-- Active Low Reset
	i_alu_val					: in 	std_logic_vector(31 downto 0);						-- ALU PC input
	i_mtvec						: in	std_logic_Vector(31 downto 0);						-- Machine Trap-Vector Base-Address (MTVEC) input
	i_mepc						: in	std_logic_vector(31 downto 0);						-- Machine Exception Program Count (MEPC) input

	i_pc_en						: in	std_logic;											-- PC Value enable signal
	i_pc_sel					: in	std_logic_vector(1 downto 0);						-- PC Value selection signal

    i_arbiter_en          		: in    std_logic;                                         	-- Arbiter Write Enable
    i_arbiter_pc             	: in    std_logic_vector(31 downto 0);                      -- Arbiter Write Data

	o_pc						: out	std_logic_vector(31 downto 0);						-- Program Counter Output Value
	o_pc_plus					: out	std_logic_vector(31 downto 0)						-- Program Counter Lookahead Value
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture program_counter_arch of program_counter is

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_pc					: unsigned(31 downto 0) 	:= to_unsigned( g_PC_RESET, 32 );	-- Internal Program Counter Signal
	signal r_pc_inc				: unsigned(31 downto 0) 	:= to_unsigned( g_PC_RESET, 32 );	-- Internal Program Counter Signal


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- PROCESSES
	------------------------------------------------------------------------------------------------------------------------------------

	-- Process to handle program counter value
	PROGRAM_COUNTER_PROC_00 : process( i_clk, i_reset_n )
	begin

		-- On reset ...
		if( i_reset_n = '0' ) then

			-- Reset program counter to dedicated reset address in IMEM
			r_pc 		<= to_unsigned( g_PC_RESET, 32 );

			-- Reset incremented program counter to dedicated reset address in IMEM
			r_pc_inc	<= to_unsigned( g_PC_RESET, 32 );


		-- On rising clock edge ...
		elsif( rising_edge( i_clk ) ) then

			-- If Arbiter Write enable is set
			if( i_arbiter_en = '1' ) then

				-- Add ALU value to program counter
				r_pc 		<= unsigned( i_arbiter_pc );

				-- Add 4 to ALU-added incremented program counter
				r_pc_inc 	<= unsigned( i_arbiter_pc ) + 4;


			-- If PC Enable is set ...
			elsif( i_pc_en = '1' ) then

				-- ALU-based Program Counter increment
				if( i_pc_sel = c_PC_ALU ) then

					-- Add ALU value to program counter
					r_pc 		<= unsigned( i_alu_val );

					-- Add 4 to ALU-added incremented program counter
					r_pc_inc 	<= unsigned( i_alu_val ) + 4;


				-- MTVEC-based Program Counter increment
				elsif( i_pc_sel = c_PC_MTVEC ) then

					-- Add MTVEC value to program counter
					r_pc 		<= unsigned( i_mtvec );

					-- Add 4 to MTVEC-added incremented program counter
					r_pc_inc 	<= unsigned( i_mtvec ) + 4;


				-- MEPC-based Program Counter increment
				elsif( i_pc_sel = c_PC_MEPC ) then

					-- Add MEPC value to program counter
					r_pc 		<= unsigned( i_mepc );

					-- Add 4 to MEPC-added incremented program counter
					r_pc_inc 	<= unsigned( i_mepc ) + 4;


				-- Default Program Counter increment
				elsif( i_pc_sel = c_PC_INCR ) then

					-- Assign incremented program counter to program counter
					r_pc		<= r_pc_inc;

					-- Add 4 to incremented program counter
					r_pc_inc 	<= r_pc_inc + 4;

				end if;

			end if;

		end if;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Connect program counter register to output port 
	o_pc 			<= std_logic_vector( r_pc );
	o_pc_plus 		<= std_logic_vector( r_pc_inc );


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------