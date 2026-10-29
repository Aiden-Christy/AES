----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  PERIPHERALS
--	GPIO PERIPHERAL DEVICE
--
--	CREATED BY CHRIS MAJOR
--  RESILIENT COMPUTING
-- 	06/29/2022
--
--!	@file
--!	@brief A GPIO Input/Output Device capable of handling tri-state buffer input/output.
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
-- LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


----------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity gpio is
generic(
    g_GPIO_SIZE                 : integer := 32															--! GPIO Word Size
);
port(
	i_reset_n					: in	std_logic;														--! Active Low Reset

    i_gpio_direction            : in    std_logic_vector( (g_GPIO_SIZE - 1) downto 0);					--! GPIO Direction Register

	i_gpio_write                : in   	std_logic_vector( (g_GPIO_SIZE - 1) downto 0);					--! GPIO Output Data (to write)
    o_gpio_read                 : out  	std_logic_vector( (g_GPIO_SIZE - 1) downto 0);					--! GPIO Input Data (to read)

    i_gpio                     	: in 	std_logic_vector( (g_GPIO_SIZE - 1) downto 0);					--! GPIO Port Input
	o_gpio                 		: out  	std_logic_vector( (g_GPIO_SIZE - 1) downto 0)					--! GPIO Port Output
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture gpio_arch of gpio is
begin

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------
	
	-- Generate Input/Output handling for all bits in the GPIO buffer
	HANDLE_PINS_01 : for i in (g_GPIO_SIZE - 1) downto 0 generate

		-- Assign output GPIO signal the write value depending on direction and reset
		o_gpio(i)			<= 	'0' 			when i_reset_n = '0' 			else
								i_gpio_write(i) when i_gpio_direction(i) = '1' 	else
								'0';

		-- Assign read value the input GPIO signal depending on direction
		o_gpio_read(i)		<= 	i_gpio(i) 		when i_gpio_direction(i) = '0' 	else
								'0';

	end generate;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------