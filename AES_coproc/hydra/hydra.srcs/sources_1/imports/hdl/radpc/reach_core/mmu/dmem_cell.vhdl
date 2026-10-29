-------------------------------------------------------------------------------------------------------------------------------
--
--	RAM MEMORY TEMPLATE
--
--	Created by Chris Major
-- 	11/17/2021
--
--	A synchronous Random Access Memory (RAM) design with a address validity flag
--  Data is byte-sized (ha ha) to match most conventional BRAM routing strategies
--
--  Data can be pre-loaded into ram_pkg.vhd
--
-------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------
-- LIBRARIES
-------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;

	-- IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;

	-- IEEE Numeric Standard Library
	use IEEE.NUMERIC_STD.ALL;


	-- RadPC Reach Core Package
	use WORK.REACH_CORE_PKG.all;

	-- RadPC Reach Core Memory Package
	use WORK.REACH_MEM_PKG.all;


-------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------------------------------------------------------
entity dmem_cell is
generic ( 
    g_MEM_DATA                      : t_DMEM_RAM                                              	-- Memory initialization data
);
port (
    i_clk                           : in    std_logic;                                          -- Input clock  

    i_A_addr                       	: in    std_logic_vector( 31 downto 0 );                    -- Address (Port A)
    i_A_rw                         	: in    std_logic;                                          -- Read / Write (Port A)
    i_A_data_wr                    	: in    std_logic_vector( 7 downto 0 );                     -- Write Data (Port A)
    o_A_data_rd                   	: out   std_logic_vector( 7 downto 0 );                     -- Read Data (Port A)

    i_B_addr                      	: in    std_logic_vector( 31 downto 0 );                    -- Address (Port B)
    i_B_rw                         	: in    std_logic;                                          -- Read / Write (Port B)
    i_B_data_wr                    	: in    std_logic_vector( 7 downto 0 );                     -- Write Data (Port A)
    o_B_data_rd                   	: out   std_logic_vector( 7 downto 0 )                     	-- Read Data (Port A)
);
end entity;


-------------------------------------------------------------------------------------------------------------------------------
-- 	ARCHITECTURE
-------------------------------------------------------------------------------------------------------------------------------
architecture dmem_cell_arch of dmem_cell is

	---------------------------------------------------------------------------------------------------------------------------
	--	VARIABLE DECLARATIONS
	---------------------------------------------------------------------------------------------------------------------------

    shared variable v_RAM			: t_DMEM_RAM 		:= g_MEM_DATA;							-- DMEM RAM Data


begin

	---------------------------------------------------------------------------------------------------------------------------
	--	MEMORY READ/WRITE PROCESS - PORT A
	---------------------------------------------------------------------------------------------------------------------------

	-- Process to read/write to memory with synchronous control (Port A)
	RAM_RW_PORT_A : process( i_clk )
	begin

		-- On rising clock edge ...
		if( rising_edge( i_clk )) then 

			-- Read Data
			o_A_data_rd		<= v_ram( to_integer( unsigned( i_A_addr) ));

			-- Port A Write Condition
			if( i_A_rw = '1' ) then

				v_ram( to_integer( unsigned( i_A_addr) )) 	:= i_A_data_wr;

			end if;

		end if;

	end process;


	---------------------------------------------------------------------------------------------------------------------------
	--	MEMORY READ/WRITE PROCESS - PORT B
	---------------------------------------------------------------------------------------------------------------------------

	-- Process to read/write to memory with synchronous control (Port B)
	RAM_RW_PORT_B : process( i_clk )
	begin

		-- On rising clock edge ...
		if( rising_edge( i_clk )) then 

			-- Read Data
			o_B_data_rd		<= v_ram( to_integer( unsigned( i_B_addr) ));

			-- Port B Write Condition
			if( i_B_rw = '1' ) then

				v_ram( to_integer( unsigned( i_B_addr) )) 	:= i_B_data_wr;

			end if;

		end if;

	end process;


end architecture;
-------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
-------------------------------------------------------------------------------------------------------------------------------