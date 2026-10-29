-------------------------------------------------------------------------------------------------------------------------------
--	
--	RADPC
--	SCRUBBER COMPONENT
--	
--	ENGINEER:		CHRIS MAJOR
--	COMPANY:		RESILIENT COMPUTING
--	DATE:			09/15/2025
--	
--	A COMPONENT FOR SCRUBBING MEMORY DEVICES WITHIN RADPC
--	
-------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------
--	LIBRARIES
-------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	-- IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;


-------------------------------------------------------------------------------------------------------------------------------
--	ENTITY
-------------------------------------------------------------------------------------------------------------------------------
entity scrubber is
	generic (
		g_CLK_RATE      : integer       := 100_000_000;										-- Expected Input Clock Rate
		g_DATA_WIDTH	: integer		:= 0;												-- Data Width
		g_ADDR_WIDTH	: integer		:= 0;												-- Address Width
		g_RAM_DEPTH		: integer		:= 0												-- Depth of RAM Array
	);
	port (
		i_clk			: in	std_logic;													-- Input Clock
		i_reset_n		: in 	std_logic;													-- Reset (Active Low)

		i_en 			: in 	std_logic;													-- Enable

		i_data_rd_00	: in	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Read Data 00
		i_data_rd_01	: in	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Read Data 01
		i_data_rd_02	: in	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Read Data 02
		i_data_rd_03	: in	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Read Data 03

		o_data_wr		: out	std_logic_vector((g_DATA_WIDTH - 1) downto 0);				-- Scrubbed Memory Write Data
		o_addr			: out	std_logic_vector((g_ADDR_WIDTH - 1) downto 0);				-- Scrubbed Memory Address
		o_rw 			: out	std_logic;													-- Scrubbed Memory Read/Write

		o_error			: out	std_logic;													-- Error Flag
		o_event			: out	std_logic_vector(31 downto 0);								-- Error Event

		o_status 		: out 	std_logic_vector(7 downto 0)								-- Scrubber Status Register
	);
end entity;


-------------------------------------------------------------------------------------------------------------------------------
--	ARCHITECTURE
-------------------------------------------------------------------------------------------------------------------------------
architecture scrubber_arch of scrubber is

	---------------------------------------------------------------------------------------------------------------------------
	-- 	CONSTANT DECLARATIONS
	---------------------------------------------------------------------------------------------------------------------------

	constant c_STAT_IDLE				: std_logic_vector(7 downto 0)					-- Idle Status Value
										:= x"00";

	constant c_STAT_SCAN				: std_logic_vector(7 downto 0)					-- Scanning Status Value
										:= x"01";

	constant c_STAT_SCRUB				: std_logic_vector(7 downto 0)					-- Scrubbing Status Value
										:= x"02";

	constant c_STAT_ERROR				: std_logic_vector(7 downto 0)					-- Error Status Value
										:= x"FF";


	---------------------------------------------------------------------------------------------------------------------------
	-- 	TYPE DECLARATIONS
	---------------------------------------------------------------------------------------------------------------------------

	-- Type for Program Count Finite State Machine (FSM) States
    type t_State is ( 
		s_INIT,
		s_LOAD,
		s_READ,
		s_CHECK,
		s_CLEAR,
		s_ACTIVATE,
		s_REPAIR,
		s_DISAGREE,
		s_INCR,
		s_ADDR
    );


	---------------------------------------------------------------------------------------------------------------------------
	--	COMPONENT DECLARATIONS
	---------------------------------------------------------------------------------------------------------------------------

	-- Declare the voter component
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


	-- Declare the counter component
	component counter_up_down is
	generic(
		g_MAX_COUNT               	: integer      	:= 256;
		g_SIZE_COUNT              	: integer      	:= 8
	);
	port(
		i_clk                      	: in    std_logic;
		i_reset_n                  	: in    std_logic;

		i_en                        : in    std_logic;
		i_clr                       : in    std_logic;

		i_up_down_sel               : in    std_logic;

		o_count                     : out   std_logic_vector( (g_SIZE_COUNT -1) downto 0)
	);
	end component;


	---------------------------------------------------------------------------------------------------------------------------
	--	SIGNAL DECLARATIONS
	---------------------------------------------------------------------------------------------------------------------------

    signal r_cur_state       	: t_State                       		             		-- FSM Current State
								:= s_INIT;

    signal r_nxt_state       	: t_State                       		            		-- FSM Next State
								:= s_INIT; 

	signal w_addr_cnt_en		: std_logic;												-- Memory Address Counter Enable
	signal w_addr_cnt_clr		: std_logic;												-- Memory Address Counter Clear

	signal w_error				: std_logic;												-- Error Detected Flag
	signal r_error_addr			: std_logic_vector(31 downto 0);							-- Address of Detected Error

	signal r_mem_addr			: std_logic_vector((g_ADDR_WIDTH - 1) downto 0);			-- Memory Address

	signal r_data_rd_vote		: std_logic_vector((g_DATA_WIDTH - 1) downto 0);			-- Data Read (Voted)
	signal r_data_rd_syn		: std_logic_vector(3 downto 0);								-- Data Read Syndrome

	signal r_status				: std_logic_vector(7 downto 0);								-- Status Register


begin

	---------------------------------------------------------------------------------------------------------------------------
	--	COMPONENT INSTANTIATIONS
	---------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the voter component
	VOTER_00 : voter
	generic map(
		g_VOTE_SIZE                 => g_DATA_WIDTH
	)
	port map(
		i_val_00                    => i_data_rd_00,
		i_val_01                    => i_data_rd_01,
		i_val_02                    => i_data_rd_02,
		i_val_03                    => i_data_rd_03,
	
		o_result                    => r_data_rd_vote,
		o_syndrome                  => r_data_rd_syn
	);


	-- Instantiate the address counter
	MEM_ADDR_CNT_00 : counter_up_down
	generic map(
		g_MAX_COUNT            		=> (g_RAM_DEPTH - 1),
		g_SIZE_COUNT              	=> g_ADDR_WIDTH
	)
	port map(
		i_clk                      	=> i_clk,
		i_reset_n                  	=> i_reset_n,

		i_en                        => w_addr_cnt_en,
		i_clr                       => w_addr_cnt_clr,

		i_up_down_sel               => '1',

		o_count                     => r_mem_addr
	);


    ------------------------------------------------------------------------------------------------------------------------------------
	--  STATE MACHINE - STATE MEMORY LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

	-- Process to handle state memory 
    FSM_STATE_MEMORY_00 : process( i_clk, i_reset_n )
    begin

		-- Clock edges
        if( rising_edge( i_clk ) ) then

			-- Reset condition
			if( i_reset_n = '0' ) then

				-- Reset current state to IDLE
				r_cur_state         	<= s_INIT;

			else

				-- Set current state to next state
				r_cur_state         	<= r_nxt_state;

			end if;

		end if;

    end process;


------------------------------------------------------------------------------------------------------------------------------------
	--  SCRUBBER STATE MACHINE - NEXT STATE LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle current state
    FSM_CURRENT_STATE_00 : process( r_cur_state, r_data_rd_syn )
    begin

        -- Handle current state
        case( r_cur_state ) is

            -- Init State
            when s_INIT        	=>  r_nxt_state         <= s_READ;

			-- Load State
			when s_LOAD			=> 	r_nxt_state         <= s_READ;

			-- Read State
			when s_READ			=> 	r_nxt_state         <= s_CHECK;

			-- Check State
			when s_CHECK		=> 	if( r_data_rd_syn = "1111" ) then
										r_nxt_state			<= s_DISAGREE;
			
									elsif( r_data_rd_syn /= "0000" ) then
										r_nxt_state			<= s_ACTIVATE;

									else
										r_nxt_state			<= s_CLEAR;

									end if;

			-- Clear State
			when s_CLEAR		=> 	r_nxt_state			<= s_INCR;

			-- Activate State
			when s_ACTIVATE		=> 	if( i_en = '1' ) then
										r_nxt_state			<= s_REPAIR;

									else
										r_nxt_state			<= s_ACTIVATE;

									end if;

			-- Repair State
			when s_REPAIR		=> 	if( r_data_rd_syn /= "0000" ) then
										r_nxt_state			<= s_REPAIR;

									else
										r_nxt_state			<= s_INCR;

									end if;

			-- Disagree State
			when s_DISAGREE		=> 	r_nxt_state			<= s_INCR;


			-- Increment State
			when s_INCR			=> 	r_nxt_state			<= s_ADDR;

			-- Address State
			when s_ADDR			=> 	r_nxt_state			<= s_LOAD;

            -- (Default State)
            when others         =>  r_nxt_state         <= s_INIT;

        end case;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--  SCRUBBER STATE MACHINE - OUTPUT LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle output logic
    FSM_OUTPUT_LOGIC_00 : process( r_cur_state, r_mem_addr, r_data_rd_vote, r_data_rd_syn )
    begin

        -- Handle current state
        case( r_cur_state ) is

            -- Init State
			when s_INIT        	=>	o_data_wr			<= (others => '0');
									o_addr				<= (others => '0');
									o_rw				<= '0';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '1';

									w_error				<= '0';
									r_error_addr		<= (others => '0');

									r_status			<= c_STAT_IDLE;

			-- Load State
			when s_LOAD			=> 	o_data_wr			<= (others => '0');
									o_addr				<= r_mem_addr;
									o_rw				<= '0';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

									w_error				<= '0';
									r_error_addr		<= (others => '0');

									r_status			<= c_STAT_SCAN;

			-- Read State
			when s_READ			=> 	o_data_wr			<= (others => '0');
									o_addr				<= r_mem_addr;
									o_rw				<= '0';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

									w_error				<= '0';
									r_error_addr		<= (others => '0');

									r_status			<= c_STAT_SCAN;

			-- Check State
			when s_CHECK		=> 	o_data_wr			<= (others => '0');
									o_addr				<= r_mem_addr;
									o_rw				<= '0';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

									w_error				<= '0';
									r_error_addr		<= (others => '0');

									r_status			<= c_STAT_SCAN;

			-- Clear State
			when s_CLEAR		=>	o_data_wr			<= r_data_rd_vote;
									o_addr				<= r_mem_addr;
									o_rw				<= '0';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

									w_error				<= '0';
									r_error_addr		<= (others => '0');

									r_status			<= c_STAT_SCAN;

			-- Activate State
			when s_ACTIVATE		=>	o_data_wr			<= (others => '0');
									o_addr				<= r_mem_addr;
									o_rw				<= '0';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

									w_error				<= '1';
									r_error_addr		<= r_mem_addr;

									r_status			<= c_STAT_SCRUB;

			-- Repair State
			when s_REPAIR		=> 	o_data_wr			<= r_data_rd_vote;
									o_addr				<= r_mem_addr;
									o_rw				<= '1';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

									w_error				<= '0';
									r_error_addr		<= r_mem_addr;

									r_status			<= c_STAT_SCRUB;

			-- Disagree State
			when s_DISAGREE		=>	o_data_wr			<= r_data_rd_vote;
									o_addr				<= r_mem_addr;
									o_rw				<= '0';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

									w_error				<= '1';
									r_error_addr		<= r_mem_addr;

									r_status			<= c_STAT_ERROR;

			-- Increment State
			when s_INCR			=> 	o_data_wr			<= (others => '0');
									o_addr				<= r_mem_addr;
									o_rw				<= '0';

									w_addr_cnt_en		<= '1';
									w_addr_cnt_clr		<= '0';

									w_error				<= '0';
									r_error_addr		<= (others => '0');

									r_status			<= c_STAT_SCAN;

			-- Address State
			when s_ADDR			=>	o_data_wr			<= (others => '0');
									o_addr				<= r_mem_addr;
									o_rw				<= '0';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

									w_error				<= '0';
									r_error_addr		<= (others => '0');

									r_status			<= c_STAT_SCAN;

            -- (Default State)
            when others         =>	o_data_wr			<= (others => '0');
									o_addr				<= (others => '0');
									o_rw				<= '0';

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

									w_error				<= '0';
									r_error_addr		<= (others => '0');

									r_status			<= c_STAT_ERROR;

        end case;

    end process;


	---------------------------------------------------------------------------------------------------------------------------
	--	SIGNAL ASSIGNMENTS
	---------------------------------------------------------------------------------------------------------------------------

	-- Assign error flag and error event
	o_error			<= w_error;
	o_event			<= r_data_rd_syn & x"000" & r_error_addr(15 downto 0);


	-- Assign status register
	o_status		<= r_status;


end architecture;
-------------------------------------------------------------------------------------------------------------------------------
--	END OF CODE
-------------------------------------------------------------------------------------------------------------------------------