----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC ARBITER
--
--	Created by Chris Major
-- 	4/3/2023
--
--	The Arbiter resolves errors in the register map.
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
-- 	LIBRARIES
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
-- 	ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity arbiter is
port(
	i_clk						: in	std_logic;											    -- Clock
	i_reset_n					: in	std_logic;											    -- Active Low Reset

	i_en 						: in	std_logic;												-- Arbiter Enable

	i_pc_00                   	: in    std_logic_vector(31 downto 0); 							-- Program Count (Tile 00)
	i_pc_01                   	: in    std_logic_vector(31 downto 0); 							-- Program Count (Tile 01)
	i_pc_02                   	: in    std_logic_vector(31 downto 0); 							-- Program Count (Tile 02)
	i_pc_03                   	: in    std_logic_vector(31 downto 0); 							-- Program Count (Tile 03)

	i_reg_read_00				: in	std_logic_vector(31 downto 0); 							-- Register Read Data 00
	i_reg_read_01				: in	std_logic_vector(31 downto 0); 							-- Register Read Data 01
	i_reg_read_02				: in	std_logic_vector(31 downto 0); 							-- Register Read Data 02
	i_reg_read_03				: in	std_logic_vector(31 downto 0); 							-- Register Read Data 03

	o_reg_write					: out	std_logic_vector(31 downto 0); 							-- Register Write Data
	o_reg_addr					: out	std_logic_vector(4 downto 0);							-- Register Address
	o_reg_rw					: out	std_logic;												-- Register Read/Write Enable

    o_pc_repair_en          	: out   std_logic;                                              -- Program Count Repair Enable
	o_pc 						: out   std_logic_vector(31 downto 0); 							-- Program Count (Voted)

    o_arbiter_stat            	: out   std_logic_vector( 7 downto 0 )                          -- Arbiter Status Flags
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- 	ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture arbiter_arch of arbiter is

    ------------------------------------------------------------------------------------------------------------------------------------
	-- 	TYPE DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	-- Type for Program Count Finite State Machine (FSM) States
    type t_PC_State is ( 
        s_INIT,
		s_CHECK,
		s_ITERATE,
		s_REPAIR
    );   

	-- Type for Register Finite State Machine (FSM) States
    type t_REG_State is ( 
        s_INIT,
		s_CHECK,
		s_ITERATE,
		s_REPAIR
    );   


    ------------------------------------------------------------------------------------------------------------------------------------
	-- 	COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

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


    ------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    signal r_PC_cur_state       : t_PC_State                       	:= s_INIT;             	-- PC FSM Current State
    signal r_PC_nxt_state       : t_PC_State                       	:= s_INIT;             	-- PC FSM Next State

    signal r_REG_cur_state     	: t_REG_State                       := s_INIT;             	-- Register FSM Current State
    signal r_REG_nxt_state     	: t_REG_State                       := s_INIT;             	-- Register FSM Next State


	signal r_pc					: std_logic_vector(31 downto 0);							-- Program Count (Voted)
	signal r_pc_syn            	: std_logic_vector(3 downto 0);                       		-- Program Count Syndrome Flags

	signal r_reg_read			: std_logic_vector(31 downto 0);							-- Register Read (Voted)
	signal r_reg_syn 			: std_logic_vector(3 downto 0);                       		-- Register Read Syndrome Flags


	signal w_addr_cnt_en		: std_logic;												-- Register Address Counter Enable
	signal w_addr_cnt_clr		: std_logic;												-- Register Address Counter Clear
	signal r_reg_addr			: std_logic_vector(4 downto 0);                       		-- Register Address


	signal r_arbiter_stat		: std_logic_vector(7 downto 0);								-- Arbiter Status


begin

    ------------------------------------------------------------------------------------------------------------------------------------
	--  ARBITER STATE MACHINES - STATE MEMORY LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

	-- Process to handle state memory 
    FSM_STATE_MEMORY_00 : process( i_clk, i_reset_n )
    begin

        -- Handle reset condition
        if( i_reset_n = '0' ) then

            -- Reset current state to IDLE
            r_PC_cur_state         	<= s_INIT;
			r_REG_cur_state			<= s_INIT;

        -- Handle clock edges
        elsif( rising_edge( i_clk ) ) then

            -- Set current state to next state
            r_PC_cur_state         	<= r_PC_nxt_state;
			r_REG_cur_state         <= r_REG_nxt_state;

        end if;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--  PROGRAM COUNT ARBITER STATE MACHINE - NEXT STATE LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle current state
    PC_FSM_CURRENT_STATE_00 : process( r_PC_cur_state, r_pc_syn, i_en )
    begin

        -- Handle current state
        case( r_PC_cur_state ) is

            -- Init State
            when s_INIT        	=>  r_PC_nxt_state         	<= s_CHECK;

            -- Check State
			when s_CHECK		=> 	if( (r_pc_syn /= "0000") and (i_en = '1') ) then
										r_PC_nxt_state			<= s_REPAIR;

									else
										r_PC_nxt_state			<= s_ITERATE;

									end if;

			-- Iterate State
			when s_ITERATE		=> 	r_PC_nxt_state			<= s_CHECK;

			-- Repair State
			when s_REPAIR		=> 	r_PC_nxt_state			<= s_CHECK;

            -- (Default State)
            when others         =>  r_PC_nxt_state         	<= s_INIT;

        end case;

    end process;


    ------------------------------------------------------------------------------------------------------------------------------------
	--  PROGRAM COUNT ARBITER STATE MACHINE - OUTPUT LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle output logic
    PC_FSM_OUTPUT_LOGIC_00 : process( r_PC_cur_state )
    begin

        -- Handle current state
        case( r_PC_cur_state ) is

            -- Init State
            when s_INIT        	=>	o_arbiter_stat		<= x"00";  
									
									o_pc_repair_en  	<= '0';
									o_pc				<= r_pc;
            
            -- Check State
			when s_CHECK		=> 	o_arbiter_stat 		<= r_arbiter_stat;
			
									o_pc_repair_en  	<= '0';
									o_pc				<= r_pc;

			-- Iterate State
			when s_ITERATE		=> 	o_arbiter_stat 		<= r_arbiter_stat;

									o_pc_repair_en  	<= '0';
									o_pc				<= r_pc;

			-- Repair State
			when s_REPAIR		=> 	o_arbiter_stat 		<= r_arbiter_stat;

									o_pc_repair_en  	<= '1';
									o_pc				<= r_pc;

            -- (Default State)
            when others         =>	o_arbiter_stat		<= x"FF"; 

									o_pc_repair_en  	<= '0';  
									o_pc				<= r_pc;

        end case;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	PROGRAM COUNT VOTER
	------------------------------------------------------------------------------------------------------------------------------------

    -- Instantiate the Voter component for the Program Count
    PC_VOTE_00 : voter
	generic map (
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => i_pc_00,
		i_val_01                    => i_pc_01,
		i_val_02                    => i_pc_02,
		i_val_03                    => i_pc_03,
	
		o_result                    => r_pc,
		o_syndrome                  => r_pc_syn 
	);


	------------------------------------------------------------------------------------------------------------------------------------
	--  REGISTER ARBITER STATE MACHINE - NEXT STATE LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle current state
    REG_FSM_CURRENT_STATE_00 : process( r_REG_cur_state )
    begin

        -- Handle current state
        case( r_REG_cur_state ) is

            -- Init State
            when s_INIT        	=>  r_REG_nxt_state        	<= s_CHECK;

            -- Check State
			when s_CHECK		=> 	if( (r_reg_syn /= "0000") and (i_en = '1') ) then
										r_REG_nxt_state			<= s_REPAIR;

									else
										r_REG_nxt_state			<= s_ITERATE;

									end if;

			-- Iterate State
			when s_ITERATE		=> 	r_REG_nxt_state			<= s_CHECK;

			-- Repair State
			when s_REPAIR		=> 	r_REG_nxt_state			<= s_CHECK;

            -- (Default State)
            when others         =>  r_REG_nxt_state       	<= s_INIT;

        end case;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--  REGISTER ARBITER STATE MACHINE - OUTPUT LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle output logic
    REG_FSM_OUTPUT_LOGIC_00 : process( r_REG_cur_state )
    begin

        -- Handle current state
        case( r_REG_cur_state ) is

            -- Init State
            when s_INIT        	=>	o_reg_addr			<= "00000";
									o_reg_rw			<= '0';
									o_reg_write			<= (others => '0');

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '1';

            -- Check State
			when s_CHECK		=> 	o_reg_addr			<= r_reg_addr;
									o_reg_rw			<= '0';
									o_reg_write			<= r_reg_read;
												
									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

			-- Iterate State
			when s_ITERATE		=> 	o_reg_addr			<= r_reg_addr;
									o_reg_rw			<= '0';
									o_reg_write			<= r_reg_read;

									w_addr_cnt_en		<= '1';
									w_addr_cnt_clr		<= '0';

			-- Repair State
			when s_REPAIR		=> 	o_reg_addr			<= r_reg_addr;
									o_reg_rw			<= '1';
									o_reg_write			<= r_reg_read;

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

            -- (Default State)
            when others         =>	o_reg_addr			<= "00000";
									o_reg_rw			<= '0';
									o_reg_write			<= (others => '0');

									w_addr_cnt_en		<= '0';
									w_addr_cnt_clr		<= '0';

        end case;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	REGISTER READ VOTER
	------------------------------------------------------------------------------------------------------------------------------------

    -- Instantiate the Voter component for the Program Count
    REG_VOTE_00 : voter
	generic map (
		g_VOTE_SIZE                 => 32
	)
	port map(
		i_val_00                    => i_reg_read_00,
		i_val_01                    => i_reg_read_01,
		i_val_02                    => i_reg_read_02,
		i_val_03                    => i_reg_read_03,
	
		o_result                    => r_reg_read,
		o_syndrome                  => r_reg_syn 
	);


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	REGISTER ADDRESS COUNTER
	------------------------------------------------------------------------------------------------------------------------------------

	-- Instantiate the address register counter
	REG_ADDR_CNT_00 : counter_up_down
	generic map(
		g_MAX_COUNT               	=> 31,
		g_SIZE_COUNT              	=> 5
	)
	port map(
		i_clk                      	=> i_clk,
		i_reset_n                  	=> i_reset_n,

		i_en                        => w_addr_cnt_en,
		i_clr                       => w_addr_cnt_clr,

		i_up_down_sel               => '1',

		o_count                     => r_reg_addr
	);


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	r_arbiter_stat 	<= 	'1' & "00" & r_reg_addr 			when( r_reg_syn /= "0000" ) 		else
						x"00";
	

end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------