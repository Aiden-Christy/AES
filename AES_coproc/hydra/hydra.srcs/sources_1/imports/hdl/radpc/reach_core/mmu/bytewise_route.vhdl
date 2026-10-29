----------------------------------------------------------------------------------------------------------------------------------------
--
--!	@file
--!	@brief A component to handle bytewise data read/write between data components
--
--	MEMORY BYTEWISE DATA ROUTING  
--
--	Created by Chris Major
-- 	11/17/2021
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
entity bytewise_route is
generic(
	g_MAX_MEM_ADDR				: integer	:= 1024												-- Max Memory Address Value
);
port (
	i_addr						: in 	std_logic_vector(31 downto 0);						    -- Address
	i_rw_en						: in	std_logic;												-- Read/Write
	i_data_width				: in	std_logic_vector(2 downto 0);							-- Data Width

	i_data_write				: in    std_logic_vector(31 downto 0);                     		-- Data in

	i_cell_read_00				: in	std_logic_vector(7 downto 0);						   	-- Memory Device Data Out 00
	i_cell_read_01				: in	std_logic_vector(7 downto 0);						   	-- Memory Device Data Out 01
	i_cell_read_02				: in	std_logic_vector(7 downto 0);						   	-- Memory Device Data Out 02
	i_cell_read_03				: in	std_logic_vector(7 downto 0);						   	-- Memory Device Data Out 03

	o_cell_addr_00				: out 	std_logic_vector(31 downto 0);							-- Memory Cell 00 Address
	o_cell_addr_01				: out 	std_logic_vector(31 downto 0);							-- Memory Cell 01 Address
	o_cell_addr_02				: out 	std_logic_vector(31 downto 0);							-- Memory Cell 02 Address
	o_cell_addr_03				: out 	std_logic_vector(31 downto 0);							-- Memory Cell 03 Address

	o_cell_rw_00				: out	std_logic;												-- Memory Device Read/Write 00
	o_cell_rw_01				: out	std_logic;												-- Memory Device Read/Write 01
	o_cell_rw_02				: out	std_logic;												-- Memory Device Read/Write 02
	o_cell_rw_03				: out	std_logic;												-- Memory Device Read/Write 03

	o_cell_write_00				: out	std_logic_vector(7 downto 0);						    -- Memory Device Data In 00
	o_cell_write_01				: out	std_logic_vector(7 downto 0);						    -- Memory Device Data In 01
	o_cell_write_02				: out	std_logic_vector(7 downto 0);						    -- Memory Device Data In 02
	o_cell_write_03				: out	std_logic_vector(7 downto 0);						    -- Memory Device Data In 03

	o_data_read					: out	std_logic_vector(31 downto 0)                     		-- Data out
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- 	ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture bytewise_route_arch of bytewise_route is

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	CONSTANT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	constant c_CELL_SIZE 		: integer	:= (g_MAX_MEM_ADDR / 4);							-- Size of Memory Cell


	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_addr 				: unsigned(29 downto 0);										-- Global Address
	signal r_addr_nxt 			: unsigned(29 downto 0);										-- Global Address (Look-Ahead Value)

	signal r_cell_addr_00		: unsigned(31 downto 0);										-- Cell 00 Local Address
	signal r_cell_addr_01		: unsigned(31 downto 0);										-- Cell 01 Local Address
	signal r_cell_addr_02		: unsigned(31 downto 0);										-- Cell 02 Local Address
	signal r_cell_addr_03		: unsigned(31 downto 0);										-- Cell 03 Local Address

	signal w_rw_00				: std_logic;													-- Cell 00 Read/Write
	signal w_rw_01				: std_logic;													-- Cell 01 Read/Write
	signal w_rw_02				: std_logic;													-- Cell 02 Read/Write
	signal w_rw_03				: std_logic;													-- Cell 03 Read/Write

	signal r_cell_rd_00			: std_logic_vector(7 downto 0);									-- Cell 00 Read Data
	signal r_cell_rd_01			: std_logic_vector(7 downto 0);									-- Cell 00 Read Data
	signal r_cell_rd_02			: std_logic_vector(7 downto 0);									-- Cell 00 Read Data
	signal r_cell_rd_03			: std_logic_vector(7 downto 0);									-- Cell 00 Read Data

	signal r_data_read			: std_logic_vector(31 downto 0);								-- Direct Memory Cell Read Value


begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	MEMORY CELL ADDRESSES
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign global address
	r_addr		<= unsigned( i_addr(31 downto 2 ) );

	-- Assign look-ahead address
	r_addr_nxt	<= unsigned( i_addr(31 downto 2 ) ) + 1;



	r_cell_addr_00	<= 	( "00" & r_addr )		when ( i_addr(1 downto 0) = "00" ) else
						( "00" & r_addr_nxt) 	when ( i_addr(1 downto 0) = "01" ) else
						( "00" & r_addr_nxt) 	when ( i_addr(1 downto 0) = "10" ) else
						( "00" & r_addr_nxt) 	when ( i_addr(1 downto 0) = "11" ) else
						x"00000000";

	r_cell_addr_01 	<= 	( "00" & r_addr)		when ( i_addr(1 downto 0) = "00" ) else
						( "00" & r_addr)		when ( i_addr(1 downto 0) = "01" ) else
						( "00" & r_addr_nxt) 	when ( i_addr(1 downto 0) = "10" ) else
						( "00" & r_addr_nxt) 	when ( i_addr(1 downto 0) = "11" ) else
						x"00000000";

	r_cell_addr_02 	<= 	( "00" & r_addr )		when ( i_addr(1 downto 0) = "00" ) else
						( "00" & r_addr )		when ( i_addr(1 downto 0) = "01" ) else
						( "00" & r_addr )		when ( i_addr(1 downto 0) = "10" ) else
						( "00" & r_addr_nxt) 	when ( i_addr(1 downto 0) = "11" ) else
						x"00000000";	

	r_cell_addr_03 	<= 	( "00" & r_addr ) 		when ( i_addr(1 downto 0) = "00" ) else
						( "00" & r_addr ) 		when ( i_addr(1 downto 0) = "01" ) else
						( "00" & r_addr ) 		when ( i_addr(1 downto 0) = "10" ) else
						( "00" & r_addr ) 		when ( i_addr(1 downto 0) = "11" ) else
						x"00000000";	


	o_cell_addr_00 	<= 	std_logic_vector(r_cell_addr_00)		when ( r_cell_addr_00 < to_unsigned(c_CELL_SIZE, 30)) else
						x"00000000";

	o_cell_addr_01 	<= 	std_logic_vector(r_cell_addr_01)		when ( r_cell_addr_01 < to_unsigned(c_CELL_SIZE, 30)) else
						x"00000000";

	o_cell_addr_02 	<= 	std_logic_vector(r_cell_addr_02)		when ( r_cell_addr_02 < to_unsigned(c_CELL_SIZE, 30)) else
						x"00000000";	

	o_cell_addr_03 	<= 	std_logic_vector(r_cell_addr_03)		when ( r_cell_addr_03 < to_unsigned(c_CELL_SIZE, 30)) else
						x"00000000";	


	------------------------------------------------------------------------------------------------------------------------------------
	-- MEMORY CELL READ/WRITE ENABLE
	------------------------------------------------------------------------------------------------------------------------------------

	w_rw_00 		<= 	i_rw_en				when ( i_addr(1 downto 0) = "00" ) and ( i_data_width = c_BYTE ) 	else		-- Store Byte 
						i_rw_en				when ( i_addr(1 downto 0) = "00" ) and ( i_data_width = c_HALF ) 	else		-- Store Half
						i_rw_en				when ( i_addr(1 downto 0) = "11" ) and ( i_data_width = c_HALF ) 	else		-- Store Half							
						i_rw_en				when ( i_data_width = c_WORD )										else		-- Store Word
						'0';																								-- (Default)

	w_rw_01 		<= 	i_rw_en				when ( i_addr(1 downto 0) = "01" ) and ( i_data_width = c_BYTE ) 	else		-- Store Byte 
						i_rw_en				when ( i_addr(1 downto 0) = "01" ) and ( i_data_width = c_HALF ) 	else		-- Store Half
						i_rw_en				when ( i_addr(1 downto 0) = "00" ) and ( i_data_width = c_HALF ) 	else		-- Store Half
						i_rw_en				when ( i_data_width = c_WORD ) 										else		-- Store Word
						'0';																								-- (Default)

	w_rw_02 		<= 	i_rw_en				when ( i_addr(1 downto 0) = "10" ) and ( i_data_width = c_BYTE )	else		-- Store Byte 
						i_rw_en				when ( i_addr(1 downto 0) = "10" ) and ( i_data_width = c_HALF )	else		-- Store Half
						i_rw_en				when ( i_addr(1 downto 0) = "01" ) and ( i_data_width = c_HALF )	else		-- Store Half
						i_rw_en				when ( i_data_width = c_WORD ) 										else		-- Store Word
						'0';																								-- (Default)

	w_rw_03 		<= 	i_rw_en				when ( i_addr(1 downto 0) = "11" ) and ( i_data_width = c_BYTE ) 	else		-- Store Byte 
						i_rw_en				when ( i_addr(1 downto 0) = "11" ) and ( i_data_width = c_HALF ) 	else		-- Store Half
						i_rw_en				when ( i_addr(1 downto 0) = "10" ) and ( i_data_width = c_HALF ) 	else		-- Store Half
						i_rw_en				when ( i_data_width = c_WORD ) 										else		-- Store Word
						'0';																								-- (Default)


	o_cell_rw_00	<= 	w_rw_00				when ( r_cell_addr_00 < to_unsigned(c_CELL_SIZE, 30)) else
						'0';

	o_cell_rw_01	<= 	w_rw_01				when ( r_cell_addr_01 < to_unsigned(c_CELL_SIZE, 30)) else
						'0';

	o_cell_rw_02	<= 	w_rw_02				when ( r_cell_addr_02 < to_unsigned(c_CELL_SIZE, 30)) else
						'0';

	o_cell_rw_03	<= 	w_rw_03				when ( r_cell_addr_03 < to_unsigned(c_CELL_SIZE, 30)) else
						'0';


	------------------------------------------------------------------------------------------------------------------------------------
	-- MEMORY CELL READ DATA
	------------------------------------------------------------------------------------------------------------------------------------

	r_cell_rd_00	<= 	i_cell_read_00		when ( r_cell_addr_00 < to_unsigned(c_CELL_SIZE, 30)) else
						x"00";

	r_cell_rd_01	<= 	i_cell_read_01		when ( r_cell_addr_01 < to_unsigned(c_CELL_SIZE, 30)) else
						x"00";

	r_cell_rd_02	<= 	i_cell_read_02		when ( r_cell_addr_02 < to_unsigned(c_CELL_SIZE, 30)) else
						x"00";

	r_cell_rd_03	<= 	i_cell_read_03		when ( r_cell_addr_03 < to_unsigned(c_CELL_SIZE, 30)) else
						x"00";


	-- Assign memory cell read value based on lower address bits
	r_data_read		<= 	(r_cell_rd_03 & r_cell_rd_02 & r_cell_rd_01 & r_cell_rd_00)		when ( i_addr(1 downto 0) = "00" ) else
						(r_cell_rd_00 & r_cell_rd_03 & r_cell_rd_02 & r_cell_rd_01)		when ( i_addr(1 downto 0) = "01" ) else
						(r_cell_rd_01 & r_cell_rd_00 & r_cell_rd_03 & r_cell_rd_02)		when ( i_addr(1 downto 0) = "10" ) else
						(r_cell_rd_02 & r_cell_rd_01 & r_cell_rd_00 & r_cell_rd_03)		when ( i_addr(1 downto 0) = "11" ) else
						x"00000000";


	-- Assign Memory Read based on data width and sign bits
	o_data_read		<= 	( x"000000" & r_data_read(7 downto 0) ) 	when ( i_data_width = c_BYTE and r_data_read(7) = '0' ) 	else			-- Load Byte 
						( x"FFFFFF" & r_data_read(7 downto 0) )		when ( i_data_width = c_BYTE and r_data_read(7) = '1' ) 	else			-- Load Byte 

						( x"0000" & r_data_read(15 downto 0) ) 		when ( i_data_width = c_HALF and r_data_read(15) = '0' ) 	else			-- Load Half
						( x"FFFF" & r_data_read(15 downto 0) ) 		when ( i_data_width = c_HALF and r_data_read(15) = '1' ) 	else			-- Load Half

						r_data_read 								when ( i_data_width = c_WORD ) 								else			-- Load Word

						( x"000000" & r_data_read(7 downto 0) )		when ( i_data_width = c_BYTE_U ) 							else			-- Load Byte (Unsigned)

						( x"0000" & r_data_read(15 downto 0) )		when ( i_data_width = c_HALF_U ) 							else			-- Load Half (Unsigned)

						x"00000000";	


	------------------------------------------------------------------------------------------------------------------------------------
	-- MEMORY CELL WRITE DATA
	------------------------------------------------------------------------------------------------------------------------------------

	-- Assign memory write values based on lower address bits
	o_cell_write_00		<= 	i_data_write(7 downto 0) 		when ( i_addr(1 downto 0) = "00" )		else
							i_data_write(31 downto 24)		when ( i_addr(1 downto 0) = "01" )		else
							i_data_write(23 downto 16) 		when ( i_addr(1 downto 0) = "10" )		else
							i_data_write(15 downto 8) 		when ( i_addr(1 downto 0) = "11" )		else
							x"00";

	o_cell_write_01		<= 	i_data_write(15 downto 8) 		when ( i_addr(1 downto 0) = "00" )		else
							i_data_write(7 downto 0)		when ( i_addr(1 downto 0) = "01" )		else
							i_data_write(31 downto 24) 		when ( i_addr(1 downto 0) = "10" )		else
							i_data_write(23 downto 16) 		when ( i_addr(1 downto 0) = "11" )		else
							x"00";

	o_cell_write_02		<= 	i_data_write(23 downto 16) 		when ( i_addr(1 downto 0) = "00" )		else
							i_data_write(15 downto 8)		when ( i_addr(1 downto 0) = "01" )		else
							i_data_write(7 downto 0) 		when ( i_addr(1 downto 0) = "10" )		else
							i_data_write(31 downto 24) 		when ( i_addr(1 downto 0) = "11" )		else
							x"00";

	o_cell_write_03		<= 	i_data_write(31 downto 24) 		when ( i_addr(1 downto 0) = "00" )		else
							i_data_write(23 downto 16)		when ( i_addr(1 downto 0) = "01" )		else
							i_data_write(15 downto 8) 		when ( i_addr(1 downto 0) = "10" )		else
							i_data_write(7 downto 0) 		when ( i_addr(1 downto 0) = "11" )		else
							x"00";




end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------