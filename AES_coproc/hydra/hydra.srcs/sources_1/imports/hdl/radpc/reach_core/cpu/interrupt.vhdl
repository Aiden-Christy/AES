-- IEEE Standard Library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- IEEE Numeric Standard Library
use IEEE.NUMERIC_STD.ALL;

-- RadPC Reach Core Library
use work.rv_reach_pkg.all;


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity interrupts is
port(
    i_clk                       : in	std_logic;                                              --! Clock
    i_reset_n                   : in	std_logic;                                              --! Active Low Reset
    i_irq                       : in    std_logic;                                              --! Incoming IRQ

    i_arbiter_write_en          : in    std_logic;                                              --! Arbiter Write Signal
    i_csr_xret                  : in    std_logic;                                              --! System xRET Enable

    o_irq                       : out   std_logic;                                              --! Interrupt Request Signal Synchronized
    o_irq_latch                 : out   std_logic;                                              --! Interrupt Request Latch Signal
    o_instruction               : out   std_logic_vector(31 downto 0);                          --! Instruction Inserted into Control Unit
    o_xret                      : out   std_logic                                               --! System xRET Enable Synchronized
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture interrupts_arch of interrupts is

	------------------------------------------------------------------------------------------------------------------------------------
	-- TYPE DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    --Type for States
    type t_State is (
        s_IDLE,
        s_MEPC,
        s_MEPC_DEL,
        s_MTVEC,
        s_IRQ,
        s_RET
    );

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    signal r_cur_state      : t_State                                       := s_IDLE;                       -- Current machine state
    signal r_next_state     : t_State                                       := s_IDLE;                       -- Next machine state

    signal r_clk_n          : std_logic                                     := '1';

begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- PROCESSES
	------------------------------------------------------------------------------------------------------------------------------------

    process( i_clk, i_reset_n )
    begin

        if( i_reset_n = '0') then

            r_clk_n     <= '1';

        elsif(rising_edge(i_clk)) then

            r_clk_n     <= not r_clk_n;

        end if;

    end process;

    STATE_MEMORY : process( r_clk_n, i_reset_n )
    begin

        -- On reset
        if( i_reset_n = '0') then

            r_cur_state     <=  s_IDLE;

        elsif( rising_edge(r_clk_n) ) then

            r_cur_state     <= r_next_state;

        end if;

    end process;

    NEXT_STATE_LOGIC : process( r_cur_state, i_arbiter_write_en, i_irq, i_csr_xret )
    begin

        case(r_cur_state) is

            when s_IDLE     =>  if(i_irq = '1') then

                                    r_next_state    <=  s_MEPC;

                                else

                                    r_next_state    <=  s_IDLE;

                                end if;

            when s_MEPC     =>  r_next_state    <=  s_MEPC_DEL;     -- s_MTVEC;

            when s_MEPC_DEL =>  r_next_state    <=  s_MTVEC;        -- Just Added


            when s_MTVEC    =>  r_next_state    <=  s_IRQ;


            when s_IRQ      =>  if(i_csr_xret = '1') then

                                    r_next_state    <=  s_RET;

                                else
                                    r_next_state    <=  s_IRQ;

                                end if;

            when s_RET      =>  r_next_state    <=  s_IDLE;

            when others     =>  r_next_state <= s_IDLE;

        end case;

    end process;

    OUTPUT_LOGIC: process( r_cur_state, i_arbiter_write_en, i_irq, i_csr_xret )
    begin

        case (r_cur_state) is

            when s_IDLE     =>  o_irq               <= '0';
                                o_irq_latch         <= '0';
                                o_instruction       <= x"00000013";                     -- addi x0, x0, 0
                                o_xret              <= '0';

            when s_MEPC     =>  o_irq               <= '1';
                                o_irq_latch         <= '0';
                                o_instruction       <= x"34101073";                     -- csrrw x0, mepc, x0
                                o_xret              <= '0';

            -- Just Added
            when s_MEPC_DEL =>  o_irq               <= '0';
                                o_irq_latch         <= '0';
                                o_instruction       <= x"00000013";                     -- addi x0, x0, 0
                                o_xret              <= '0';

            when s_MTVEC    =>  o_irq               <= '1';
                                o_irq_latch         <= '0';
                                o_instruction       <= x"30502073";                     -- csrrs x0, mtvec, x0
                                o_xret              <= '0';

            when s_IRQ      =>  o_irq               <= '0';
                                o_irq_latch         <= '1';
                                o_instruction       <= x"00000013";                     -- addi x0, x0, 0
                                o_xret              <= '0';

            when s_RET      =>  o_irq               <= '0';
                                o_irq_latch         <= '0';
                                o_instruction       <= x"00000013";                     -- addi x0, x0, 0
                                o_xret              <= '1';

            when others     =>  o_irq               <= '0';
                                o_irq_latch         <= '0';
                                o_instruction       <= x"00000013";                     -- addi x0, x0, 0
                                o_xret              <= '0';

        end case;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------