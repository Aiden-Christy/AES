----------------------------------------------------------------------------------------------------------------------------------------
--
--	RISCV PROCESSOR CORE
--	CONTROL UNIT
--
--	Created by Chris Major
-- 	6/17/2022
--
--	A handwritten attempt at a functional RISC-V core in VHDL.
--
-- 	The Control Unit fetches and decodes instructions
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
entity control_unit is
generic(
    g_OBFUSCATION_OFFSET        : integer           := 0
);
port(
    i_clk						: in    std_logic;			                                --! Clock
	i_reset_n					: in    std_logic;			                                --! Active Low Reset

    i_error_detect              : in    std_logic;			                                -- Error Detected Flag 

    i_opcode                    : in    std_logic_vector(6 downto 0);                       --! Instruction Opcode
    i_funct3                    : in    std_logic_vector(2 downto 0);                       --! Instruction Function 3 (funct3) signal
    i_funct7                    : in    std_logic_vector(6 downto 0);                       --! Instruction Function 7 (funct7) signal

    i_BrEQ                      : in    std_logic;                                          --! Branch When Equal 
    i_BrLT                      : in    std_logic;                                          --! Branch When Lesser Than 

    i_exception_flag            : in    std_logic;                                          --! Exception Flag
    o_exception_clr             : out   std_logic;                                          --! Exception Clear

    o_radpc_active              : out   std_logic;                                          --! RadPC Active Flag

    o_BrU                       : out   std_logic;                                          --! Unsigned/Signed Switch 

    o_pc_sel                    : out   std_logic_vector(1 downto 0);                       --! PC Select
    o_pc_en                     : out   std_logic;                                          --! PC Enable

    o_data_pass                 : out   std_logic_vector(1 downto 0);                       --! ALU passthrough select
    o_b_sel                     : out   std_logic;                                          --! ALU B Data Select
    o_a_sel                     : out   std_logic;                                          --! ALU A Data Select

    o_funct7                    : out   std_logic_vector(6 downto 0);                       --! Instruction Function 7 (funct7) signal
    o_funct3                    : out   std_logic_vector(2 downto 0);                       --! Instruction Function 3 (funct3) signal

    o_reg_wen                   : out   std_logic;                                          --! Register Write Enable
    o_imm_sel                   : out   std_logic_vector(2 downto 0);                       --! Imm Gen Select

    o_mem_rw_en                 : out   std_logic;                                          --! Memory RW Enable
    o_wb_sel                    : out   std_logic_vector(1 downto 0);                       --! Memory/ALU Result Select
    o_load_size                 : out   std_logic_vector(2 downto 0);                       --! Memory Size Select

    o_csr_en                    : out   std_logic;                                          --! CSR Read Enable
    o_csr_sel                   : out   std_logic_vector(1 downto 0);                       --! CSR Operation Select
    o_csr_imm                   : out   std_logic;                                          --! CSR Immediate Select

    o_mepc_en                   : out   std_logic;                                          --! MEPC Write

    o_arbiter_en                : out   std_logic;                                          -- Arbiter Enable Flag
    o_scrubber_en               : out   std_logic;                                          -- Scrubber Enable Flag
    o_illegal_opcode            : out   std_logic                                           --! Illegal Opcode Flag
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture control_unit_arch of control_unit is

    ------------------------------------------------------------------------------------------------------------------------------------
    --  TYPE DECLARATIONS
    ------------------------------------------------------------------------------------------------------------------------------------

    -- Type for Finite State Machine (FSM) States
    type t_State is ( 
        s_START,
        s_MONITOR,
        s_CORRECT,
        s_FETCH,
        s_DECODE,
        s_EXECUTE,
        s_EXCEPTION
    );   


    ------------------------------------------------------------------------------------------------------------------------------------
	-- CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    constant c_OFFSET           : unsigned(6 downto 0)              := to_unsigned( g_OBFUSCATION_OFFSET, 7 );      --! Instruction Offset Value

    constant c_R_INST           : std_logic_vector(6 downto 0)      := c_R_OPCODE;                                  --! Register (R) Instruction Opcode (Local)
    constant c_I_INST           : std_logic_vector(6 downto 0)      := c_I_OPCODE;                                  --! Immediate (I) Instruction Opcode (Local)
    constant c_L_INST           : std_logic_vector(6 downto 0)      := c_L_OPCODE;                                  --! Load (L) Instruction Opcode (Local)
    constant c_S_INST           : std_logic_vector(6 downto 0)      := c_S_OPCODE;                                  --! Store (S) Instruction Opcode (Local)
    constant c_B_INST         	: std_logic_vector(6 downto 0)      := c_B_OPCODE;           		                --! Branch (B) Instruction Opcode (Local)
    constant c_JAL_INST         : std_logic_vector(6 downto 0)      := c_JAL_OPCODE;           		                --! Jump And Link (JAL) Instruction Opcode (Local)
    constant c_JALR_INST      	: std_logic_vector(6 downto 0)      := c_JALR_OPCODE;           		            --! Jump and Link Register (JALR) Instruction Opcode (Local)
    constant c_LUI_INST         : std_logic_vector(6 downto 0)      := c_LUI_OPCODE;                                --! Load Upper Immediate (LUI) Instruction Opcode (Local)
    constant c_AUIPC_INST       : std_logic_vector(6 downto 0)      := c_AUIPC_OPCODE;                              --! Add Upper Immediate to PC (AUIPC) Instruction Opcode (Local)
    constant c_SYS_INST      	: std_logic_vector(6 downto 0)      := c_SYS_OPCODE;           		                --! System (SYS) Instruction Opcode (Local)


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    signal r_cur_state          : t_State                           := s_START;             --! Finite State Machine (FSM) Current State
    signal r_nxt_state          : t_State                           := s_START;             --! Finite State Machine (FSM) Next State

    signal r_opcode             : std_logic_vector(6 downto 0);                             -- Instruction Opcode
    signal r_funct3             : std_logic_vector(2 downto 0);                             -- Function 3
    signal r_funct7             : std_logic_vector(6 downto 0);                             -- Function 7
    signal r_branch_unsigned    : std_logic;                                                -- Branch Compare Unsigned Flag

    signal r_exception_flag     : std_logic;                                                -- Test

begin

    ------------------------------------------------------------------------------------------------------------------------------------
	--  CONTROL UNIT STATE MACHINE - STATE MEMORY LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle state memory 
    FSM_STATE_MEMORY_00 : process( i_clk, i_reset_n )
    begin

        -- Handle reset condition
        if( i_reset_n = '0' ) then

            -- Reset current state to IDLE
            r_cur_state         <= s_START;

        -- Handle clock edges
        elsif( rising_edge( i_clk ) ) then

            -- Set current state to next state
            r_cur_state         <= r_nxt_state;

        end if;

    end process;


    ------------------------------------------------------------------------------------------------------------------------------------
	--  CONTROL UNIT STATE MACHINE - NEXT STATE LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle current state
    FSM_CURRENT_STATE_00 : process( r_cur_state, i_exception_flag, i_error_detect )
    begin

        -- Handle current state
        case( r_cur_state ) is

            -- Start State
            when s_START        =>  r_nxt_state         <= s_MONITOR;

            -- Monitor State
            when s_MONITOR      =>  if( i_error_detect = '1' ) then
                                        r_nxt_state         <= s_CORRECT;

                                    else
                                        r_nxt_state         <= s_FETCH;

                                    end if;

            -- Correct State
            when s_CORRECT      =>  if( i_error_detect = '0' ) then
                                        r_nxt_state         <= s_MONITOR;

                                    else
                                        r_nxt_state         <= s_CORRECT;

                                    end if;

            -- Fetch State
            when s_FETCH        =>  if( i_exception_flag = '1') then
                                        r_nxt_state         <= s_EXCEPTION;

                                    else
                                        r_nxt_state         <= s_DECODE;

                                    end if;

            -- Decode State
            when s_DECODE       =>  r_nxt_state         <= s_EXECUTE;
                                   
            -- Execute State
            when s_EXECUTE      =>  r_nxt_state         <= s_MONITOR;

            -- Exception State
            when s_EXCEPTION    =>  r_nxt_state         <= s_FETCH;

            -- (Default State)
            when others         =>  r_nxt_state         <= s_START;

        end case;

    end process;


    ------------------------------------------------------------------------------------------------------------------------------------
	--  CONTROL UNIT STATE MACHINE - OUTPUT LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle output logic
    FSM_OUTPUT_LOGIC_00 : process( r_cur_state, r_opcode, r_funct3, r_funct7, i_BrEQ, i_BrLT, r_branch_unsigned )
    begin

        -- Handle current state
        case( r_cur_state ) is

            -- Start State
            when s_START        =>  o_illegal_opcode    <= '0';
                                    o_pc_en             <= '1';   
                                    o_pc_sel            <= c_PC_INCR;

                                    o_a_sel             <= '0';
                                    o_b_sel             <= '0';

                                    o_imm_sel           <= c_I_IMM;

                                    o_funct3            <= (others => '0');
                                    o_funct7            <= (others => '0');

                                    o_reg_wen           <= '0';  
                                    o_data_pass         <= (others => '0');

                                    o_wb_sel            <= c_WB_MEM_READ;
                                    o_mem_rw_en         <= '0';
                                    o_load_size         <= (others => '0');

                                    o_csr_en            <= '0';
                                    o_csr_sel           <= "00";
                                    o_csr_imm           <= '0';

                                    o_radpc_active      <= '0';

                                    o_exception_clr     <= '0';
                                    o_mepc_en           <= '0';

                                    o_arbiter_en        <= '0';
                                    o_scrubber_en       <= '0';

            -- Monitor State
            when s_MONITOR      =>  o_illegal_opcode    <= '0'; 
                                    o_pc_en             <= '0';
                                    o_pc_sel            <= c_PC_INCR;

                                    o_a_sel             <= '0';
                                    o_b_sel             <= '0';

                                    o_imm_sel           <= c_I_IMM;

                                    o_funct3            <= (others => '0');
                                    o_funct7            <= (others => '0');

                                    o_reg_wen           <= '0';  
                                    o_data_pass         <= (others => '0');

                                    o_wb_sel            <= c_WB_MEM_READ;
                                    o_mem_rw_en         <= '0';
                                    o_load_size         <= (others => '0');

                                    o_csr_en            <= '0';
                                    o_csr_sel           <= "00";
                                    o_csr_imm           <= '0';

                                    o_radpc_active      <= '1';

                                    o_exception_clr     <= '0';
                                    o_mepc_en           <= '0';

                                    o_arbiter_en        <= '0';
                                    o_scrubber_en       <= '1';

            -- Correct State
            when s_CORRECT      =>  o_illegal_opcode    <= '0'; 
                                    o_pc_en             <= '0';
                                    o_pc_sel            <= c_PC_INCR;

                                    o_a_sel             <= '0';
                                    o_b_sel             <= '0';

                                    o_imm_sel           <= c_I_IMM;

                                    o_funct3            <= (others => '0');
                                    o_funct7            <= (others => '0');

                                    o_reg_wen           <= '0';  
                                    o_data_pass         <= (others => '0');

                                    o_wb_sel            <= c_WB_MEM_READ;
                                    o_mem_rw_en         <= '0';
                                    o_load_size         <= (others => '0');

                                    o_csr_en            <= '0';
                                    o_csr_sel           <= "00";
                                    o_csr_imm           <= '0';

                                    o_radpc_active      <= '1';

                                    o_exception_clr     <= '0';
                                    o_mepc_en           <= '0';

                                    o_arbiter_en        <= '1';
                                    o_scrubber_en       <= '1';

            -- Fetch State
            when s_FETCH        =>  o_illegal_opcode    <= '0'; 
                                    o_pc_en             <= '0';
                                    o_pc_sel            <= c_PC_INCR;

                                    o_a_sel             <= '0';
                                    o_b_sel             <= '0';

                                    o_imm_sel           <= c_I_IMM;

                                    o_funct3            <= (others => '0');
                                    o_funct7            <= (others => '0');

                                    o_reg_wen           <= '0';  
                                    o_data_pass         <= (others => '0');

                                    o_wb_sel            <= c_WB_MEM_READ;
                                    o_mem_rw_en         <= '0';
                                    o_load_size         <= (others => '0');

                                    o_csr_en            <= '0';
                                    o_csr_sel           <= "00";
                                    o_csr_imm           <= '0';

                                    o_radpc_active      <= '1';

                                    o_exception_clr     <= '0';
                                    o_mepc_en           <= '0';

                                    o_arbiter_en        <= '0';
                                    o_scrubber_en       <= '0';

            -- Decode State
            when s_DECODE       =>  o_pc_en             <= '0';                                                             -- Disable Program Count
                                    o_radpc_active      <= '1';

                                    o_exception_clr     <= '0';
                                    o_mepc_en           <= '0';
            
                                    o_arbiter_en        <= '0';
                                    o_scrubber_en       <= '0';

                                    case( r_opcode ) is

                                        -- Register (R) Instruction
                                        when c_R_INST           =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '0';

                                                                    o_imm_sel           <= c_I_IMM;

                                                                    o_funct3            <= r_funct3;
                                                                    o_funct7            <= r_funct7;

                                                                    o_reg_wen           <= '0';   
                                                                    o_data_pass         <= (others => '0');

                                                                    o_wb_sel            <= c_WB_ALU;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');

                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Immediate (I) Instruction
                                        when c_I_INST           =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag 
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '1';

                                                                    o_imm_sel           <= c_I_IMM;

                                                                    o_funct3            <= r_funct3;

                                                                    o_reg_wen           <= '0';  
                                                                    o_data_pass         <= (others => '0');

                                                                    o_wb_sel            <= c_WB_ALU;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                                                    if( r_funct3 = "101" ) then
                                                                        o_funct7            <= r_funct7;

                                                                    else
                                                                        o_funct7            <= (others => '0');

                                                                    end if;

                                                                    

                                        -- Load (L) Instruction
                                        when c_L_INST           =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate

                                                                    o_imm_sel           <= c_I_IMM;                         -- Set Immediate Type to Default

                                                                    o_funct3            <= (others => '0');                 -- Set Load Size from Funct3 Bits
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';   
                                                                    o_data_pass         <= (others => '0'); 

                                                                    o_wb_sel            <= c_WB_MEM_READ;                   -- Set Writeback Select to Memory
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= r_funct3;
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Store (S) Instruction
                                        when c_S_INST           =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate
   
                                                                    o_imm_sel           <= c_S_IMM;                         -- Set Immediate Type to S-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= (others => '0'); 
                                                                    
                                                                    o_wb_sel            <= c_WB_MEM_READ;           
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= r_funct3;                        -- Set Load Size from Funct3 Bits
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Branch (B) Instruction
                                        when c_B_INST           =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '1';                             -- Set A Data to PC  
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate
   
                                                                    o_imm_sel           <= c_B_IMM;                         -- Set Immediate Type to B-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= (others => '0');   

                                                                    o_wb_sel            <= c_WB_MEM_READ;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= r_funct3;                        -- Set Load Size from Funct3 Bits
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Jump And Link (JAL) Instruction
                                        when c_JAL_INST         =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_ALU;                        -- Set PC input to ALU

                                                                    o_a_sel             <= '1';                             -- Set A Data to PC  
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate
   
                                                                    o_imm_sel           <= c_J_IMM;                         -- Set Immediate Type to J-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= (others => '0');   

                                                                    o_wb_sel            <= c_WB_PC_PLUS;                    -- Set Writeback to PC                 
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Jump And Link Register (JALR) Instruction
                                        when c_JALR_INST        =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_ALU;                        -- Set PC input to ALU

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate
   
                                                                    o_imm_sel           <= c_I_IMM;

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= (others => '0');  

                                                                    o_wb_sel            <= c_WB_PC_PLUS;                    -- Set Writeback to PC                 
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                     
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Load Upper Immediate (LUI) Instruction 
                                        when c_LUI_INST         =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '1';                             -- Set A Data to PC
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate

                                                                    o_imm_sel           <= c_U_IMM;                         -- Set Immediate Type to U-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= (others => '0');

                                                                    o_wb_sel            <= c_WB_MEM_READ;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Add Upper Immediate to PC (AUIPC) Instruction
                                        when c_AUIPC_INST       =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '1';                             -- Set A Data to PC
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate
   
                                                                    o_imm_sel           <= c_U_IMM;                         -- Set Immediate Type to U-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= "01";                            -- Pass B data through ALU   

                                                                    o_wb_sel            <= c_WB_ALU;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- System (SYS) Instruction
                                        when c_SYS_INST         =>  if (r_funct7 = "0011000" AND r_funct3 = "000") then
                                                                        o_pc_sel            <= c_PC_MEPC;
                                                                    else
                                                                        o_pc_sel            <= c_PC_INCR;
                                                                    end if;
                                                                    o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= r_funct3(2);                     -- Select Immediate for I-type CSR instructions
   
                                                                    o_imm_sel           <= c_SYS_IMM;                       -- Set Immediate Type to CSR

                                                                    o_funct3            <= r_funct3;
                                                                    o_funct7            <= r_funct7;

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= "01";                            -- Pass B data through ALU  

                                                                    o_wb_sel            <= c_WB_CSR;                        -- Set Writeback to CSR
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                   
                                                                    o_csr_en            <= '1';                             -- Enable CSR access 
                                                                    o_csr_sel           <= r_funct3(1 downto 0);            -- Enable CSR select
                                                                    o_csr_imm           <= r_funct3(2);

                                        -- (Default Case)
                                        when others             =>  o_illegal_opcode    <= '1';                             -- Set Illegal Opcode Flag 
                                                                    o_pc_en             <= '0';                             -- Disable Program Count
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '0';

                                                                    o_imm_sel           <= c_I_IMM;

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= (others => '0');

                                                                    o_wb_sel            <= c_WB_MEM_READ;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');

                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                    end case;  

            -- Execute State
            when s_EXECUTE      =>  o_pc_en             <= '1';
                                    o_radpc_active      <= '1';

                                    o_exception_clr     <= '0';
                                    o_mepc_en           <= '0';

                                    o_arbiter_en        <= '0';
                                    o_scrubber_en       <= '0';
            
                                    case( r_opcode ) is

                                        -- Register (R) Type Instructions
                                        when c_R_INST           =>  o_illegal_opcode    <= '0'; 
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '0';

                                                                    o_imm_sel           <= c_I_IMM;

                                                                    o_funct3            <= r_funct3;
                                                                    o_funct7            <= r_funct7;

                                                                    o_reg_wen           <= '1';                             -- Set Register Write'
                                                                    o_data_pass         <= (others => '0');

                                                                    o_wb_sel            <= c_WB_ALU;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Immediate (I) Type Instructions
                                        when c_I_INST           =>  o_illegal_opcode    <= '0'; 
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate

                                                                    o_imm_sel           <= c_I_IMM;

                                                                    o_funct3            <= r_funct3;

                                                                    o_reg_wen           <= '1';                             -- Set Register Write       
                                                                    o_data_pass         <= (others => '0');

                                                                    o_wb_sel            <= c_WB_ALU;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');

                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';
                                                                    
                                                                    if( r_funct3 = "101" ) then
                                                                        o_funct7            <= r_funct7;

                                                                    else
                                                                        o_funct7            <= (others => '0');

                                                                    end if;

                                        -- Load (L) Type Instructions
                                        when c_L_INST           =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate

                                                                    o_imm_sel           <= c_I_IMM;                         -- Set Immediate Type to Default

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '1';                             -- Set Register Write
                                                                    o_data_pass         <= (others => '0'); 

                                                                    o_wb_sel            <= c_WB_MEM_READ;                   -- Set Writeback Select to Memory
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= r_funct3;                        -- Set Load Size from Funct3 Bits
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Store (S) Type Instructions
                                        when c_S_INST           =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag                       
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '1';

                                                                    o_imm_sel           <= c_S_IMM;                         -- Set Immediate Type to S-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= (others => '0'); 

                                                                    o_wb_sel            <= c_WB_MEM_READ;
                                                                    o_mem_rw_en         <= '1';
                                                                    o_load_size         <= r_funct3;                        -- Set Load Size from Funct3 Bits
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Branch (B) Instruction
                                        when c_B_INST           =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
 
                                                                    o_a_sel             <= '1';                             -- Set A Data to PC
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate

                                                                    o_imm_sel           <= c_B_IMM;                         -- Set Immediate Type to B-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= (others => '0');

                                                                    o_wb_sel            <= c_WB_MEM_READ;             
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= r_funct3;                        -- Set Load Size from Funct3 Bits
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                                                    case( r_funct3 ) is

                                                                        -- Branch if Equal (BEQ)
                                                                        when "000"          =>  if( i_BrEQ = '1' and r_branch_unsigned = '0' ) then
                                                                                                    o_pc_sel    <= c_PC_ALU;

                                                                                                else
                                                                                                    o_pc_sel    <= c_PC_INCR;

                                                                                                end if;
 
                                                                        -- Branch if Not Equal (BNE)
                                                                        when "001"          =>  if( i_BrEQ = '0' and r_branch_unsigned = '0' ) then
                                                                                                    o_pc_sel    <= c_PC_ALU;

                                                                                                else
                                                                                                    o_pc_sel    <= c_PC_INCR;

                                                                                                end if;                                                                                           
 
                                                                        -- Branch if Lesser Than (BLT)
                                                                        when "100"          =>  if( i_BrLT = '1' and r_branch_unsigned = '0' ) then
                                                                                                    o_pc_sel    <= c_PC_ALU;

                                                                                                else
                                                                                                    o_pc_sel    <= c_PC_INCR;

                                                                                                end if;  

                                                                        -- Branch if Greater Than or Equal (BGE)
                                                                        when "101"          =>  if( i_BrLT = '0' and r_branch_unsigned = '0' ) then
                                                                                                    o_pc_sel    <= c_PC_ALU;

                                                                                                else
                                                                                                    o_pc_sel    <= c_PC_INCR;

                                                                                                end if;  

                                                                        -- Branch if Lesser Than Unsigned (BLTU)
                                                                        when "110"          =>  if( i_BrLT = '1' and r_branch_unsigned = '1' ) then
                                                                                                    o_pc_sel    <= c_PC_ALU;

                                                                                                else
                                                                                                    o_pc_sel    <= c_PC_INCR;

                                                                                                end if;  

                                                                        -- Branch if Greater Than or Equal Unsigned (BGEU)
                                                                        when "111"          =>  if( i_BrLT = '0' and r_branch_unsigned = '1' ) then
                                                                                                    o_pc_sel    <= c_PC_ALU;

                                                                                                else
                                                                                                    o_pc_sel    <= c_PC_INCR;

                                                                                                end if;  


                                                                        when others         =>  o_pc_sel <= "00";

                                                                    end case;

                                        -- Jump And Link (JAL) Instruction
                                        when c_JAL_INST         =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_ALU;                         -- Set PC input to ALU

                                                                    o_a_sel             <= '1';                             -- Set A Data to PC  
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate

                                                                    o_imm_sel           <= c_J_IMM;                         -- Set Immediate Type to J-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '1';                             -- Set Register Write
                                                                    o_data_pass         <= (others => '0');   

                                                                    o_wb_sel            <= c_WB_PC_PLUS;                    -- Set Writeback to PC                 
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');                 -- Set Load Size from Funct3 Bits
                                                                   
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Jump And Link Register (JALR) Instruction
                                        when c_JALR_INST        =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_ALU;                        -- Set PC input to ALU

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate

                                                                    o_imm_sel           <= c_I_IMM;

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '1';                             -- Set Register Write
                                                                    o_data_pass         <= (others => '0');   

                                                                    o_wb_sel            <= c_WB_PC_PLUS;                    -- Set Writeback to PC                 
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Load Upper Immediate (LUI) Instruction 
                                        when c_LUI_INST         =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate

                                                                    o_imm_sel           <= c_U_IMM;                         -- Set Immediate Type to U-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '1';                             -- Set Register Write
                                                                    o_data_pass         <= "01";                            -- Pass B data through ALU 

                                                                    o_wb_sel            <= c_WB_ALU;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- Add Upper Immediate to PC (AUIPC) Instruction
                                        when c_AUIPC_INST       =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '1';                             -- Set A Data to PC
                                                                    o_b_sel             <= '1';                             -- Set B Data to Immediate

                                                                    o_imm_sel           <= c_U_IMM;                         -- Set Immediate Type to U-Instruction

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '1';                             -- Set Register Write
                                                                    o_data_pass         <= "00";

                                                                    o_wb_sel            <= c_WB_ALU;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                    
                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                        -- System (SYS) Instruction
                                        when c_SYS_INST         =>  --if (r_funct7 = "0011000" AND r_funct3 = "000") then
                                                                    --    o_pc_sel            <= c_PC_MEPC;
                                                                    --else
                                                                        o_pc_sel            <= c_PC_INCR;
                                                                    --end if;
                                                                    o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag
                                                                    

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= r_funct3(2);                     -- Select Immediate for I-type CSR instructions

                                                                    o_imm_sel           <= c_SYS_IMM;                       -- Set Immediate Type to CSR

                                                                    o_funct3            <= r_funct3;
                                                                    o_funct7            <= r_funct7;

                                                                    o_reg_wen           <= '1';                             -- Set Register Write   
                                                                    o_data_pass         <= "01";                            -- Pass B data through ALU  

                                                                    o_wb_sel            <= c_WB_CSR;                        -- Set Writeback to CSR
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');
                                                                    
                                                                    o_csr_en            <= '1';                             -- Enable CSR access 
                                                                    o_csr_sel           <= r_funct3(1 downto 0);            -- Enable CSR select
                                                                    o_csr_imm           <= r_funct3(2);

                                        -- (Default Case)
                                        when others             =>  o_illegal_opcode    <= '1';                             -- Set Illegal Opcode Flag 
                                                                    o_pc_en             <= '0';                             -- Disable Program Count
                                                                    o_pc_sel            <= c_PC_INCR;

                                                                    o_a_sel             <= '0';
                                                                    o_b_sel             <= '0';

                                                                    o_imm_sel           <= c_I_IMM;

                                                                    o_funct3            <= (others => '0');
                                                                    o_funct7            <= (others => '0');

                                                                    o_reg_wen           <= '0';
                                                                    o_data_pass         <= (others => '0');

                                                                    o_wb_sel            <= c_WB_MEM_READ;
                                                                    o_mem_rw_en         <= '0';
                                                                    o_load_size         <= (others => '0');

                                                                    o_csr_en            <= '0';
                                                                    o_csr_sel           <= "00";
                                                                    o_csr_imm           <= '0';

                                    end case;    

            -- Exception State
            when s_EXCEPTION    =>  o_illegal_opcode    <= '0';                             -- Clear Illegal Opcode Flag  
                                    o_pc_en             <= '1';                             -- Enable Program Count
                                    o_pc_sel            <= c_PC_MTVEC;                      -- Set Program Count to MTVEC

                                    o_a_sel             <= '0';
                                    o_b_sel             <= '0';

                                    o_imm_sel           <= c_I_IMM;

                                    o_funct3            <= (others => '0');
                                    o_funct7            <= (others => '0');

                                    o_reg_wen           <= '0';  
                                    o_data_pass         <= (others => '0');

                                    o_wb_sel            <= c_WB_MEM_READ;
                                    o_mem_rw_en         <= '0';
                                    o_load_size         <= (others => '0');

                                    o_csr_en            <= '0';
                                    o_csr_sel           <= "00";
                                    o_csr_imm           <= '0';

                                    o_radpc_active      <= '1';

                                    o_exception_clr     <= '1';
                                    o_mepc_en           <= '1';                             -- Write MEPC

                                    o_arbiter_en        <= '0';
                                    o_scrubber_en       <= '0';

            -- (Default State)
            when others         =>  o_illegal_opcode    <= '1';                             -- Set Illegal Opcode Flag  
                                    o_pc_en             <= '0';                             -- Disable Program Count
                                    o_pc_sel            <= c_PC_INCR;

                                    o_a_sel             <= '0';
                                    o_b_sel             <= '0';

                                    o_imm_sel           <= c_I_IMM;

                                    o_funct3            <= (others => '0');
                                    o_funct7            <= (others => '0');

                                    o_reg_wen           <= '0';  
                                    o_data_pass         <= (others => '0');

                                    o_wb_sel            <= c_WB_MEM_READ;
                                    o_mem_rw_en         <= '0';
                                    o_load_size         <= (others => '0');

                                    o_csr_en            <= '0';
                                    o_csr_sel           <= "00";
                                    o_csr_imm           <= '0';  

                                    o_radpc_active      <= '0';

                                    o_exception_clr     <= '0';
                                    o_mepc_en           <= '0';

                                    o_arbiter_en        <= '0';
                                    o_scrubber_en       <= '0';

        end case;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Decode the instruction
    r_opcode            <= i_opcode;
    r_funct3            <= i_funct3;
    r_funct7            <= i_funct7;

    -- r_exception_flag    <= '1' when (i_exception_flag = '1' AND r_cur_state /= s_FETCH) else
    --                        '0';

    -- Assign internal branch unsigned flag given function 3 code
    r_branch_unsigned   <=  '1'     when( r_funct3 = "110" )    else     
                            '1'     when( r_funct3 = "111" )    else    
                            '0';

    -- Assign output branch unsigned
    o_BrU               <= r_branch_unsigned;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------