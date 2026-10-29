----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	HARDWARE ACCELERATOR (HWA) CORES
--	PASSTHROUGH IN AND OUT
--
--	Created by Hezekiah Austin
-- 	Resilient Computing
-- 	2024-12-02
--
--!	@file
--!	@brief Test component and model for hardware accelerator development. A component for passing through the HWA's I/O pins to the RadPC's HWA I/O and vis versa.
--
----------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------
--	DEVELOPMENT NOTES
----------------------------------------------------------------------------------------------------------------------------------------

-- In addition to testing the HWA I/O, this coprocessor file is also the template for future coprocessor development.
-- If the entity is unchanged, this component will integrated directly into the RadPC system.


----------------------------------------------------------------------------------------------------------------------------------------
--	LIBRARIES
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
--	ENTITY
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
--	ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture hwa_arch of hwa is

	-- VHDL CAN BE CHANGED BETWEEN HERE!


	------------------------------------------------------------------------------------------------------------------------------------
	--	TYPE DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Type for Finite State Machine (FSM) States
	type t_State is ( 
		s_RESET,
		s_OUTPUT,
		s_INPUT
	);	


	------------------------------------------------------------------------------------------------------------------------------------
	--	SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_cur_state				: t_State												-- Finite State Machine (FSM) Current State
									:= s_RESET;				
		
	signal r_nxt_state				: t_State												-- Finite State Machine (FSM) Next State
									:= s_RESET;				

	signal r_select					: std_logic_vector(1 downto 0) := "00";					-- Select Register

	signal r_data_in_A				: std_logic_vector(31 downto 0);						-- Input from RadPC

begin -- This needs to stay


	------------------------------------------------------------------------------------------------------------------------------------
	--	FSM STATE MEMORY LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

	-- Process to handle state memory 
	FSM_STATE_MEMORY : process( i_clk, i_reset_n )
	begin

		-- Handle reset condition
		if( i_reset_n = '0' ) then

			-- Reset current state to IDLE
			r_cur_state		<= s_RESET;

		-- Handle clock edges
		elsif( rising_edge( i_clk ) ) then

			-- Set current state to next state
			r_cur_state		<= r_nxt_state;

		end if;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--	FSM NEXT STATE LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

	-- Process to select next state
	FSM_NEXT_STATE : process( r_select )
	begin

		-- Handle current state
		case( r_select ) is

			-- Reset State
			when "00"		=>	r_nxt_state		<= s_RESET;

			-- Output State
			when "01"		=>	r_nxt_state		<= s_OUTPUT;

			-- Input State
			when "10"		=>	r_nxt_state		<= s_INPUT;
			
			-- (Default)
			when others		=> r_nxt_state		<= s_RESET;

		end case;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--	FSM OUTPUT LOGIC
	------------------------------------------------------------------------------------------------------------------------------------
	
	-- Process to handle output logic
	FSM_OUTPUT_LOGIC : process( r_cur_state )
	begin

		-- Handle current state
		case( r_cur_state ) is

			-- Reset State
			when s_RESET		=>	o_hwaio_dir		<= x"00000000";
									o_hwaio_out		<= x"00000000";
									o_data_A		<= x"00000000";
			-- Idle State
			when s_OUTPUT		=>	o_hwaio_dir		<= x"FFFFFFFF";
									o_hwaio_out		<= r_data_in_A;
			-- Calculate State
			when s_INPUT		=>	o_hwaio_dir		<= x"00000000";
									o_data_A		<= i_hwaio_in;			
			-- (Default)
			when others			=>	o_hwaio_dir		<= x"00000000";
									o_hwaio_out		<= x"00000000";
									o_data_A		<= x"00000000";
		end case;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--	SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign Control Register to State Machine Select
	r_select			<= i_hwa_ctrl(1 downto 0);

	-- Assign RadPC Input to Register
	r_data_in_A			<= i_data_A;

	-- Assign Coprocessor ID Code (You will need to update the ID with a new ID from your assigned coprocessor ID Block)
	o_hwa_id			<= x"02";

	-- AND HERE!


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
--	END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------