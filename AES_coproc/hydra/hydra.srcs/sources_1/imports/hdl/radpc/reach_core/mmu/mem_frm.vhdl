----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--	REACH PROCESSOR CORE MEMORY MANAGEMENT
-- 	FAULT RECOVERY MECHANISM (FRM) MEMORY INTERFACE
--
--	Created by Chris Major
-- 	Resilient Computing
-- 	10/30/2025
--
--	A memory-mapped component for reading RadPC's reports from various fault mitigation systems
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
entity mem_frm is
	port(
		i_clk						: in	std_logic;												-- Input Clock
		i_reset_n					: in	std_logic;												-- Active Low Reset

		i_cpu_addr					: in 	std_logic_vector(31 downto 0);						    -- CPU Address
		i_cpu_dw					: in	std_logic_vector(2 downto 0);							-- CPU Data Width (DW)
		i_cpu_rw					: in	std_logic;												-- CPU Read/Write (RW))
		i_cpu_wr					: in 	std_logic_vector(31 downto 0);							-- CPU Memory Write (WR)
		o_cpu_rd					: out	std_logic_vector(31 downto 0);							-- CPU Memory Read (RD)

		i_sem_stat					: in 	std_logic_vector(7 downto 0);							-- SEM Status Register
		i_arbiter_stat				: in 	std_logic_vector(7 downto 0);							-- Arbiter Status Register
		i_monitor_stat				: in 	std_logic_vector(7 downto 0);							-- Monitor Status Register
		i_imem_scrubber_stat		: in 	std_logic_vector(7 downto 0);							-- IMEM Scrubber Status Register
		i_dmem_scrubber_stat		: in 	std_logic_vector(7 downto 0);							-- DMEM Scrubber Status Register
		i_bootrom_stat				: in 	std_logic_vector(7 downto 0);							-- BOOTROM Scrubber Status Register

		o_index						: out	std_logic_vector(7 downto 0);							-- Event Index
		i_event						: in	std_logic_vector(31 downto 0)							-- Event Data (Read)
	);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture mem_frm_arch of mem_frm is

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Declare the memory data routing component
	component bytewise_route is
	generic(
		g_MAX_MEM_ADDR				: integer	:= 1024
	);
	port (
		i_addr						: in 	std_logic_vector(31 downto 0);
		i_rw_en						: in	std_logic;
		i_data_width				: in	std_logic_vector(2 downto 0);

		i_data_write				: in    std_logic_vector(31 downto 0);

		i_cell_read_00				: in	std_logic_vector(7 downto 0);
		i_cell_read_01				: in	std_logic_vector(7 downto 0);
		i_cell_read_02				: in	std_logic_vector(7 downto 0);
		i_cell_read_03				: in	std_logic_vector(7 downto 0);

		o_cell_addr_00				: out 	std_logic_vector(31 downto 0);
		o_cell_addr_01				: out 	std_logic_vector(31 downto 0);
		o_cell_addr_02				: out 	std_logic_vector(31 downto 0);
		o_cell_addr_03				: out 	std_logic_vector(31 downto 0);

		o_cell_rw_00				: out	std_logic;
		o_cell_rw_01				: out	std_logic;
		o_cell_rw_02				: out	std_logic;
		o_cell_rw_03				: out	std_logic;

		o_cell_write_00				: out	std_logic_vector(7 downto 0);
		o_cell_write_01				: out	std_logic_vector(7 downto 0);
		o_cell_write_02				: out	std_logic_vector(7 downto 0);
		o_cell_write_03				: out	std_logic_vector(7 downto 0);

		o_data_read					: out	std_logic_vector(31 downto 0)
	);
	end component;


	------------------------------------------------------------------------------------------------------------------------------------
	-- CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	constant c_ADDR_SPACE				: integer							:= 28;

	constant c_LOG_INDEX				: std_logic_vector(29 downto 0)		:= "00" & x"0000000";			-- Log Index
	constant c_LOG_EVENT				: std_logic_vector(29 downto 0)		:= "00" & x"0000001";			-- Log Event 
	constant c_SEM_STAT_RD				: std_logic_vector(29 downto 0)		:= "00" & x"0000002";			-- SEM Status Register Address
	constant c_ARB_STAT_RD				: std_logic_vector(29 downto 0)		:= "00" & x"0000003";			-- Arbiter Status Register Address
	constant c_MON_STAT_RD				: std_logic_vector(29 downto 0)		:= "00" & x"0000004";			-- Monitor Status Register Address
	constant c_MEM_STAT_RD				: std_logic_vector(29 downto 0)		:= "00" & x"0000005";			-- Memory Scrubbers Status Register Address
	constant c_ROM_STAT_RD				: std_logic_vector(29 downto 0)		:= "00" & x"0000006";			-- BOOTROM Scrubber Status Register Address


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_addr_mem_00				: std_logic_vector(31 downto 0);							-- Memory Device 00 Address
	signal r_addr_mem_01				: std_logic_vector(31 downto 0);							-- Memory Device 01 Address
	signal r_addr_mem_02				: std_logic_vector(31 downto 0);							-- Memory Device 02 Address
	signal r_addr_mem_03				: std_logic_vector(31 downto 0);							-- Memory Device 03 Address

	signal r_data_in_mem_00				: std_logic_vector(7 downto 0);						    	-- Memory Device Data In 00
	signal r_data_in_mem_01				: std_logic_vector(7 downto 0);						    	-- Memory Device Data In 01
	signal r_data_in_mem_02				: std_logic_vector(7 downto 0);						    	-- Memory Device Data In 02
	signal r_data_in_mem_03				: std_logic_vector(7 downto 0);						    	-- Memory Device Data In 03

	signal r_data_out_mem_00			: std_logic_vector(7 downto 0);						    	-- Memory Device Data Out 00
	signal r_data_out_mem_01			: std_logic_vector(7 downto 0);						    	-- Memory Device Data Out 01
	signal r_data_out_mem_02			: std_logic_vector(7 downto 0);						    	-- Memory Device Data Out 02
	signal r_data_out_mem_03			: std_logic_vector(7 downto 0);						    	-- Memory Device Data Out 03

	signal w_rw_mem_00					: std_logic;												-- Memory Device Read/Write 00
	signal w_rw_mem_01					: std_logic;												-- Memory Device Read/Write 01
	signal w_rw_mem_02					: std_logic;												-- Memory Device Read/Write 02
	signal w_rw_mem_03					: std_logic;												-- Memory Device Read/Write 03

	signal w_clear_sem					: std_logic;												-- Clear Latched SEM Data
	signal r_sem_stat					: std_logic_vector(7 downto 0);								-- SEM Latched Data

	signal r_index						: std_logic_vector(7 downto 0);								-- Log Index


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- COMPONENT INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate Memory Data Routing
	DATA_ROUTE_00 : bytewise_route
	generic map (
		g_MAX_MEM_ADDR					=> c_ADDR_SPACE
	)
	port map (
		i_addr							=> i_cpu_addr,
		i_rw_en							=> i_cpu_rw,
		i_data_width					=> i_cpu_dw,

		i_data_write					=> i_cpu_wr,

		i_cell_read_00					=> r_data_out_mem_00,
		i_cell_read_01					=> r_data_out_mem_01,
		i_cell_read_02					=> r_data_out_mem_02,
		i_cell_read_03					=> r_data_out_mem_03,

		o_cell_addr_00					=> r_addr_mem_00,
		o_cell_addr_01					=> r_addr_mem_01,
		o_cell_addr_02					=> r_addr_mem_02,
		o_cell_addr_03					=> r_addr_mem_03,

		o_cell_rw_00					=> w_rw_mem_00,
		o_cell_rw_01					=> w_rw_mem_01,
		o_cell_rw_02					=> w_rw_mem_02,
		o_cell_rw_03					=> w_rw_mem_03,

		o_cell_write_00					=> r_data_in_mem_00,
		o_cell_write_01					=> r_data_in_mem_01,
		o_cell_write_02					=> r_data_in_mem_02,
		o_cell_write_03					=> r_data_in_mem_03,

		o_data_read						=> o_cpu_rd
	);


	------------------------------------------------------------------------------------------------------------------------------------
	-- MEMORY READ/WRITE
	------------------------------------------------------------------------------------------------------------------------------------

	-- READ/WRITE to Memory Device 00
	MEM_WRITE_00 : process( i_clk, i_reset_n )
	begin

		-- On Reset ...
		if( i_reset_n = '0' ) then

			-- Reset all values
			r_index				<= x"00";

			r_data_out_mem_00 	<= x"00";


		-- On Rising Clock Edge ...
		elsif( rising_edge( i_clk )) then

			-- On WRITE condition ...
			if( w_rw_mem_00 = '1' ) then

				-- Check the address to read
				case( r_addr_mem_00(29 downto 0) ) is

					-- Log Index Register Address
					when c_LOG_INDEX			=>	r_index				<= r_data_in_mem_00;

					-- Log Event Register Address
					when c_LOG_EVENT			=>	-- (No Write)

					-- SEM Status Register Address
					when c_SEM_STAT_RD			=> 	-- (No Write)

					-- Arbiter Status Register Address
					when c_ARB_STAT_RD			=> 	-- (No Write)

					-- Monitor Status Register Address
					when c_MON_STAT_RD			=> 	-- (No Write)

					-- Memory Scrubbers Status Register Address
					when c_MEM_STAT_RD			=> 	-- (No Write)

					-- BOOTROM Scrubber Status Register Address
					when c_ROM_STAT_RD			=> 	-- (No Write)

					-- (Default)
					when others					=> 	-- (Do Nothing)

				end case;

			-- On READ Condition ...
			else

				-- Check the address to read
				case( r_addr_mem_00(29 downto 0) ) is

					-- Log Index Register Address
					when c_LOG_INDEX			=>	r_data_out_mem_00	<= r_index;

					-- Log Event Register Address
					when c_LOG_EVENT			=>	r_data_out_mem_00	<= i_event(7 downto 0);

					-- SEM Status Register Address
					when c_SEM_STAT_RD			=> 	r_data_out_mem_00 	<= i_sem_stat;

					-- Arbiter Status Register Address
					when c_ARB_STAT_RD			=> 	r_data_out_mem_00 	<= i_arbiter_stat;

					-- Monitor Status Register Address
					when c_MON_STAT_RD			=> 	r_data_out_mem_00 	<= i_monitor_stat;

					-- Memory Scrubbers Status Register Address
					when c_MEM_STAT_RD			=> 	r_data_out_mem_00 	<= i_dmem_scrubber_stat;

					-- BOOTROM Scrubber Status Register Address
					when c_ROM_STAT_RD			=> 	r_data_out_mem_00 	<= i_bootrom_stat;

					-- (Default)
					when others					=> 	r_data_out_mem_00 	<= x"00";

				end case;

			end if;

		end if;

	end process;		


	-- READ/WRITE to Memory Device 01
	MEM_WRITE_01 : process( i_clk, i_reset_n )
	begin

		-- On Reset ...
		if( i_reset_n = '0' ) then

			-- Reset all values
			r_data_out_mem_01 	<= x"00";


		-- On Rising Clock Edge ...
		elsif( rising_edge( i_clk )) then

			-- On WRITE condition ...
			if( w_rw_mem_01 = '1' ) then

				-- Check the address to read
				case( r_addr_mem_01(29 downto 0) ) is

					-- Log Index Register Address
					when c_LOG_INDEX			=>	-- (No Write)

					-- Log Event Register Address
					when c_LOG_EVENT			=>	-- (No Write)

					-- SEM Status Register Address
					when c_SEM_STAT_RD			=> 	-- (No Write)

					-- Arbiter Status Register Address
					when c_ARB_STAT_RD			=> 	-- (No Write)

					-- Monitor Status Register Address
					when c_MON_STAT_RD			=> 	-- (No Write)

					-- Memory Scrubbers Status Register Address
					when c_MEM_STAT_RD			=> 	-- (No Write)

					-- BOOTROM Scrubber Status Register Address
					when c_ROM_STAT_RD			=> 	-- (No Write)

					--- (Default)
					when others					=> 	-- (Do Nothing)

				end case;

			-- On READ Condition ...
			else

				-- Check the address to read
				case( r_addr_mem_01(29 downto 0) ) is

					-- Log Index Register Address
					when c_LOG_INDEX			=>	r_data_out_mem_01	<= x"00";

					-- Log Event Register Address
					when c_LOG_EVENT			=>	r_data_out_mem_01	<= i_event(15 downto 8);

					-- SEM Status Register Address
					when c_SEM_STAT_RD			=> 	r_data_out_mem_01	<= r_sem_stat;

					-- Arbiter Status Register Address
					when c_ARB_STAT_RD			=> 	r_data_out_mem_01	<= x"00";

					-- Monitor Status Register Address
					when c_MON_STAT_RD			=> 	r_data_out_mem_01	<= x"00";

					-- Memory Scrubbers Status Register Address
					when c_MEM_STAT_RD			=> 	r_data_out_mem_01	<= x"00";

					-- BOOTROM Scrubber Status Register Address
					when c_ROM_STAT_RD			=> 	r_data_out_mem_01	<= x"00";

					-- (Default)
					when others					=> 	r_data_out_mem_01	<= x"00";

				end case;

			end if;

		end if;

	end process;		


	-- READ/WRITE to Memory Device 02
	MEM_WRITE_02 : process( i_clk, i_reset_n )
	begin

		-- On Reset ...
		if( i_reset_n = '0' ) then

			-- Reset all values
			r_data_out_mem_02 	<= x"00";


		-- On Rising Clock Edge ...
		elsif( rising_edge( i_clk )) then

			-- On WRITE condition ...
			if( w_rw_mem_02 = '1' ) then

				-- Check the address to read
				case( r_addr_mem_02(29 downto 0) ) is

					-- Log Index Register Address
					when c_LOG_INDEX			=>	-- (No Write)

					-- Log Event Register Address
					when c_LOG_EVENT			=>	-- (No Write)

					-- SEM Status Register Address
					when c_SEM_STAT_RD			=> 	-- (No Write)

					-- Arbiter Status Register Address
					when c_ARB_STAT_RD			=> 	-- (No Write)

					-- Monitor Status Register Address
					when c_MON_STAT_RD			=> 	-- (No Write)

					-- Memory Scrubbers Status Register Address
					when c_MEM_STAT_RD			=> 	-- (No Write)

					-- BOOTROM Scrubber Status Register Address
					when c_ROM_STAT_RD			=> 	-- (No Write)

					--- (Default)
					when others					=> 	-- (Do Nothing)

				end case;

			-- On READ Condition ...
			else

				-- Check the address to read
				case( r_addr_mem_02(29 downto 0) ) is

					-- Log Index Register Address
					when c_LOG_INDEX			=>	r_data_out_mem_02	<= x"00";

					-- Log Event Register Address
					when c_LOG_EVENT			=>	r_data_out_mem_02	<= i_event(23 downto 16);

					-- SEM Status Register Address
					when c_SEM_STAT_RD			=> 	r_data_out_mem_02	<= x"00";

					-- Arbiter Status Register Address
					when c_ARB_STAT_RD			=> 	r_data_out_mem_02	<= x"00";

					-- Monitor Status Register Address
					when c_MON_STAT_RD			=> 	r_data_out_mem_02	<= x"00";

					-- Memory Scrubbers Status Register Address
					when c_MEM_STAT_RD			=> 	r_data_out_mem_02	<= x"00";

					-- BOOTROM Scrubber Status Register Address
					when c_ROM_STAT_RD			=> 	r_data_out_mem_02	<= x"00";

					-- (Default)
					when others					=> 	r_data_out_mem_02	<= x"00";

				end case;

			end if;

		end if;

	end process;


	-- READ/WRITE to Memory Device 03
	MEM_WRITE_03 : process( i_clk, i_reset_n )
	begin

		-- On Reset ...
		if( i_reset_n = '0' ) then

			-- Reset all values
			r_data_out_mem_03 	<= x"00";


		-- On Rising Clock Edge ...
		elsif( rising_edge( i_clk )) then

			-- On WRITE condition ...
			if( w_rw_mem_03 = '1' ) then

				-- Check the address to read
				case( r_addr_mem_03(29 downto 0) ) is

					-- Log Index Register Address
					when c_LOG_INDEX			=>	-- (No Write)

					-- Log Event Register Address
					when c_LOG_EVENT			=>	-- (No Write)

					-- SEM Status Register Address
					when c_SEM_STAT_RD			=> 	w_clear_sem			<= r_data_in_mem_03(0);

					-- Arbiter Status Register Address
					when c_ARB_STAT_RD			=> 	-- (No Write)

					-- Monitor Status Register Address
					when c_MON_STAT_RD			=> 	-- (No Write)

					-- Memory Scrubbers Status Register Address
					when c_MEM_STAT_RD			=> 	-- (No Write)

					-- BOOTROM Scrubber Status Register Address
					when c_ROM_STAT_RD			=> 	-- (No Write)

					--- (Default)
					when others					=> 	-- (Do Nothing)

				end case;

			-- On READ Condition ...
			else

				-- Check the address to read
				case( r_addr_mem_01(29 downto 0) ) is

					-- Log Index Register Address
					when c_LOG_INDEX			=>	r_data_out_mem_03	<= x"00";

					-- Log Event Register Address
					when c_LOG_EVENT			=>	r_data_out_mem_03	<= i_event(31 downto 24);

					-- SEM Status Register Address
					when c_SEM_STAT_RD			=> 	r_data_out_mem_03	<= "0000000" & w_clear_sem;

					-- Arbiter Status Register Address
					when c_ARB_STAT_RD			=> 	r_data_out_mem_03	<= x"00";

					-- Monitor Status Register Address
					when c_MON_STAT_RD			=> 	r_data_out_mem_03	<= x"00";

					-- Memory Scrubbers Status Register Address
					when c_MEM_STAT_RD			=> 	r_data_out_mem_03	<= x"00";

					-- BOOTROM Scrubber Status Register Address
					when c_ROM_STAT_RD			=> 	r_data_out_mem_03	<= x"00";

					-- (Default)
					when others					=> 	r_data_out_mem_03	<= x"00";

				end case;

			end if;

		end if;

	end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SEM LATCHING
	------------------------------------------------------------------------------------------------------------------------------------

	-- Process to latch any SEM data that indicates an error
	SEM_LATCH_PROC : process( i_clk, i_reset_n )
	begin

		-- On Reset ...
		if( i_reset_n = '1' ) then

			-- Reset the SEM Status register
			r_sem_stat	<= x"00";

		-- On Clock Edge ...
		elsif( rising_edge(i_clk) ) then

			-- Clear the SEM Status register with a signal
			if( w_clear_sem = '1' ) then

				r_sem_stat	<= x"00";

			-- Latch the SEM data when the Correction Bit is set
			elsif( i_sem_stat(3) = '1') then

				r_sem_stat	<= i_sem_stat;

			-- Latch the SEM data when the Classification Bit is set
			elsif( i_sem_stat(4) = '1') then

				r_sem_stat	<= i_sem_stat;

			-- Latch the SEM data when the Uncorrectable Bit is set
			elsif( i_sem_stat(7) = '1') then

				r_sem_stat	<= i_sem_stat;

			end if;

		end if;

	end process;



	o_index <= r_index;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------