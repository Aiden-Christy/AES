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

	-- Key declatration
	constant KEY : std_logic_vector(255 downto 0) := x"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4";

	component AES is	
		port(
			 	i_clk     : in std_logic;
    			i_reset_n : in std_logic;   -- active low

    			key_load  : in  std_logic;
    			key_valid : out std_logic;

    			in_valid : in std_logic;    
    			out_valid: out std_logic;

    			plaintext : in std_logic_vector(127 downto 0);
    			cipherkey : in std_logic_vector(255 downto 0);

    			ciphertext : out std_logic_vector(127 downto 0)
	);
	end component;

	component decrypt is 
		port(
				i_clk       : in std_logic;
    			i_reset_n   : in std_logic;   -- active low

    			key_load    : in  std_logic;
    			key_valid   : out std_logic;

    			in_valid    : in std_logic;    
    			out_valid   : out std_logic;

    			ciphertext  : in std_logic_vector(127 downto 0);
    			cipherkey   : in std_logic_vector(255 downto 0);

    			plaintext   : out std_logic_vector(127 downto 0)
	);
	end component;

	-- Signals

	-- Internal signals for both
	signal key_load 	: std_logic;
	signal in_valid		: std_logic;

	-- Encryption internal signals
	signal key_valid_e 		: std_logic;
	signal out_valid_e 		: std_logic;
	signal plaintext_in 	: std_logic_vector(127 downto 0);
	signal ciphertext_out	: std_logic_vector(127 downto 0);

	-- Decryption internal signals
	signal key_valid_d	 	: std_logic;
	signal out_valid_d 		: std_logic;
	signal ciphertext_in	: std_logic_vector(127 downto 0);
	signal plaintext_out	: std_logic_vector(127 downto 0);


	-- key load logic
	signal key_pulse : std_logic := '0';


begin



	encryption : AES
		port map(
			i_clk 		=> i_clk,
			i_reset_n	=> i_reset_n,
			key_load 	=> key_load,
			key_valid 	=> key_valid_e,
			in_valid	=> in_valid,
			out_valid	=> out_valid_e,
			plaintext	=> plaintext_in,
			cipherkey	=> KEY,
			ciphertext	=> ciphertext_out
	);

	decryption : decrypt
		port map(
			i_clk 		=> i_clk,
			i_reset_n	=> i_reset_n,
			key_load 	=> key_load,
			key_valid 	=> key_valid_d,
			in_valid	=> in_valid,
			out_valid	=> out_valid_d,
			ciphertext	=> ciphertext_in,
			cipherkey	=> KEY,
			plaintext	=> plaintext_out
	);

	key_init : process(i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				key_pulse <= '0';
				key_load  <= '0';
			elsif key_pulse = '0' then
				key_load <= '1';
				key_pulse <= '1';
			else 
				key_load <= '0';
			end if;
		end if;
	end process;

	mode_select : process(i_clk)
	begin
		if rising_edge(i_clk) then
			if i_reset_n = '0' then
				o_data_A <= (others => '0');
				o_data_B <= (others => '0');
				o_data_C <= (others => '0');
				o_data_D <= (others => '0');
				o_data_E <= (others => '0');
				o_data_F <= (others => '0');
				o_data_G <= (others => '0');
				o_data_H <= (others => '0');
			else

				case i_hwa_ctrl is
					when "00000000" =>
						in_valid <= '0';

						o_data_A <= (others => '0');
						o_data_B <= (others => '0');
						o_data_C <= (others => '0');
						o_data_D <= (others => '0');
						o_data_E <= (others => '0');
						o_data_F <= (others => '0');
						o_data_G <= (others => '0');
						o_data_H <= (others => '0');

						o_hwa_stat <= "00000000";
					when "00000001" =>

						plaintext_in <= i_data_A & i_data_B & i_data_C & i_data_D;

						in_valid <= i_data_H(0);

						o_data_A <= ciphertext_out(127 downto 96);
						o_data_B <= ciphertext_out(95 downto 64);
						o_data_C <= ciphertext_out(63 downto 32);
						o_data_D <= ciphertext_out(31 downto 0);

						o_data_H(1 downto 0) <= out_valid_e & key_valid_e;

						o_hwa_stat <= "00000001";
					when "00000010" =>

						ciphertext_in <= i_data_A & i_data_B & i_data_C & i_data_D;

						in_valid <= i_data_H(0);

						o_data_A <= plaintext_out(127 downto 96);
						o_data_B <= plaintext_out(95 downto 64);
						o_data_C <= plaintext_out(63 downto 32);
						o_data_D <= plaintext_out(31 downto 0);

						o_data_H(1 downto 0) <= out_valid_d & key_valid_d;

						o_hwa_stat <= "00000010";
					when others =>
						o_data_A <= (others => '0');
						o_data_B <= (others => '0');
						o_data_C <= (others => '0');
						o_data_D <= (others => '0');
						o_data_E <= (others => '0');
						o_data_F <= (others => '0');
						o_data_G <= (others => '0');
						o_data_H <= (others => '0');

						o_hwa_stat <= "11111111";
				end case;
			end if;
		end if;
	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--	SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	-- [ASSIGN SIGNALS HERE]


	-- [ALL HARDWARE ACCELERATORS MUST HAVE A UNIQUE ASSIGNED ID]
	-- [ID 00 IS RESERVED FOR EMPTY HWA PBLOCK SPACE]
	o_hwa_id <= x"69";

	o_hwaio_out <= (others => '0');
	o_hwaio_dir <= (others => '0');
	


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
--	END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------