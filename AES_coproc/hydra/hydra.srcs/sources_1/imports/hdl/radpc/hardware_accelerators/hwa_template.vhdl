----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	HARDWARE ACCELERATOR (HWA) CORES
--	[TEMPLATE]
--
--	Created by [DEVELOPER]
-- 	Resilient Computing
-- 	[DD]/[MM]/[YYYY]
--
--	[DESCRIPTION]
--
----------------------------------------------------------------------------------------------------------------------------------------


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

	------------------------------------------------------------------------------------------------------------------------------------
	--	COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- [DECLARE COMPONENTS HERE]


	------------------------------------------------------------------------------------------------------------------------------------
	--	TYPE DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- [DECLARE TYPES FOR A STATE MACHINE HERE]


	------------------------------------------------------------------------------------------------------------------------------------
	--	CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- [DECLARE CONSTANTS HERE]


	------------------------------------------------------------------------------------------------------------------------------------
	--	SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- [DECLARE SIGNALS HERE]


begin


	------------------------------------------------------------------------------------------------------------------------------------
	--	COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- [DECLARE COMPONENTS HERE]


	------------------------------------------------------------------------------------------------------------------------------------
	--	SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- [ASSIGN SIGNALS HERE]


	-- [ALL HARDWARE ACCELERATORS MUST HAVE A UNIQUE ASSIGNED ID]
	-- [ID 00 IS RESERVED FOR EMPTY HWA PBLOCK SPACE]
	o_hwa_id <= x"00";


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
--	END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------