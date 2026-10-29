----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  PERIPHERALS
--	TIMER PERIPHERAL DEVICE
--
--	CREATED BY TRISTAN RUNNING CRANE
--  RESILIENT COMPUTING
-- 	05/29/2024
--
--!	@file
--!	@brief A Timer Device
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
entity timer is

port(
	i_clk						: in	std_logic;														--! Clock
	i_reset_n					: in	std_logic;														--! Active Low Reset

	i_ctl						: in	std_logic_vector(31 downto 0);									--! TIMER Countrol Value
	i_mtime_L					: in	std_logic_vector(31 downto 0);									--! TIMER Counter Low  Value
	i_mtime_H					: in	std_logic_vector(31 downto 0);									--! TIMER Counter High Value
	i_mtimecmp_L				: in	std_logic_vector(31 downto 0);									--! TIMER Compare Low  Value
	i_mtimecmp_H				: in	std_logic_vector(31 downto 0);									--! TIMER Compare High Value

	o_mtime_L					: out	std_logic_vector(31 downto 0);									--! TIMER Counter Low  Value
	o_mtime_H					: out	std_logic_vector(31 downto 0)									--! TIMER Counter High Value
);
end entity;

----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture timer_arch of timer is

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_mtime_counter_L		: unsigned(31 downto 0) := x"00000000";								--! TIMER Counter Low  Register
	signal r_mtime_counter_H		: unsigned(31 downto 0) := x"00000000";								--! TIMER Counter High Register
	signal r_mtime_compare_L		: unsigned(31 downto 0) := x"00000000";								--! TIMER Compare Low  Register
	signal r_mtime_compare_H		: unsigned(31 downto 0) := x"00000000";								--! TIMER Compare High Register

	signal r_mtime_tclr				: std_logic				:= '0';										--! TIMER Clear Bit
	signal r_mtime_tmode			: std_logic_vector(1 downto 0)	:= "00";							--! TIMER Mode Bits
	signal r_mtime_dir				: std_logic				:= '0';										--! TIMER Counter Direction Bit

begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- PROCESSES
	------------------------------------------------------------------------------------------------------------------------------------
	
	--Timer Process
	TIMER_PROC_00 : process( i_clk, i_reset_n)
	begin

		if( i_reset_n = '0' OR r_mtime_tclr = '1') then
			r_mtime_dir			<= '0';
			r_mtime_counter_L	<= x"00000000";
			r_mtime_counter_H	<= x"00000000";

		elsif( rising_edge( i_clk )) then

			--Only increment if control bit enables counter
			--if(i_mtimecmp_01 /= x"00000000" OR i_mtimecmp_00 /= x"00000000") then
			if(r_mtime_tmode /= "00") then
				
				if (r_mtime_tmode = "01") then
					
					--Check for compare condition
					if((r_mtime_counter_H = r_mtime_compare_H) AND (r_mtime_counter_L = r_mtime_compare_L)) then
						--Reset if double max value reached
						r_mtime_counter_L <= x"00000000";
						r_mtime_counter_H <= x"00000000";

					--Check for single rollover condtion
					elsif(r_mtime_counter_L = x"FFFFFFFF") then

						--Reset if single max value reached
						r_mtime_counter_L <= x"00000000";

						--Increment high register
						r_mtime_counter_H <= r_mtime_counter_H + 1;

					else

						r_mtime_counter_L <= r_mtime_counter_L + 1;

					end if;
					

				elsif(r_mtime_tmode = "10") then
					--Check for double rollover condition
					if(r_mtime_counter_H = x"FFFFFFFF" AND r_mtime_counter_L = x"FFFFFFFF") then

						--Reset if double max value reached
						r_mtime_counter_L <= x"00000000";
						r_mtime_counter_H <= x"00000000";
					
					--Check for single rollover condtion
					elsif(r_mtime_counter_L = x"FFFFFFFF") then

						--Reset if single max value reached
						r_mtime_counter_L <= x"00000000";

						--Increment high register
						r_mtime_counter_H <= r_mtime_counter_H + 1;

					else

						--Increment low register
						r_mtime_counter_L <= r_mtime_counter_L + 1;

					end if;

				elsif(r_mtime_tmode = "11") then

					if (r_mtime_dir = '0') then

						--Check for compare condition
						if((r_mtime_counter_H = r_mtime_compare_H) AND (r_mtime_counter_L = r_mtime_compare_L)) then

							--Invert Counter Direction
							r_mtime_dir <= not r_mtime_dir;

						--Check for single rollover condtion
						elsif(r_mtime_counter_L = x"FFFFFFFF") then

							--Reset if single max value reached
							r_mtime_counter_L <= x"00000000";

							--Increment high register
							r_mtime_counter_H <= r_mtime_counter_H +1;

						else

							r_mtime_counter_L <= r_mtime_counter_L + 1;

						end if;

					elsif(r_mtime_dir = '1') then

						--Check for compare condition
						if((r_mtime_counter_H = x"00000000") AND (r_mtime_counter_L = x"00000000")) then

							--Invert Counter Direction
							r_mtime_dir <= not r_mtime_dir;

						--Check for single rollover condtion
						elsif(r_mtime_counter_L = x"00000000") then

							--Reset if single min value reached
							r_mtime_counter_L <= x"FFFFFFFF";

							--Decrement high register
							r_mtime_counter_H <= r_mtime_counter_H - 1;

						else

							r_mtime_counter_L <= r_mtime_counter_L - 1;

						end if;

					end if;

				end if;

			else

				--If not counter set counter to mem mapped value for starting value
				r_mtime_counter_L <= unsigned(i_mtime_L);
				r_mtime_counter_H <= unsigned(i_mtime_H);

			end if;

		end if;
		
	end process;

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	r_mtime_tclr		<= i_ctl(2);
	r_mtime_tmode		<= i_ctl(5 downto 4);

	r_mtime_compare_L	<= unsigned(i_mtimecmp_L);
	r_mtime_compare_H	<= unsigned(i_mtimecmp_H);

	o_mtime_L 		<=	std_logic_vector(r_mtime_counter_L);
	o_mtime_H 		<=	std_logic_vector(r_mtime_counter_H);


	
	-- CMPNZ_00		<=	'1' when i_mtimecmp_00 /= x"00000000" else
	-- 					'0';


	-- CMPNZ_01		<=	'1' when i_mtimecmp_01 /= x"00000000" else
	-- 					'0';

	-- o_compare_flag	<=	'1'	when ((CMPNZ_00 = '1' AND (r_mtime_counter_L >= unsigned(i_mtimecmp_00))) OR (CMPNZ_01 = '1' AND (r_mtime_counter_H >= unsigned(i_mtimecmp_01)))) else
	-- 					'0';


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------