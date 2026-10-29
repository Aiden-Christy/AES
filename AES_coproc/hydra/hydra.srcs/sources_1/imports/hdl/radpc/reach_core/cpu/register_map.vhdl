----------------------------------------------------------------------------------------------------------------------------------------
--
--	RISCV PROCESSOR CORE
--  REGISTER MAP
--
--	Created by Chris Major
-- 	6/17/2022
--
--	A handwritten attempt at a functional RISC-V core in VHDL.
--
--  The Register Map handles all the registers within RadPC.
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
--  LIBRARIES
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
--  ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity register_map is
port(
	i_clk						: in	std_logic;											    -- Clock
	i_reset_n					: in	std_logic;											    -- Active Low Reset

    i_addr_D                    : in	std_logic_vector(4 downto 0);                           -- Register D Address
    i_addr_A                    : in	std_logic_vector(4 downto 0);                           -- Register A Address
    i_addr_B                    : in	std_logic_vector(4 downto 0);                           -- Register B Address

    i_data_D                    : in	std_logic_vector(31 downto 0);                          -- Register D Data

    i_reg_rw                    : in	std_logic;                                              -- Register Read/Write Enable  

    o_arb_read				    : out	std_logic_vector(31 downto 0); 						    -- Arbiter Read Data
    i_arb_write					: in	std_logic_vector(31 downto 0); 						    -- Arbiter Write Data
    i_arb_addr					: in	std_logic_vector(4 downto 0);						    -- Arbiter Address
    i_arb_rw					: in	std_logic;											    -- Arbiter Read/Write Enable

    o_data_A                    : out	std_logic_vector(31 downto 0);                          -- Register A Data
    o_data_B                    : out	std_logic_vector(31 downto 0)                           -- Register B Data
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
--  ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture register_map_arch of register_map is

	------------------------------------------------------------------------------------------------------------------------------------
	--  TYPE DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Declare a type array for the registers
    type t_REGISTERS is array (31 downto 0) of std_logic_vector(31 downto 0);


	------------------------------------------------------------------------------------------------------------------------------------
	--  SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Declare array for all 32 data registers
    signal r_registers : t_REGISTERS := (

        others  => x"00000000"

    );


    signal r_addr_D         : integer range 0 to 31;                                                 -- Address D intermediate signal
    signal r_addr_A         : integer range 0 to 31;                                                 -- Address A intermediate signal
    signal r_addr_B         : integer range 0 to 31;                                                 -- Address B intermediate signal

    signal r_addr_arb       : integer range 0 to 31;                                                 -- Arbiter Address intermediate signal


begin

	------------------------------------------------------------------------------------------------------------------------------------
	--  PROCESSES
	------------------------------------------------------------------------------------------------------------------------------------

    -- Process to synchronize register signals
    REG_MAP : process( i_clk, i_reset_n )
    begin

        -- Hold all registers in reset
        if( i_reset_n = '0' ) then
            
            r_registers     <= ( others => x"00000000" );


        -- On rising clock edge ...
        elsif( rising_edge( i_clk) ) then

            -- Assign Arbiter write data to appropriate register
            if( i_arb_rw = '1' ) and ( r_addr_arb > 0 ) then

                r_registers( r_addr_arb )   <= i_arb_write;
                r_registers(0)              <= x"00000000";


            -- Assign input data to appropriate register
            elsif( i_reg_rw = '1' ) and ( r_addr_D > 0 ) then
            
                r_registers( r_addr_D )     <= i_data_D;


            end if;

        end if;

    end process;


	------------------------------------------------------------------------------------------------------------------------------------
	--  SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Assign to ALU Input A
    o_data_A        <=      r_registers(0)          when r_addr_A = 0       else
                            r_registers(1)          when r_addr_A = 1       else
                            r_registers(2)          when r_addr_A = 2       else
                            r_registers(3)          when r_addr_A = 3       else
                            r_registers(4)          when r_addr_A = 4       else
                            r_registers(5)          when r_addr_A = 5       else
                            r_registers(6)          when r_addr_A = 6       else
                            r_registers(7)          when r_addr_A = 7       else
                            r_registers(8)          when r_addr_A = 8       else
                            r_registers(9)          when r_addr_A = 9       else
                            r_registers(10)         when r_addr_A = 10      else
                            r_registers(11)         when r_addr_A = 11      else
                            r_registers(12)         when r_addr_A = 12      else
                            r_registers(13)         when r_addr_A = 13      else
                            r_registers(14)         when r_addr_A = 14      else
                            r_registers(15)         when r_addr_A = 15      else
                            r_registers(16)         when r_addr_A = 16      else
                            r_registers(17)         when r_addr_A = 17      else
                            r_registers(18)         when r_addr_A = 18      else
                            r_registers(19)         when r_addr_A = 19      else
                            r_registers(20)         when r_addr_A = 20      else
                            r_registers(21)         when r_addr_A = 21      else
                            r_registers(22)         when r_addr_A = 22      else
                            r_registers(23)         when r_addr_A = 23      else
                            r_registers(24)         when r_addr_A = 24      else
                            r_registers(25)         when r_addr_A = 25      else
                            r_registers(26)         when r_addr_A = 26      else
                            r_registers(27)         when r_addr_A = 27      else
                            r_registers(28)         when r_addr_A = 28      else
                            r_registers(29)         when r_addr_A = 29      else
                            r_registers(30)         when r_addr_A = 30      else
                            r_registers(31)         when r_addr_A = 31      else
                            x"00000000";


    -- Assign to ALU Input B
    o_data_B        <=      r_registers(0)          when r_addr_B = 0       else
                            r_registers(1)          when r_addr_B = 1       else
                            r_registers(2)          when r_addr_B = 2       else
                            r_registers(3)          when r_addr_B = 3       else
                            r_registers(4)          when r_addr_B = 4       else
                            r_registers(5)          when r_addr_B = 5       else
                            r_registers(6)          when r_addr_B = 6       else
                            r_registers(7)          when r_addr_B = 7       else
                            r_registers(8)          when r_addr_B = 8       else
                            r_registers(9)          when r_addr_B = 9       else
                            r_registers(10)         when r_addr_B = 10      else
                            r_registers(11)         when r_addr_B = 11      else
                            r_registers(12)         when r_addr_B = 12      else
                            r_registers(13)         when r_addr_B = 13      else
                            r_registers(14)         when r_addr_B = 14      else
                            r_registers(15)         when r_addr_B = 15      else
                            r_registers(16)         when r_addr_B = 16      else
                            r_registers(17)         when r_addr_B = 17      else
                            r_registers(18)         when r_addr_B = 18      else
                            r_registers(19)         when r_addr_B = 19      else
                            r_registers(20)         when r_addr_B = 20      else
                            r_registers(21)         when r_addr_B = 21      else
                            r_registers(22)         when r_addr_B = 22      else
                            r_registers(23)         when r_addr_B = 23      else
                            r_registers(24)         when r_addr_B = 24      else
                            r_registers(25)         when r_addr_B = 25      else
                            r_registers(26)         when r_addr_B = 26      else
                            r_registers(27)         when r_addr_B = 27      else
                            r_registers(28)         when r_addr_B = 28      else
                            r_registers(29)         when r_addr_B = 29      else
                            r_registers(30)         when r_addr_B = 30      else
                            r_registers(31)         when r_addr_B = 31      else
                            x"00000000";


    -- Assign to Arbiter Read
    o_arb_read      <=      r_registers(0)          when r_addr_arb = 0     else
                            r_registers(1)          when r_addr_arb = 1     else
                            r_registers(2)          when r_addr_arb = 2     else
                            r_registers(3)          when r_addr_arb = 3     else
                            r_registers(4)          when r_addr_arb = 4     else
                            r_registers(5)          when r_addr_arb = 5     else
                            r_registers(6)          when r_addr_arb = 6     else
                            r_registers(7)          when r_addr_arb = 7     else
                            r_registers(8)          when r_addr_arb = 8     else
                            r_registers(9)          when r_addr_arb = 9     else
                            r_registers(10)         when r_addr_arb = 10    else
                            r_registers(11)         when r_addr_arb = 11    else
                            r_registers(12)         when r_addr_arb = 12    else
                            r_registers(13)         when r_addr_arb = 13    else
                            r_registers(14)         when r_addr_arb = 14    else
                            r_registers(15)         when r_addr_arb = 15    else
                            r_registers(16)         when r_addr_arb = 16    else
                            r_registers(17)         when r_addr_arb = 17    else
                            r_registers(18)         when r_addr_arb = 18    else
                            r_registers(19)         when r_addr_arb = 19    else
                            r_registers(20)         when r_addr_arb = 20    else
                            r_registers(21)         when r_addr_arb = 21    else
                            r_registers(22)         when r_addr_arb = 22    else
                            r_registers(23)         when r_addr_arb = 23    else
                            r_registers(24)         when r_addr_arb = 24    else
                            r_registers(25)         when r_addr_arb = 25    else
                            r_registers(26)         when r_addr_arb = 26    else
                            r_registers(27)         when r_addr_arb = 27    else
                            r_registers(28)         when r_addr_arb = 28    else
                            r_registers(29)         when r_addr_arb = 29    else
                            r_registers(30)         when r_addr_arb = 30    else
                            r_registers(31)         when r_addr_arb = 31    else
                            x"00000000";


    -- Assign intermediate signals
    r_addr_D        <= to_integer( unsigned( i_addr_D ) );
    r_addr_A        <= to_integer( unsigned( i_addr_A ) );
    r_addr_B        <= to_integer( unsigned( i_addr_B ) );

    r_addr_arb      <= to_integer( unsigned( i_arb_addr ) );


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
--  END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------