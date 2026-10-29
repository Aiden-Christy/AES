-----------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC 
--  ERROR MITIGATION MONITOR
--
--	CREATED BY CHRIS MAJOR
--  RESILIENT COMPUTING
-- 	06/16/2025
--
--  The RadPC Monitor oversees all runtime signals reported by each RadPC Reach core and determines errors
--
--  "Looking back, we should have done a few things differently. For one thing, we should have installed two caretakers per 
--  installation ..."
--      - 343 Guilty Spark
--
-----------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------------
--  LIBRARIES
-----------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	-- IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;

	-- IEEE Numeric Standard Library
	use IEEE.NUMERIC_STD.ALL;


-----------------------------------------------------------------------------------------------------------------------------------
--  ENTITY
-----------------------------------------------------------------------------------------------------------------------------------
entity monitor is
port (
	i_clk								: in	std_logic;										-- Clock
	i_reset_n							: in	std_logic;										-- Active Low Reset

    i_radpc_active_00                   : in    std_logic;										--! RadPC Active Flag (Tile 00)
	i_radpc_active_01                   : in    std_logic;										--! RadPC Active Flag (Tile 01)
	i_radpc_active_02                   : in    std_logic;										--! RadPC Active Flag (Tile 02)
	i_radpc_active_03                   : in    std_logic;										--! RadPC Active Flag (Tile 03)

	i_pc_00                             : in    std_logic_vector(31 downto 0); 					--! Program Count (Tile 00)
	i_pc_01                             : in    std_logic_vector(31 downto 0); 					--! Program Count (Tile 01)
	i_pc_02                             : in    std_logic_vector(31 downto 0); 					--! Program Count (Tile 02)
	i_pc_03                             : in    std_logic_vector(31 downto 0); 					--! Program Count (Tile 03)

    i_illegal_opcode_00             	: in    std_logic;										--! Illegal Opcode Flag (Tile 00)
	i_illegal_opcode_01             	: in    std_logic;										--! Illegal Opcode Flag (Tile 01)
	i_illegal_opcode_02             	: in    std_logic;										--! Illegal Opcode Flag (Tile 02)
	i_illegal_opcode_03             	: in    std_logic;										--! Illegal Opcode Flag (Tile 03)

    i_runtime_stat_00               	: in    std_logic_vector(31 downto 0);			        --! Runtime Status (Tile 00)
	i_runtime_stat_01               	: in    std_logic_vector(31 downto 0);			        --! Runtime Status (Tile 01)
	i_runtime_stat_02               	: in    std_logic_vector(31 downto 0);			        --! Runtime Status (Tile 02)
	i_runtime_stat_03               	: in    std_logic_vector(31 downto 0);			        --! Runtime Status (Tile 03)

	i_instr_00				    	    : in    std_logic_vector(31 downto 0);					--! Current Instruction (Tile 00)
	i_instr_01				    	    : in    std_logic_vector(31 downto 0);					--! Current Instruction (Tile 01)
	i_instr_02				    	    : in    std_logic_vector(31 downto 0);					--! Current Instruction (Tile 02)
	i_instr_03				    	    : in    std_logic_vector(31 downto 0);					--! Current Instruction (Tile 03)

    o_radpc_active                      : out   std_logic;                                      --! RadPC Active Flag (Voted)
    o_pc                                : out   std_logic_vector(31 downto 0);                  --! Illegal Opcode Flag (Voted)
    o_illegal_opcode                    : out   std_logic;                                      --! Runtime Status (Voted)
    o_runtime_stat                      : out   std_logic_vector(31 downto 0);                  --! Program Count (Voted)
    o_instr				                : out   std_logic_vector(31 downto 0);                  --! Current Instruction (Voted)

    o_monitor_stat                    : out   std_logic_vector(7 downto 0)                   	--! Monitor Status Flags
);
end entity;


-----------------------------------------------------------------------------------------------------------------------------------
--  ARCHITECTURE
-----------------------------------------------------------------------------------------------------------------------------------
architecture monitor_arch of monitor is

    -------------------------------------------------------------------------------------------------------------------------------
    --  COMPONENT DECLARATIONS
    -------------------------------------------------------------------------------------------------------------------------------

    -- Declare the Voter component
	component voter is
	generic(
		g_VOTE_SIZE                 : integer       := 8
	);
	port(
		i_val_00                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
		i_val_01                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
		i_val_02                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
		i_val_03                    : in    std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
	
		o_result                    : out   std_logic_vector( (g_VOTE_SIZE - 1) downto 0 );
		o_syndrome                  : out   std_logic_vector( 3 downto 0 )
	);
    end component;


    -------------------------------------------------------------------------------------------------------------------------------
    --  SIGNAL DECLARATIONS
    -------------------------------------------------------------------------------------------------------------------------------

    signal r_radpc_active_syn           : std_logic_vector(3 downto 0);                       	-- RadPC Active Syndrome Flags
    signal r_pc_syn                     : std_logic_vector(3 downto 0);                       	-- Program Count Syndrome Flags
    signal r_illegal_opcode_syn         : std_logic_vector(3 downto 0);                       	-- Illegal Opcode Syndrome Flags
    signal r_runtime_stat_syn           : std_logic_vector(3 downto 0);                       	-- Runtime Status Syndrome Flags
    signal r_instr_syn                  : std_logic_vector(3 downto 0);                       	-- Instruction Syndrome Flags

	signal w_mismatch_detect			: std_logic_vector(1 downto 0);							-- Tile Mismatch Flags
	signal w_mismatch_tiles				: std_logic_vector(3 downto 0);							-- Tile Mismatch Identifiers


	--signal r_tile_diagnose				: std_logic_vector( 3 downto 0 );                       --! Tile Diagnostic Flags 

begin

    -- Instantiate the Voter component for the RadPC Active Flag
    RADPC_ACTIVE_00 : voter
	generic map (
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => i_radpc_active_00,
		i_val_01(0)                 => i_radpc_active_01,
		i_val_02(0)                 => i_radpc_active_02,
		i_val_03(0)                 => i_radpc_active_03,
	
		o_result(0)                 => o_radpc_active,
		o_syndrome                  => r_radpc_active_syn
	);


    -- Instantiate the Voter component for the Program Count
    PROGRAM_COUNT_00 : voter
	generic map (
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => i_pc_00,
		i_val_01                    => i_pc_01,
		i_val_02                    => i_pc_02,
		i_val_03                    => i_pc_03,
	
		o_result                    => o_pc,
		o_syndrome                  => r_pc_syn 
	);


    -- Instantiate the Voter component for the Illegal Opcode Flag
    ILLEGAL_OPCODE_00 : voter
	generic map (
		g_VOTE_SIZE                 => 1
	)
	port map(
		i_val_00(0)                 => i_illegal_opcode_00,
		i_val_01(0)                 => i_illegal_opcode_01,
		i_val_02(0)                 => i_illegal_opcode_02,
		i_val_03(0)                 => i_illegal_opcode_03,
	
		o_result(0)                 => o_illegal_opcode,
		o_syndrome                  => r_illegal_opcode_syn 
	);


    -- Instantiate the Voter component for the Runtime Status
    RUNTIME_STATUS_00 : voter
	generic map (
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => i_runtime_stat_00,
		i_val_01                    => i_runtime_stat_01,
		i_val_02                    => i_runtime_stat_02,
		i_val_03                    => i_runtime_stat_03,
	
		o_result                    => o_runtime_stat,
		o_syndrome                  => r_runtime_stat_syn 
	);


    -- Instantiate the Voter component for the Instruction
    INSTR_00 : voter
	generic map (
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => i_instr_00,
		i_val_01                    => i_instr_01,
		i_val_02                    => i_instr_02,
		i_val_03                    => i_instr_03,
	
		o_result                    => o_instr,
		o_syndrome                  => r_instr_syn 
	);


	-- Assign syndrome signals to tile diagnosis signal
	MONITOR_STAT : process( i_clk, i_reset_n )
	begin

		-- On reset ...
		if( i_reset_n = '0' ) then

			w_mismatch_detect		<= "00";
			w_mismatch_tiles		<= "0000";


		-- On rising clock edge
		elsif( rising_edge( i_clk )) then

			case( r_pc_syn ) is

				-- Tile 03/02 Mismatch
				when "1100"	=> 	w_mismatch_detect		<= "10";
								w_mismatch_tiles		<= r_pc_syn;		

				-- Tile 03/01 Mismatch
				when "1010"	=> 	w_mismatch_detect		<= "10";
								w_mismatch_tiles		<= r_pc_syn;			

				-- Tile 03/00 Mismatch
				when "1001"	=> 	w_mismatch_detect		<= "10";
								w_mismatch_tiles		<= r_pc_syn;

				-- Tile 02/01 Mismatch
				when "0110"	=> 	w_mismatch_detect		<= "10";
								w_mismatch_tiles		<= r_pc_syn;		

				-- Tile 02/00 Mismatch
				when "0101"	=> 	w_mismatch_detect		<= "10";
								w_mismatch_tiles		<= r_pc_syn;		

				-- Tile 01/00 Mismatch
				when "0011"	=> 	w_mismatch_detect		<= "10";
								w_mismatch_tiles		<= r_pc_syn;		

				-- Tile 03 Mismatch
				when "1000"	=> 	w_mismatch_detect		<= "01";
								w_mismatch_tiles		<= r_pc_syn;		

				-- Tile 02 Mismatch
				when "0100"	=> 	w_mismatch_detect		<= "01";
								w_mismatch_tiles		<= r_pc_syn;	

				-- Tile 01 Mismatch
				when "0010"	=> 	w_mismatch_detect		<= "01";
								w_mismatch_tiles		<= r_pc_syn;		

				-- Tile 00 Mismatch
				when "0001"	=> 	w_mismatch_detect		<= "01";
								w_mismatch_tiles		<= r_pc_syn;		

				-- Total Agreement
				when "0000"	=> 	w_mismatch_detect		<= "00";
								w_mismatch_tiles		<= r_pc_syn;

				-- Total Mismatch 
				when others => 	w_mismatch_detect		<= "11";
								w_mismatch_tiles		<= r_pc_syn;															


			end case;

		end if;

	end process;


	o_monitor_stat <= w_mismatch_tiles & "00" & w_mismatch_detect;


end architecture;
-----------------------------------------------------------------------------------------------------------------------------------
--  END OF CODE
-----------------------------------------------------------------------------------------------------------------------------------