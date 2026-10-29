----------------------------------------------------------------------------------------------------------------------------------------
--
--!	@file
--!	@brief The Control and Status Registers (CSRs) are used by the processor core to access processor-specific data with special instructions.
--
--  RADPC
--	CONTROL AND STATUS REGISTER (CSR) COMPONENT
--
--	Created by Chris Major, Tristan Running Crane
--  Resilient Computing
-- 	7/19/2022
--
----------------------------------------------------------------------------------------------------------------------------------------

-- RESOURCES:
--  1. http://csg.csail.mit.edu/6.S983/recs/riscv_recitation/
--  2. https://five-embeddev.com/riscv-isa-manual/lar_csr_data_write/csr.html#csr-instructions 
--  3. https://five-embeddev.com/riscv-isa-manual/lar_csr_data_write/priv-csrs.html#csr-address-mapping-conventions 
--  4. https://inst.eecs.berkeley.edu/~eecs151/sp22/


--  How to handle Write vs. Set vs. Clear? ( i_csr_sel ) - Intermediate signals for W/S/C cases that go into process?
--  How to handle address by address basis?


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
entity csr is
port(
    i_clk                       : in	std_logic;                                              --! Clock
    i_reset_n                   : in	std_logic;                                              --! Active Low Reset

    i_csr_addr                  : in    std_logic_vector(11 downto 0);                          --! CSR Address

    i_csr_en                    : in    std_logic;                                              --! CSR Enable
    i_csr_sel                   : in    std_logic_vector(1 downto 0);                           --! CSR Operation
    i_csr_data_write            : in    std_logic_vector(31 downto 0);                          --! CSR Write Data

    o_csr_data_read             : out   std_logic_vector(31 downto 0);                          --! CSR Read Data

    i_illegal_opcode            : in    std_logic;                                              -- Illegal Opcode Flag
    i_illegal_pc                : in    std_logic;                                              -- Illegal Program Count Flag

    i_sem_status                : in 	std_logic_vector(7 downto 0);                           --! SEM Status Pins
    o_runtime_stat              : out   std_logic_vector(31 downto 0);                          --! Runtime Status
    i_bootload_en               : in    std_logic;                                              --! Bootload Enable

    i_pc                        : in    std_logic_vector(31 downto 0);                          --! Program Count
    i_mepc_en                   : in    std_logic;                                              --! MEPC Write Enable

    i_gpio_00_irq               : in    std_logic;                                              --! GPIO 00 Interrupt Signal
    i_gpio_01_irq               : in    std_logic;                                              --! GPIO 01 Interrupt Signal
    i_uart_00_irq               : in    std_logic;                                              --! UART 00 Interrupt Signal
    i_uart_01_irq               : in    std_logic;                                              --! UART 01 Interrupt Signal
    i_timer_00_irq              : in    std_logic;                                              --! Timer 00 Interrupt Signal
    i_timer_01_irq              : in    std_logic;                                              --! Timer 01 Interrupt Signal
    i_spi_00_irq                : in    std_logic;                                              --! SPI 00 Interrupt Signal
    i_spi_01_irq                : in    std_logic;                                              --! SPI 00 Interrupt Signal
    i_i2c_00_irq                : in    std_logic;                                              --! I2C 00 Interrupt Signal
    i_i2c_01_irq                : in    std_logic;                                              --! I2C 01 Interrupt Signal

    i_exception_clr             : in    std_logic;                                              --! Exception Clear
    o_exception_flag            : out   std_logic;                                              --! Exception Flag
    o_mtvec                     : out   std_logic_vector(31 downto 0);                          --! Machine Trap Vector (MTVEC) Value
    o_mepc                      : out   std_logic_vector(31 downto 0)                           --! MEPC Value
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture csr_arch of csr is

    ------------------------------------------------------------------------------------------------------------------------------------
    --  TYPE DECLARATIONS
    ------------------------------------------------------------------------------------------------------------------------------------

    -- Type for Finite State Machine (FSM) States
    type t_State is ( 
        s_START,
        s_WAIT,
        s_RAISE,
        s_DIAGNOSE,
        s_RAISE_ILLEGAL,
        s_RAISE_TIMER,
        s_RAISE_EXTERNAL,
        s_RAISE_INSTR_ACCESS,
        s_SERVICE_ILLEGAL,
        s_SERVICE_TIMER,
        s_SERVICE_EXTERNAL,
        s_SERVICE_INSTR_ACCESS
    );   


	------------------------------------------------------------------------------------------------------------------------------------
	-- CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    constant c_MSTATUS_ADDR             : std_logic_vector(11 downto 0)     := x"300";                      -- MSTATUS CSR Address
    constant c_MISA_ADDR                : std_logic_vector(11 downto 0)     := x"301";                      -- MISA CSR Address
    constant c_MEDELEG_ADDR             : std_logic_vector(11 downto 0)     := x"302";                      -- MEDELEG CSR ADdress
    constant c_MIE_ADDR                 : std_logic_Vector(11 downto 0)     := x"304";                      -- MIE CSR Address
    constant c_MTVEC_ADDR               : std_logic_vector(11 downto 0)     := x"305";                      -- MTVEC CSR Address
    constant c_MSCRATCH_ADDR            : std_logic_vector(11 downto 0)     := x"340";                      -- MSCRATCH CSR Address
    constant c_MEPC_ADDR                : std_logic_vector(11 downto 0)     := x"341";                      -- MEPC CSR Address
    constant c_MCAUSE_ADDR              : std_logic_vector(11 downto 0)     := x"342";                      -- MCAUSE CSR Address
    constant c_MIP_ADDR                 : std_logic_vector(11 downto 0)     := x"344";                      -- MIP CSR Address

    constant c_MAIN_PC                  : std_logic_vector(11 downto 0)     := x"BC0";                      -- Main PC CSR Address
    constant c_INTR_PC                  : std_logic_vector(11 downto 0)     := x"BC1";                      -- Interrupt PC CSR Address

    constant c_SEMSTAT_ADDR             : std_logic_vector(11 downto 0)     := x"FC0";                      -- SEMSTAT CSR Address (Custom)
    constant c_RUNTIME_ADDR             : std_logic_vector(11 downto 0)     := x"FFE";                      -- RUNTIME CSR Address (Custom)
    constant c_BOOT_EN_ADDR             : std_logic_vector(11 downto 0)     := x"FFF";                      -- BOOTEN CSR Address (Custom)


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    signal r_cur_state                  : t_State                           := s_START;                     --! Finite State Machine (FSM) Current State
    signal r_nxt_state                  : t_State                           := s_START;                     --! Finite State Machine (FSM) Next State

    signal r_csr_mstatus                : std_logic_vector(31 downto 0)     := x"00000000";                 --! CSR MSTATUS register]
    signal r_csr_misa                   : std_logic_vector(31 downto 0)     := x"00000000";                 --! Machine ISA (MISA) CSR register
    signal r_csr_mie                    : std_logic_vector(31 downto 0)     := x"00000000";                 --! Machine Interrupt Enable (MIE) register
    signal r_csr_mtvec                  : std_logic_vector(31 downto 0)     := x"00000000";                 --! Machine Trap Vector Control (MTVEC) register
    signal r_csr_mscratch               : std_logic_vector(31 downto 0)     := x"00000000";                 --! Machine Scratch (MSCRATCH) register
    signal r_csr_mepc                   : std_logic_vector(31 downto 0)     := x"00000000";                 --! Machine Exception Program Counter (MEPC) register
    signal r_csr_mcause                 : std_logic_vector(31 downto 0)     := x"00000000";                 --! Machine Exception Cause (MCAUSE) register

    signal r_csr_main_pc                : std_logic_vector(31 downto 0)     := x"00000000";                 -- Main CSR PC
    signal r_csr_intr_pc                : std_logic_vector(31 downto 0)     := x"00000000";                 -- Interrupt CSR PC

    signal r_csr_runtime                : std_logic_vector(31 downto 0)     := x"00000000";                 --! Runtime Status (RUNTIME) register
    signal r_csr_boot_en                : std_logic_vector(31 downto 0)     := x"00000000";                 --! Boot Enable (BOOTEN) register

    signal r_mcause_write               : std_logic_vector(31 downto 0)     := x"00000000";                 --! Machine Exception Program Counter (MEPC) update value

    signal r_trap                       : std_logic;                                                        --! Trap Signal
    signal r_exception                  : std_logic;                                                        --! Synchronus Exception Signal Register
    signal r_itnr                       : std_logic;                                                        --! Machine Interrupt Signal Register
    signal r_external_itnr              : std_logic;                                                        --! Machine External Interrupt flag    
    signal r_timer_itnr                 : std_logic;                                                        --! Machine Timer Interrupt flag

    signal r_exception_flag             : std_logic;
    signal w_mstatus_rw                 : std_logic;

    signal w_mcause_rw                  : std_logic;                                                        --! MCAUSE Write Signal


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- PROCESSES
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to read CSR Registers
    READ_CSR_00 : process( i_clk, i_reset_n )
    begin

        -- On reset ...
        if( i_reset_n = '0' ) then
            
            -- Clear read data
            o_csr_data_read     <= (others => '0');


        -- On clock edge ...
        elsif( rising_edge( i_clk ) ) then

            -- Evaluate current CSR address
            case( i_csr_addr ) is

                -- Machine Status (MSTATUS) CSR
                when c_MSTATUS_ADDR         =>  o_csr_data_read         <= r_csr_mstatus;

                -- Machine ISA (MISA) CSR
                when c_MISA_ADDR            =>  o_csr_data_read         <= r_csr_misa;

                -- Machine Interrupt Enable (MIE) CSR
                when c_MIE_ADDR             =>  o_csr_data_read         <= r_csr_mie;

                -- Machine Trap Vector (MTVEC) CSR
                when c_MTVEC_ADDR           =>  o_csr_data_read         <= r_csr_mtvec; 

                -- Machine Scratch (MSCRATCH) CSR
                when c_MSCRATCH_ADDR        =>  o_csr_data_read         <= r_csr_mscratch;

                -- Machine Exception Program Counter (MEPC) CSR
                when c_MEPC_ADDR            =>  o_csr_data_read         <= r_csr_mepc;

                -- Machine Exception Cause (MCAUSE) CSR
                when c_MCAUSE_ADDR          =>  o_csr_data_read         <= r_csr_mcause;

                -- SEM Status (SEMSTAT) CSR
                when c_SEMSTAT_ADDR         =>  o_csr_data_read         <= x"000000" & i_sem_status;

                -- Runtime Status (RUNTIME) CSR
                when c_RUNTIME_ADDR         =>  o_csr_data_read         <= r_csr_runtime;

                -- Bootload Enable (BOOTEN) CSR
                when c_BOOT_EN_ADDR         =>  o_csr_data_read         <= r_csr_boot_en;

                -- Main PC CSR
                when c_MAIN_PC              =>  o_csr_data_read         <= r_csr_main_pc;

                -- Interrupt PC CSR
                when c_INTR_PC              =>  o_csr_data_read         <= r_csr_intr_pc;

                -- (Default Case)
                when others                 =>  o_csr_data_read         <= (others => '0');  

            end case;

        end if;

    end process;


    -- Process to write CSR Registers
    WRITE_CSR_00 : process( i_clk, i_reset_n, i_csr_en, i_csr_addr, i_csr_sel )
        variable    v_csr_mstatus_mie   :   std_logic := '0';
        variable    v_csr_mstatus_mpie  :   std_logic := '0';
    begin

        -- On reset ...
        if( i_reset_n = '0' ) then
            
            -- Reset all CSR Registers
            r_csr_mstatus               <= ( others => '0');
            r_csr_misa                  <= "000000000" & c_V_SUPPORT & "10100000" & c_M_SUPPORT & "0000" & c_I_SUPPORT & c_H_SUPPORT & c_G_SUPPORT & c_F_SUPPORT & '0' & c_D_SUPPORT & c_C_SUPPORT & c_B_SUPPORT & c_A_SUPPORT;
            r_csr_mie                   <= ( others => '0' ); 
            r_csr_mtvec                 <= std_logic_vector(c_IMEM_START + to_unsigned(c_IMEM_SIZE, 32) - 4); --( others => '0' ); 
            r_csr_mscratch              <= ( others => '0' ); 
            r_csr_mepc                  <= ( others => '0' ); 
            r_csr_mcause                <= ( others => '0' ); 

            r_csr_runtime               <= ( others => '0' ); 
            r_csr_boot_en(31 downto 1)  <= ( others => '0' ); 


        -- On clock edge ...
        elsif( rising_edge( i_clk ) ) then

            v_csr_mstatus_mie   := r_csr_mstatus(3);
            v_csr_mstatus_mpie  := r_csr_mstatus(7);

            -- If CSR RW is set to WRITE (1) ...
            if ( i_csr_en = '1' ) then

                -- Evaluate current CSR address
                case( i_csr_addr ) is

                    -- Machine STATUS (MSTATUS) CSR
                    when c_MSTATUS_ADDR         =>  if( i_csr_sel = c_CSR_WRITE) then
                                                        r_csr_mstatus                   <= i_csr_data_write;
                                                    elsif( i_csr_sel = c_CSR_SET) then
                                                        r_csr_mstatus                   <= r_csr_mstatus or i_csr_data_write;
                                                    elsif( i_csr_sel = c_CSR_CLEAR) then
                                                        r_csr_mstatus                   <= r_csr_mstatus and i_csr_data_write;
                                                    end if;

                    when c_MEDELEG_ADDR         =>  --MRET FUNCTIONALITY
                                                    if(v_csr_mstatus_mpie = '1') then
                                                        r_csr_mstatus(3) <= '1';
                                                        r_csr_mstatus(7) <= '0';
                                                    end if;

                    -- Machine ISA (MISA) CSR
                    when c_MISA_ADDR            =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_misa(21)                  <= i_csr_data_write(21);                        -- Only write User (U) Bit 
                                                        r_csr_misa(19)                  <= i_csr_data_write(19);                        -- Only write Supervisor (S) Bit

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_misa(21)                  <= r_csr_misa(21) or i_csr_data_write(21);      -- Only mask User (U) Bit 
                                                        r_csr_misa(19)                  <= r_csr_misa(19) or i_csr_data_write(19);      -- Only mask Supervisor (S) Bit

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_misa(21)                  <= r_csr_misa(21) and i_csr_data_write(21);     -- Only mask User (U) Bit 
                                                        r_csr_misa(19)                  <= r_csr_misa(19) and i_csr_data_write(19);     -- Only mask Supervisor (S) Bit

                                                    end if;

                    -- Machine Interrupt Enable (MIE) CSR
                    when c_MIE_ADDR             =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_mie                       <= i_csr_data_write;                            -- Write entire MIE CSR

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_mie                       <= r_csr_mie or i_csr_data_write;               -- Mask entire MIE CSR with write value (SET)

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_mie                       <= r_csr_mie and i_csr_data_write;              -- Mask entire MIE CSR with write value (CLEAR)

                                                    end if;

                    -- Machine Trap Vector (MTVEC) CSR
                    when c_MTVEC_ADDR           =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_mtvec                     <= i_csr_data_write;                            -- Write entire MTVEC CSR

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_mtvec                     <= r_csr_mtvec or i_csr_data_write;             -- Mask entire MTVEC CSR with write value (SET)

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_mtvec                     <= r_csr_mtvec and i_csr_data_write;            -- Mask entire MTVEC CSR with write value (CLEAR)

                                                    end if;

                    -- Machine Scratch (MSCRATCH) CSR
                    when c_MSCRATCH_ADDR        =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_mscratch                  <= i_csr_data_write;                            -- Write entire MSCRATCH CSR

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_mscratch                  <= r_csr_mscratch or i_csr_data_write;          -- Mask entire MSCRATCH CSR with write value (SET)

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_mscratch                  <= r_csr_mscratch and i_csr_data_write;         -- Mask entire MSCRATCH CSR with write value (CLEAR)

                                                    end if;

                    -- Machine Exception Program Counter (MEPC) CSR
                    when c_MEPC_ADDR            =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_mepc                      <= i_csr_data_write;                            -- Write entire MEPC CSR

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_mepc                      <= r_csr_mepc or i_csr_data_write;              -- Mask entire MEPC CSR with write value (SET)

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_mepc                      <= r_csr_mepc and i_csr_data_write;             -- Mask entire MEPC CSR with write value (CLEAR)

                                                    end if;

                    -- Machine Exception Cause (MCAUSE) CSR
                    when c_MCAUSE_ADDR          =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_mcause                    <= i_csr_data_write;                            -- Write entire MCAUSE CSR

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_mcause                    <= r_csr_mcause or i_csr_data_write;            -- Mask entire MCAUSE CSR with write value (SET)

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_mcause                    <= r_csr_mcause and i_csr_data_write;           -- Mask entire MCAUSE CSR with write value (CLEAR)

                                                    end if;

                    -- Runtime Status (RUNTIME) CSR
                    when c_RUNTIME_ADDR         =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_runtime                   <= i_csr_data_write;                            -- Write entire RUNTIME CSR

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_runtime                   <= r_csr_runtime or i_csr_data_write;           -- Mask entire RUNTIME CSR with write value (SET)

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_runtime                   <= r_csr_runtime and i_csr_data_write;          -- Mask entire RUNTIME CSR with write value (CLEAR)

                                                    end if;


                    -- Bootload Enable (BOOTEN) CSR
                    when c_BOOT_EN_ADDR         =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_boot_en(31 downto 1)      <= i_csr_data_write(31 downto 1);                                       -- Write upper 31 bits of BOOTEN CSR

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_boot_en(31 downto 1)      <= r_csr_boot_en(31 downto 1) or i_csr_data_write(31 downto 1);         -- Mask upper 31 bits of BOOTEN CSR with write value (SET)

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_boot_en(31 downto 1)      <= r_csr_boot_en(31 downto 1) and i_csr_data_write(31 downto 1);        -- Mask upper 31 bits of BOOTEN CSR with write value (CLEAR)

                                                    end if;

                    -- Main PC CSR
                    when c_MAIN_PC              =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_main_pc                   <= i_csr_data_write;                            -- Write entire Main PC CSR

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_main_pc                   <= r_csr_main_pc or i_csr_data_write;           -- Mask entire Main PC CSR with write value (SET)

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_main_pc                   <= r_csr_main_pc and i_csr_data_write;          -- Mask entire Main PC CSR with write value (CLEAR)

                                                    end if;

                    -- Interrupt PC CSR
                    when c_INTR_PC              =>  if( i_csr_sel = c_CSR_WRITE ) then
                                                        r_csr_intr_pc                   <= i_csr_data_write;                            -- Write entire Interrupt PC CSR

                                                    elsif( i_csr_sel = c_CSR_SET ) then
                                                        r_csr_intr_pc                   <= r_csr_intr_pc or i_csr_data_write;           -- Mask entire Interrupt PC CSR with write value (SET)

                                                    elsif( i_csr_sel = c_CSR_CLEAR ) then
                                                        r_csr_intr_pc                   <= r_csr_intr_pc and i_csr_data_write;          -- Mask entire Interrupt PC CSR with write value (CLEAR)

                                                    end if;


                    -- (Default Case)
                    when others                 =>  -- Do Nothing

                end case;

            end if;

            -- Update all CSR registers not actively written by the program
            if( i_mepc_en = '1' ) then
                r_csr_mepc      <= i_pc; 

            end if;

            if( w_mstatus_rw = '1') then
                if(v_csr_mstatus_mie = '1') then
                    r_csr_mstatus(7)   <=   '1';
                    r_csr_mstatus(3)   <=   '0';
                end if;            
            end if;
            
            if( w_mcause_rw = '1' ) then
                r_csr_mcause    <= r_mcause_write;

            end if;

            
        end if;

    end process;


    ------------------------------------------------------------------------------------------------------------------------------------
	--  TRAP HANDLER UNIT STATE MACHINE - STATE MEMORY LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle state memory 
    TRAP_FSM_STATE_MEMORY_00 : process( i_clk, i_reset_n )
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
	--  TRAP HANDLER STATE MACHINE - NEXT STATE LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle current state
    TRAP_FSM_CURRENT_STATE_00 : process( r_cur_state, i_illegal_opcode, r_trap, i_exception_clr, r_timer_itnr, r_external_itnr )
    begin

        -- Handle current state
        case( r_cur_state ) is

            -- Start State
            when s_START                    =>  r_nxt_state         <= s_WAIT;

            -- Wait State
            when s_WAIT                     =>  if( r_trap = '1' ) then
                                                    r_nxt_state         <= s_RAISE;
                                                    
                                                else
                                                    r_nxt_state         <= s_WAIT;

                                                end if;

            -- Raise Exception State
            when s_RAISE                    =>  if( i_exception_clr = '1' ) then
                                                    r_nxt_state         <= s_DIAGNOSE;

                                                else
                                                    r_nxt_state         <= s_RAISE;

                                                end if;

            -- Diagnose Exception State
            when s_DIAGNOSE                 =>  if( i_illegal_opcode = '1' ) then
                                                    r_nxt_state         <= s_RAISE_ILLEGAL;

                                                elsif( r_timer_itnr = '1' ) then
                                                    r_nxt_state         <= s_RAISE_TIMER;

                                                elsif( r_external_itnr = '1') then
                                                    r_nxt_state         <= s_RAISE_EXTERNAL;

                                                elsif( i_illegal_pc = '1') then
                                                    r_nxt_state         <= s_RAISE_INSTR_ACCESS;

                                                else
                                                    r_nxt_state         <= s_WAIT;

                                                end if;


            -- Raise Illegal Opcode Exception
            when s_RAISE_ILLEGAL            =>  r_nxt_state         <= s_SERVICE_ILLEGAL;

            -- Service Illegal Opcode Exception
            when s_SERVICE_ILLEGAL          =>  if( i_illegal_opcode = '0' ) then
                                                    r_nxt_state         <= s_WAIT;  
                                                
                                                else
                                                    r_nxt_state         <= s_SERVICE_ILLEGAL;

                                                end if;

            -- Raise Timer Interrupt Exception
            when s_RAISE_TIMER              =>  r_nxt_state         <= s_SERVICE_TIMER;

            -- Service Timer Interrupt Exception
            when s_SERVICE_TIMER            =>  if( r_timer_itnr = '0') then
                                                    r_nxt_state         <= s_WAIT;
                                                
                                                else
                                                    r_nxt_state        <= s_SERVICE_TIMER;
                                                
                                                end if;

            -- Raise External Interrupt Exception
            when s_RAISE_EXTERNAL           =>  r_nxt_state         <= s_SERVICE_EXTERNAL;

            -- Service Illegal Opcode Exception
            when s_SERVICE_EXTERNAL         =>  if( r_external_itnr = '0' ) then
                                                    r_nxt_state         <= s_WAIT;  
                                                
                                                else
                                                    r_nxt_state         <= s_SERVICE_EXTERNAL;

                                                end if;

            -- Raise Instruction Access Exception
            when s_RAISE_INSTR_ACCESS       =>  r_nxt_state         <= s_SERVICE_INSTR_ACCESS;

            -- Service Instruction Access Exception
            when s_SERVICE_INSTR_ACCESS     =>  if( i_illegal_pc = '0' ) then
                                                    r_nxt_state         <= s_WAIT;  
                                                
                                                else
                                                    r_nxt_state         <= s_SERVICE_INSTR_ACCESS;

                                                end if;

            -- (Default State)
            when others                     =>      r_nxt_state         <= s_START;

        end case;

    end process;


    ------------------------------------------------------------------------------------------------------------------------------------
	--  TRAP HANDLER STATE MACHINE - OUTPUT LOGIC
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to handle output logic
    TRAP_FSM_OUTPUT_LOGIC_00 : process( r_cur_state )
    begin

        -- Handle current state
        case( r_cur_state ) is

            -- Start State
            when s_START                    =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '0';
                                                w_mcause_rw         <= '0';
                                                r_mcause_write     <= ( others => '0' );   

            -- Wait State
            when s_WAIT                     =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '0';
                                                w_mcause_rw         <= '0';
                                                r_mcause_write     <= ( others => '0' );   

            -- Raise Exception State
            when s_RAISE                    =>  r_exception_flag    <= '1';
                                                w_mstatus_rw        <= '0';
                                                w_mcause_rw         <= '0';
                                                r_mcause_write     <= ( others => '0' );   

            -- Diagnose Exception State
            when s_DIAGNOSE                 =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '0';
                                                w_mcause_rw         <= '0';
                                                r_mcause_write      <= ( others => '0' );   

            -- Raise Illegal Opcode Exception
            when s_RAISE_ILLEGAL            =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '0';
                                                w_mcause_rw         <= '1';
                                                r_mcause_write      <= x"00000002"; 
                                                
            -- Service Illegal Opcode Exception
            when s_SERVICE_ILLEGAL          =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '0';  
                                                w_mcause_rw         <= '0';
                                                r_mcause_write      <= x"00000002"; 
            
            -- Raise Timer Interrupt Exception
            when s_RAISE_TIMER              => r_exception_flag     <= '0';
                                                w_mstatus_rw        <= '1';
                                                w_mcause_rw         <= '1';
                                                r_mcause_write      <= x"80000007";

            -- Service Timer Interrupt Exception
            when s_SERVICE_TIMER            => r_exception_flag     <= '0';
                                                w_mstatus_rw        <= '0';
                                                w_mcause_rw         <= '0';
                                                r_mcause_write      <= x"80000007";

            -- Raise External Interrupt Exception
            when s_RAISE_EXTERNAL           =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '1';
                                                w_mcause_rw         <= '1';
                                                r_mcause_write      <= x"8000000B";

            -- Service External Interrupt Exception
            when s_SERVICE_EXTERNAL         =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '0';
                                                w_mcause_rw         <= '0';
                                                r_mcause_write      <= x"8000000B";

            -- Raise Instruction Access Exception
            when s_RAISE_INSTR_ACCESS       =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '0';
                                                w_mcause_rw         <= '1';
                                                r_mcause_write      <= x"00000001";  

            -- Service Instruction Access Exception
            when s_SERVICE_INSTR_ACCESS     =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '0';  
                                                w_mcause_rw         <= '0';
                                                r_mcause_write      <= x"00000001"; 


            -- (Default State)
            when others                     =>  r_exception_flag    <= '0';
                                                w_mstatus_rw        <= '0';
                                                w_mcause_rw         <= '0';
                                                r_mcause_write     <= ( others => '0' );  

        end case;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Tied Exception flag to the machine interrupt enable bit
    o_exception_flag            <= r_exception_flag;

    -- Write BOOTLOAD ENABLE to register
    r_csr_boot_en(0)            <= i_bootload_en;

    -- Write Runtime Status to outputs
    o_runtime_stat              <= r_csr_runtime;

    -- Assign Machine Exception Program Count to output
    o_mtvec                     <= r_csr_mtvec;
    o_mepc                      <= r_csr_mepc;

    -- Assign Machine External Interrupt Register
    r_external_itnr             <= r_csr_mie(11) and ( i_gpio_00_irq OR i_gpio_01_irq OR i_uart_00_irq OR i_uart_01_irq OR i_spi_00_irq OR i_spi_01_irq OR i_i2c_00_irq OR i_i2c_01_irq ); 

    -- Assign Machine Timer Interrupt Register
    r_timer_itnr                <= r_csr_mie(7) and ( i_timer_00_irq OR i_timer_01_irq );

    -- Assign Interrupt Signal Register
    r_itnr                      <= (r_external_itnr AND r_csr_mstatus(3)) or (r_timer_itnr AND r_csr_mstatus(3));

    -- Assign Synchronus Exception Signal Register
    r_exception                 <= i_illegal_opcode or i_illegal_pc;

    -- Assign Trap Signal Register
    r_trap                      <= r_exception or r_itnr;



    -- --Write Machine Timer Interrupt Register
    -- r_csr_MTI               <= r_csr_mie(7)         AND ( i_timer_00_irq OR i_timer_01_irq );

    -- --Write Machine External Interrupt Register
    -- r_csr_MEI               <= r_csr_mie(11)        AND ( i_gpio_00_irq OR i_gpio_01_irq OR i_uart_00_irq OR i_uart_01_irq OR i_spi_00_irq OR i_spi_01_irq OR i_i2c_00_irq OR i_i2c_01_irq );


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------

