----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	HARDWARE ACCELERATOR (HWA) CORES
--
--	Created by Chris Major and Hezekiah Austin
-- 	Resilient Computing
-- 	2024-12-02
--
--!	@file
--!	@brief A component for hardware accelerator (HWA)
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
entity hwa_core is
port(
	i_clk						: in		std_logic;										-- Input Clock
	i_reset_n					: in		std_logic;										-- Reset (Active Low)

	i_pr_decouple				: in		std_logic;										-- Partial Configuration Decoupling Enable

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
	o_hwaio_dir					: out		std_logic_vector(31 downto 0)						-- Hardware Accelerator I/O (Direction)
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
--  ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture hwa_core_arch of hwa_core is

	------------------------------------------------------------------------------------------------------------------------------------
	--  COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the Hardware Accelerator
	component hwa is
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
	end component;


	-- Declare the Dynamic Function Xchange (DFX) Decoupler IP Block
	component dfx_decoupler_0_sv is
	port(
		s_hwa_intf_o_hwa_id 		: out 		std_logic_vector(7 downto 0);
		rp_hwa_intf_o_hwa_id 		: in 		std_logic_vector(7 downto 0);

		s_hwa_intf_i_data_A 		: in 		std_logic_vector(31 downto 0);
		rp_hwa_intf_i_data_A		: out		std_logic_vector(31 downto 0);
		s_hwa_intf_i_data_B 		: in 		std_logic_vector(31 downto 0);
		rp_hwa_intf_i_data_B		: out		std_logic_vector(31 downto 0);
		s_hwa_intf_i_data_C 		: in 		std_logic_vector(31 downto 0);
		rp_hwa_intf_i_data_C		: out		std_logic_vector(31 downto 0);
		s_hwa_intf_i_data_D 		: in 		std_logic_vector(31 downto 0);
		rp_hwa_intf_i_data_D		: out		std_logic_vector(31 downto 0);
		s_hwa_intf_i_data_E 		: in 		std_logic_vector(31 downto 0);
		rp_hwa_intf_i_data_E		: out		std_logic_vector(31 downto 0);
		s_hwa_intf_i_data_F 		: in 		std_logic_vector(31 downto 0);
		rp_hwa_intf_i_data_F		: out		std_logic_vector(31 downto 0);
		s_hwa_intf_i_data_G 		: in 		std_logic_vector(31 downto 0);
		rp_hwa_intf_i_data_G		: out		std_logic_vector(31 downto 0);
		s_hwa_intf_i_data_H 		: in 		std_logic_vector(31 downto 0);
		rp_hwa_intf_i_data_H		: out		std_logic_vector(31 downto 0);

		s_hwa_intf_o_data_A 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_data_A		: in		std_logic_vector(31 downto 0);
		s_hwa_intf_o_data_B 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_data_B		: in		std_logic_vector(31 downto 0);
		s_hwa_intf_o_data_C 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_data_C		: in		std_logic_vector(31 downto 0);
		s_hwa_intf_o_data_D 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_data_D		: in		std_logic_vector(31 downto 0);
		s_hwa_intf_o_data_E 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_data_E		: in		std_logic_vector(31 downto 0);
		s_hwa_intf_o_data_F 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_data_F		: in		std_logic_vector(31 downto 0);
		s_hwa_intf_o_data_G 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_data_G		: in		std_logic_vector(31 downto 0);
		s_hwa_intf_o_data_H 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_data_H 		: in		std_logic_vector(31 downto 0);

		s_hwa_intf_i_hwa_ctrl 		: in 		std_logic_vector(7 downto 0);
		rp_hwa_intf_i_hwa_ctrl 		: out		std_logic_vector(7 downto 0);
		s_hwa_intf_o_hwa_stat 		: out		std_logic_vector(15 downto 0);
		rp_hwa_intf_o_hwa_stat 		: in 		std_logic_vector(15 downto 0);

		s_hwa_intf_i_hwaio_in 		: in 		std_logic_vector(31 downto 0);
		rp_hwa_intf_i_hwaio_in 		: out		std_logic_vector(31 downto 0);
		s_hwa_intf_o_hwaio_out 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_hwaio_out 	: in 		std_logic_vector(31 downto 0);
		s_hwa_intf_o_hwaio_dir 		: out		std_logic_vector(31 downto 0);
		rp_hwa_intf_o_hwaio_dir 	: in 		std_logic_vector(31 downto 0);

		decouple 					: in 		std_logic;
		decouple_status 			: out		std_logic
  	);
	end component;


	------------------------------------------------------------------------------------------------------------------------------------
	--  SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_hwa_id					: std_logic_vector(7 downto 0);								-- Hardware Accelerator ID


	signal r_i_data_A				: std_logic_vector(31 downto 0);					-- Input Data A
	signal r_i_data_B				: std_logic_vector(31 downto 0);					-- Input Data B
	signal r_i_data_C				: std_logic_vector(31 downto 0);					-- Input Data C
	signal r_i_data_D				: std_logic_vector(31 downto 0);					-- Input Data D
	signal r_i_data_E				: std_logic_vector(31 downto 0);					-- Input Data E
	signal r_i_data_F				: std_logic_vector(31 downto 0);					-- Input Data F
	signal r_i_data_G				: std_logic_vector(31 downto 0);					-- Input Data G
	signal r_i_data_H				: std_logic_vector(31 downto 0);					-- Input Data H

	signal r_o_data_A				: std_logic_vector(31 downto 0);					-- Output Data A
	signal r_o_data_B				: std_logic_vector(31 downto 0);					-- Output Data B
	signal r_o_data_C				: std_logic_vector(31 downto 0);					-- Output Data C
	signal r_o_data_D				: std_logic_vector(31 downto 0);					-- Output Data D
	signal r_o_data_E				: std_logic_vector(31 downto 0);					-- Output Data E
	signal r_o_data_F				: std_logic_vector(31 downto 0);					-- Output Data F
	signal r_o_data_G				: std_logic_vector(31 downto 0);					-- Output Data G
	signal r_o_data_H				: std_logic_vector(31 downto 0);					-- Output Data H

	signal r_hwa_ctrl				: std_logic_vector(7 downto 0);						-- Hardware Accelerator Control (CTRL)
	signal r_hwa_stat				: std_logic_vector(15 downto 0);					-- Hardware Accelerator Status (STAT)

	signal r_hwaio_in				: std_logic_vector(31 downto 0);					-- Hardware Accelerator I/O (Read)
	signal r_hwaio_out				: std_logic_vector(31 downto 0);					-- Hardware Accelerator I/O (Write)
	signal r_hwaio_dir				: std_logic_vector(31 downto 0);					-- Hardware Accelerator I/O (Direction)


begin

	----------------------------------------------------------------------------------------------------------------------------------------
	--  COMPONENT INSTANTIATIONS
	----------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the Hardware Accelerator
	HWA_00 : hwa
	port map(
		i_clk						=>		i_clk,
		i_reset_n					=>		i_reset_n,

		o_hwa_id					=>		r_hwa_id,			-- o_hwa_id

		i_data_A					=>		r_i_data_A, --i_data_A,
		i_data_B					=>		r_i_data_B, --i_data_B,
		i_data_C					=>		r_i_data_C, --i_data_C,
		i_data_D					=>		r_i_data_D, --i_data_D,
		i_data_E					=>		r_i_data_E, --i_data_E,
		i_data_F					=>		r_i_data_F, --i_data_F,
		i_data_G					=>		r_i_data_G, --i_data_G,
		i_data_H					=>		r_i_data_H, --i_data_H,

		o_data_A					=>		r_o_data_A, --o_data_A,
		o_data_B					=>		r_o_data_B, --o_data_B,
		o_data_C					=>		r_o_data_C, --o_data_C,
		o_data_D					=>		r_o_data_D, --o_data_D,
		o_data_E					=>		r_o_data_E, --o_data_E,
		o_data_F					=>		r_o_data_F, --o_data_F,
		o_data_G					=>		r_o_data_G, --o_data_G,
		o_data_H					=>		r_o_data_H, --o_data_H,

		i_hwa_ctrl					=>		r_hwa_ctrl,	--i_hwa_ctrl,
		o_hwa_stat					=>		r_hwa_stat,	--o_hwa_stat,

		i_hwaio_in					=>		r_hwaio_in, 	--i_hwaio_in,
		o_hwaio_out					=>		r_hwaio_out, 	--o_hwaio_out,
		o_hwaio_dir					=>		r_hwaio_dir 	--o_hwaio_dir
	);


	-- Instantiate the Dynamic Function Xchange (DFX) Decoupler IP Block
	DECOUPLE_00 : dfx_decoupler_0_sv
	port map(
		s_hwa_intf_o_hwa_id 		=> o_hwa_id,
		rp_hwa_intf_o_hwa_id 		=> r_hwa_id,

		s_hwa_intf_i_data_A 		=> i_data_A,
		rp_hwa_intf_i_data_A		=> r_i_data_A,
		s_hwa_intf_i_data_B 		=> i_data_B,
		rp_hwa_intf_i_data_B		=> r_i_data_B,
		s_hwa_intf_i_data_C 		=> i_data_C,
		rp_hwa_intf_i_data_C		=> r_i_data_C,
		s_hwa_intf_i_data_D 		=> i_data_D,
		rp_hwa_intf_i_data_D		=> r_i_data_D,
		s_hwa_intf_i_data_E 		=> i_data_E,
		rp_hwa_intf_i_data_E		=> r_i_data_E,
		s_hwa_intf_i_data_F 		=> i_data_F,
		rp_hwa_intf_i_data_F		=> r_i_data_F,
		s_hwa_intf_i_data_G 		=> i_data_G,
		rp_hwa_intf_i_data_G		=> r_i_data_G,
		s_hwa_intf_i_data_H 		=> i_data_H,
		rp_hwa_intf_i_data_H		=> r_i_data_H,

		s_hwa_intf_o_data_A 		=> o_data_A,
		rp_hwa_intf_o_data_A		=> r_o_data_A,
		s_hwa_intf_o_data_B 		=> o_data_B,
		rp_hwa_intf_o_data_B		=> r_o_data_B,
		s_hwa_intf_o_data_C 		=> o_data_C,
		rp_hwa_intf_o_data_C		=> r_o_data_C,
		s_hwa_intf_o_data_D 		=> o_data_D,
		rp_hwa_intf_o_data_D		=> r_o_data_D,
		s_hwa_intf_o_data_E 		=> o_data_E,
		rp_hwa_intf_o_data_E		=> r_o_data_E,
		s_hwa_intf_o_data_F 		=> o_data_F,
		rp_hwa_intf_o_data_F		=> r_o_data_F,
		s_hwa_intf_o_data_G 		=> o_data_G,
		rp_hwa_intf_o_data_G		=> r_o_data_G,
		s_hwa_intf_o_data_H 		=> o_data_H,
		rp_hwa_intf_o_data_H 		=> r_o_data_H,

		s_hwa_intf_i_hwa_ctrl 		=> i_hwa_ctrl,
		rp_hwa_intf_i_hwa_ctrl 		=> r_hwa_ctrl,
		s_hwa_intf_o_hwa_stat 		=> o_hwa_stat,
		rp_hwa_intf_o_hwa_stat 		=> r_hwa_stat,

		s_hwa_intf_i_hwaio_in 		=> i_hwaio_in,
		rp_hwa_intf_i_hwaio_in 		=> r_hwaio_in,
		s_hwa_intf_o_hwaio_out 		=> o_hwaio_out,
		rp_hwa_intf_o_hwaio_out 	=> r_hwaio_out,
		s_hwa_intf_o_hwaio_dir 		=> o_hwaio_dir,
		rp_hwa_intf_o_hwaio_dir 	=> r_hwaio_dir,

		decouple 					=> i_pr_decouple,
		decouple_status 			=> open
  	);


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
--  END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------
