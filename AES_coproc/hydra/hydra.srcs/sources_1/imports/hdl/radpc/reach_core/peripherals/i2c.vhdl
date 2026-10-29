----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  PERIPHERALS
--	I2C PERIPHERAL DEVICE
--
--	CREATED BY TRISTAN RUNNING CRANE, BEN MACHT
--  RESILIENT COMPUTING
-- 	06/11/2024
--
--	An I2C Transciever Device
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
-- 	LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- IEEE Numeric Standard Library
use IEEE.NUMERIC_STD.ALL;


----------------------------------------------------------------------------------------------------------------------------------------
-- 	ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity i2c is
port(
	i_clk						: in	std_logic;														--! I2C Clock
	i_reset_n					: in	std_logic;														--! Active Low Reset

	i_ctl						: in	std_logic_vector(15 downto 0);									--! I2C Control Value
	o_status					: out	std_logic_vector(31 downto 0);									--! I2C Status Value
	i_brw						: in	std_logic_vector(15 downto 0);									--! I2C Bit Rate Word Control Value
	i_bcount					: in	std_logic_vector(7 downto 0);									--! I2C Bit Count Threshold Value
	o_rxbuf						: out	std_logic_vector(7 downto 0);									--! I2C RX Buffer Value
	i_txbuf						: in	std_logic_vector(7 downto 0);									--! I2C TX Buffer Value
	i_oaddr						: in	std_logic_vector(15 downto 0);									--! I2C Own Address Value
	i_taddr						: in	std_logic_vector(15 downto 0);									--! I2C Target Address Value
	o_raddr						: out	std_logic_vector(31 downto 0);									--! I2C Receive Address

	i_scl						: in	std_logic;														--! I2C Incoming Serial Clock
	i_sda						: in	std_logic;														--! I2C Incoming Serial Data
	o_scl						: out	std_logic;														--! I2C Outgoing Serial Clock
	o_sda						: out	std_logic;														--! I2C Outgoing Serial Data
	o_i2c_mode					: out	std_logic_vector(1 downto 0)									--! I2C Transceiver INOUT Signal
);
end entity;

----------------------------------------------------------------------------------------------------------------------------------------
-- 	ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture i2c_arch of i2c is

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	TYPE DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	--Type for States
	type t_State is(
		s_IDLE,		--0
		s_TX_START,	--1
		s_RX_START,	--2
		s_RESTART,	--3
		s_TX_ADDR,	--4
		s_RX_ADDR,	--5
		s_TX_DATA,	--6
		s_RX_DATA,	--7
		s_ACK_NACK,	--8
		s_STOP,		--9
		s_STRETCH	--10
	);

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

	signal r_cur_state			: t_State							:= s_IDLE;							--! Current Machine State
	signal r_next_state			: t_State							:= s_IDLE;							--! Next Machine State

	signal w_ctl_reset			: std_logic							:= '0';								--! Reset Bit
	signal w_ctl_start			: std_logic							:= '0';								--! Transmit Start Bit
	signal w_ctl_stop			: std_logic							:= '0';								--! Transmit Stop Bit
	signal w_ctl_nack			: std_logic							:= '0';								--! Transmit a Nack Bit
	signal w_ctl_TR				: std_logic							:= '0';								--! Transmitter/Receiver Bit
	signal w_ctl_ack			: std_logic							:= '0';								--! Transmit Ack Bit
	signal w_ctl_ctr			: std_logic							:= '0';								--! Mode Select (1 = Controller) (0 = Target)
	signal w_ctl_mc				: std_logic							:= '0';								--! Multiple Contoller Enable Bit
	signal w_ctl_ta10			: std_logic							:= '0';								--! Target 10-bit Addressing Mode Enable Bit
	signal w_ctl_oa10			: std_logic							:= '0';								--! Own 10-bit Addressing Mode Enable bit
	signal w_ctl_astop			: std_logic_vector(1 downto 0)		:= "00";							--! Automatic Stop Mode Bits

	signal w_status_busy		: std_logic							:= '0';								--! Status Busy Bit
	signal r_status_gcr			: std_logic							:= '0';								--! Status General Call Bit
	signal r_status_scl			: std_logic							:= '0';								--! Status Clock Held Low Bit (1 =  SCL held low)
	signal r_status_clrstt		: std_logic							:= '0';								--! Status of address transmistion
	signal r_status_bcnt		: unsigned(7 downto 0)				:= x"00";							--! Status Byte Counter (# of bytes Transmitted or Received since START/RESTART)

	signal r_bcount				: std_logic_vector(7 downto 0)		:= x"00";							--! Byte Count Threshold
	signal w_bcount_en			: std_logic							:= '0';								--! Byte Threshold Met

	signal r_tx_shift			: unsigned(7 downto 0)				:= x"00";						--! TX Shift Register
	signal r_rx_shift			: unsigned(7 downto 0)				:= x"00";						--! RX Shift Register
	signal r_rx_bit				: std_logic := '0';

	--signal r_txbuf				: std_logic_vector(31 downto 0)		:= x"00000000";						--! TX Buffer Register
	signal r_txbuf				: std_logic_vector(7 downto 0)		:= x"00";							--! TX Buffer Register
	--signal r_rxbuf				: std_logic_vector(31 downto 0)		:= x"00000000";						--! RX Buffer Register
	signal r_rxbuf				: std_logic_vector(7 downto 0)		:= x"00";							--! RX Buffer Register
	signal r_oaddr				: std_logic_vector(10 downto 0)		:= "000" & x"00";					--! Own Address
	signal r_taddr				: std_logic_vector(9 downto 0)		:= "00" & x"00";					--! Target Address
	signal r_raddr				: std_logic_vector(9 downto 0)		:= "00" & x"00";					--! Last Received Address

	signal w_read_transmit		: std_logic							:= '0';								--! Master read - Transmit address sent (1 = sent, 0 = not sent)
	signal w_reg_sent			: std_logic							:= '0';								--! Master read - register address to read sent (1 = sent, 0 = not sent)
	signal w_read_data			: std_logic							:= '0';								--! Master read - ready for data byte

	signal r_sda				: std_logic							:= '0';
	signal r_sda_clk			: std_logic							:= '0';
	signal r_scl_clk			: std_logic							:= '0';
	signal r_bit_cnt			: unsigned(3 downto 0)				:= x"0";							--! Bit Tracker
	signal r_rx_bit_cnt			: integer range 0 to 8				:= 0;
	signal r_addr_cnt			: unsigned(1 downto 0)				:= "00";							--! 10 Bit Address 2nd Byte of Address Enable
	signal r_stop				: std_logic							:= '0';								--! Enable Stop Condition
	signal clk_en				: std_logic_vector(1 downto 0)		:= "00";
	signal r_I2C_mode			: std_logic_vector(1 downto 0)		:= "11";
	signal r_brw				: integer range 0 to 65535			:= 0;
	signal r_tx_ready			: std_logic							:= '0';
	signal r_tx_latched			: std_logic							:= '0';
	signal r_rx_ready			: std_logic							:= '0';
	signal r_status_tx_start_detected: std_logic					:= '0';
	signal r_status_stop_detected: std_logic						:= '0';
	signal r_status_nack_detected: std_logic						:= '0';
	signal r_status_bcnt_detected: std_logic						:= '0';
	signal r_NACK				: std_logic							:= '0';
	signal r_address_check		: std_logic							:= '0';
	signal r_NACK_DETECTED		: std_logic							:= '0';
	signal r_stop_detected		: std_logic							:= '0';

	signal r_sda_sample		: std_logic := '0';
	signal r_scl_sample		: std_logic := '0';
	signal v_o_scl			: std_logic := '0';
	signal v_o_sda_delay	: std_logic := '0';
	signal v_o_scl_delay	: std_logic := '0';

	signal tracker_state		: integer range 0 to 12 := 0;
	signal tracker_output		: integer range 0 to 12 := 0;
	signal tracker_internal		: integer range 0 to 12 := 0;
	signal test_tracker			: integer;
	signal test_next_tracker	: integer;

	signal w_tx_complete		: std_logic := '0';
	signal w_rx_complete		: std_logic := '0';


begin


	STATE_MEMORY : process( r_sda_clk, i_reset_n, w_ctl_reset)
	begin

		--On Hardware or Software Reset
		if ( i_reset_n = '0' OR w_ctl_reset = '1') then

			r_cur_state			<= s_IDLE;

		elsif ( rising_edge(r_sda_clk) ) then

			r_cur_state			<= r_next_state;

		end if;
		
	end process;



	NEXT_STATE_LOGIC : process(r_cur_state, w_ctl_start, i_sda, w_tx_complete, w_rx_complete, r_NACK)
	begin

		case(r_cur_state) is

			when s_IDLE	=>		if (w_ctl_ctr = '1' AND w_ctl_start = '1') then --RadPC is a Controller

									r_next_state <= s_TX_START;

								elsif (w_ctl_ctr = '0' AND i_sda = '0' ) then 	--RadPC is a Target

									r_next_state <= s_RX_ADDR;

								else

								r_next_state <= s_IDLE;							--No start condition remain in IDLE state

								end if;

			when s_TX_START =>	r_next_state <= s_TX_ADDR;						--Spend once clock cylce in TX_START then move to TX_ADDR

			when s_RX_START =>	r_next_state <= s_RX_DATA;						--Spend once clock cylce in RX_START then move to RX_ADDR

			when s_RESTART => 	r_next_state <= s_TX_ADDR;						--Spend once clock cylce in Repeated Start then move to TX_ADDR (Yet to be implemented)

			when s_TX_ADDR =>	if (w_tx_complete = '1') then					-- Wiat for TX Transmission to be complete
									r_next_state	<= s_ACK_NACK;
								else
									r_next_state	<= s_TX_ADDR;
								end if;


			when s_RX_ADDR =>	if (w_rx_complete = '1') then
									r_next_state	<= s_ACK_NACK;
								else
									r_next_state	<= s_RX_ADDR;
								end if;

			when s_TX_DATA =>	if (w_tx_complete = '1') then
									r_next_state	<= s_ACK_NACK;
								else
									r_next_state	<= s_TX_DATA;
								end if;

			when s_RX_DATA =>	if (w_rx_complete = '1') then
									r_next_state	<= s_ACK_NACK;
								else
									r_next_state	<= s_RX_DATA;
								end if;

			when s_ACK_NACK =>	if (w_ctl_ctr = '1') then
									if (w_ctl_TR = '1') then
										if (r_NACK = '0') then
											if (w_ctl_ta10 = '1') then
												if(to_integer(r_addr_cnt) >= 2) then
													r_next_state	<= s_TX_DATA;
												else
													r_next_state	<= s_TX_ADDR;
												end if;
											else
												r_next_state		<= s_TX_DATA;
											end if;
										else
											r_next_state	<= s_STOP;
										end if;
									else
										if (r_NACK = '0') then
												if(w_ctl_ta10 = '1') then
													if(to_integer(r_addr_cnt) >= 2) then
														r_next_state <= s_RX_DATA;
													else
														r_next_state <= s_TX_ADDR;
													end if;
												else
													if (w_read_transmit = '1') then							-- in master read mode, if slave write address is sent then transmit register address to read from
														if (w_reg_sent = '1') then
															if (w_read_data = '1') then
																r_next_state <= s_RX_DATA;					-- read data byte from slave register
															else
																r_next_state <= s_TX_START;					-- send slave read address
															end if;
														else
															r_next_state <= s_TX_DATA;						-- send slave register address to read from
														end if;
													else
														r_next_state <= s_RX_DATA;
													end if;
												end if;
										else
											r_next_state <= s_STOP;
										end if;
									end if;
								else
									if(w_ctl_TR = '1') then
										r_next_state	<= s_IDLE;
									else
										if(r_NACK = '0') then
											if(w_ctl_ta10 = '1') then
												if(to_integer(r_addr_cnt) >= 2) then
													r_next_state <= s_RX_ADDR;
												else
													r_next_state <= s_RX_DATA;
												end if;
											else
												r_next_state <= s_RX_DATA;
											end if;
										else
											r_next_state <= s_STOP;
										end if;
									end if;
								end if;

			when s_STOP =>	r_next_state	<= s_IDLE;

			when others =>	r_next_state <=	s_STOP;
		end case;
	end process;


	OUTPUT_LOGIC: process(r_cur_state, clk_en, i_scl, i_sda, r_tx_shift, r_NACK, w_rx_complete, w_tx_complete)
	begin
		case(r_cur_state) is

				when s_IDLE		=>	r_scl_clk		<= '1';
									r_sda			<= '1';
									r_I2C_mode		<= "11";
									r_rx_shift		<= x"00";
									r_tx_ready		<= '0';
									r_rx_ready		<= '0';
									r_status_nack_detected <= '0';


				when s_TX_START	=>	r_I2C_mode	<= "00";
									if (clk_en = "00") then
										r_sda		<= '1';
										r_scl_clk	<= '1';
									elsif(clk_en = "01") then
										r_sda		<= '1';
										r_scl_clk	<= '1';
									elsif(clk_en = "10") then
										r_sda		<= '0';
										r_scl_clk	<= '1';
									elsif(clk_en = "11") then
										r_sda		<= '0';
										r_scl_clk	<= '0';
									end if;
									r_rx_ready		<= '0';

				when s_RX_START	=>	r_I2C_mode	<= "10";
									r_rx_ready		<= '0';

				when s_RESTART	=>	r_I2C_mode	<= "00";
									r_sda		<= '0';
									r_rx_ready		<= '0';

				when s_TX_ADDR	=>	r_I2C_mode <= "00";
									r_sda		<= r_tx_shift(7);
									if (clk_en = "00") then
										r_scl_clk	<= '0';
										r_tx_ready <= '0';
									elsif(clk_en = "01") then
										r_scl_clk	<= '1';
										r_tx_ready <= '0';
									elsif(clk_en = "10") then
										r_scl_clk	<= '1';
										r_tx_ready <= '0';
									elsif(clk_en = "11") then
										r_scl_clk <= '0';
										if(w_tx_complete = '1') then
											r_tx_ready <= '1';
										else 
											r_tx_ready <= '0';
										end if;
									end if;
									r_rx_ready		<= '0';


				when s_RX_ADDR	=>	r_I2C_mode <= "11";
									r_sda		<= i_sda;
									if(r_scl_sample = '0' AND i_scl = '1') then
										r_rx_shift(r_rx_bit_cnt) <= r_sda_sample;
									end if;
									if(clk_en = "00") then
										r_scl_clk <= '1';
 									elsif(clk_en = "01") then
										r_scl_clk <= '1';
									elsif(clk_en = "10") then
										r_scl_clk <= '1';
									elsif(clk_en = "11") then
										if(w_rx_complete = '1') then
										else 
										end if;
									end if;
									r_rx_ready		<= '0';

				when s_TX_DATA	=>	if (w_ctl_ctr = '1') then
										r_I2C_mode <= "00";
									else
										r_I2C_mode <= "01";
									end if;
									r_sda		<= r_tx_shift(7);
									if(clk_en = "00") then
										r_scl_clk <= '0';
										r_tx_ready <= '0';
 									elsif(clk_en = "01") then
										r_scl_clk <= '1';
										r_tx_ready <= '0';
									elsif(clk_en = "10") then
										r_scl_clk <= '1';
										r_tx_ready <= '0';
									elsif(clk_en = "11") then
										r_scl_clk <= '0';
										if(w_tx_complete = '1') then
											r_tx_ready <= '1';
										else 
											r_tx_ready <= '0';
										end if;
									end if;
									r_rx_ready		<= '0';


				when s_RX_DATA	=>	if(w_ctl_ctr = '1') then
										r_I2C_mode <= "10";
										r_sda		<= i_sda;
										if(clk_en = "00") then
											r_scl_clk <= '0';
										elsif(clk_en = "01") then
											r_rx_shift(r_rx_bit_cnt) <= r_sda_sample;
											r_scl_clk <= '1';
										elsif(clk_en = "10") then
											r_scl_clk <= '1';
										elsif(clk_en = "11") then
											r_scl_clk <= '0';
											if(w_rx_complete = '1') then
												r_rx_ready <= '1';
												r_rxbuf(7 downto 0) <= std_logic_vector(r_rx_shift);
											else 
												r_rx_ready <= '0';
											end if;
										end if;
									else
										r_I2C_mode <= "00";
										r_sda		<= i_sda;
										if(r_scl_sample = '0' AND i_scl = '1') then
											r_rx_shift(r_rx_bit_cnt) <= r_sda_sample;
										end if;
										if(clk_en = "00") then
											r_scl_clk <= '1';
										elsif(clk_en = "01") then
											r_scl_clk <= '1';
										elsif(clk_en = "10") then
											r_scl_clk <= '1';
										elsif(clk_en = "11") then
											r_scl_clk <= '1';
											if(w_rx_complete = '1') then
												r_rx_ready <= '1';
												r_rxbuf(7 downto 0) <= std_logic_vector(r_rx_shift);
											else 
												r_rx_ready <= '0';
											end if;
										end if;
									end if;

				when s_ACK_NACK	=>	r_rx_ready <= '0';
									if (w_ctl_ctr = '1') then
										r_rx_bit		<= '0';
										r_I2C_mode(0)	<= '0';

										if (w_ctl_TR = '1') then
											r_I2C_mode(1)	<= '1';
											r_sda			<= '0';
											r_tx_ready		<= '0';
											
										else
											if(to_integer(r_status_bcnt) <= 1) then
												r_I2C_mode(1)	<= '1';
												r_sda			<= '0';
												r_tx_ready		<= '0';
											else
												if (r_NACK = '1') then
													r_I2C_mode(1)	<= '0';
													r_sda			<= '1';
													r_tx_ready		<= '0';
												else
													r_I2C_mode(1)	<= '0';
													r_sda			<= '0';
													r_tx_ready		<= '0';
												end if;
											end if;
										end if;

										if(clk_en = "00") then
											r_scl_clk <= '0';
										elsif(clk_en = "01") then
											r_scl_clk <= '1';
										elsif(clk_en = "10") then
											r_scl_clk <= '1';
										elsif(clk_en = "11") then
											r_scl_clk <= '0';
										end if;

									else
										r_rx_bit		<= '0';
										r_I2C_mode(0)	<= '1';
										r_scl_clk		<= '1';
										r_rx_bit		<= '0';
										if (w_ctl_TR = '1') then
											r_I2C_mode(1)	<= '1';
											r_sda			<= '1';
											r_tx_ready		<= '0';
										else
											r_I2C_mode(1)	<= '0';
											if(r_NACK = '0') then
												r_sda			<= '0';
											else
												r_sda			<= '1';
											end if;
											if(clk_en = "00") then
											elsif(clk_en = "10") then
												r_rx_shift	<= x"00";
											end if;
										end if;
									end if;


				when s_STOP		=>	r_I2C_mode	<= "00";
									r_rx_ready		<= '0';
									if (clk_en = "00") then
										r_sda		<= '0';
										r_scl_clk	<= '0';
									elsif (clk_en = "01") then
										r_sda		<= '0';
										r_scl_clk	<= '1';
									elsif (clk_en = "10") then
										r_sda		<= '1';
										r_scl_clk	<= '1';
									elsif(clk_en = "11") then
										r_sda		<= '1';
										r_scl_clk	<= '1';
									end if;


				when others =>		r_I2C_mode <= "11";
									r_scl_clk		<= '1';
									r_sda			<= '1';
									r_tx_ready		<= '0';
									r_rx_ready		<= '0';
									r_status_nack_detected <= '0';

			end case;

	end process;


	INTERNAL_LOGIC: process(r_sda_clk, r_cur_state)
	begin
		if(rising_Edge(r_sda_clk)) then
			case(r_cur_state) is

				when s_IDLE		=>	r_tx_shift		<= x"00";
									r_status_bcnt	<= x"00";
									r_bit_cnt		<= x"0";
									r_rx_bit_cnt	<= 8;
									r_addr_cnt		<= "00";
									r_tx_latched	<= '0';
									w_tx_complete	<= '0';
									w_rx_complete	<= '0';
									w_status_busy	<= '0';
									r_bcount		<= x"00";
									w_read_transmit <= '0';
									w_read_data 	<= '0';
									w_reg_sent		<= '0';
									w_ctl_TR		<=	i_ctl(4);

				when s_TX_START	=>	w_status_busy	<= '1';
									r_bcount		<= i_bcount(7 downto 0);
									if (w_ctl_ta10 = '0') then
										if (w_ctl_TR = '1') then
											r_tx_shift	<= unsigned(r_taddr(6 downto 0)) & NOT w_ctl_TR;				-- master write
										else
											if w_read_transmit = '0' then
												r_tx_shift	<= unsigned(r_taddr(6 downto 0)) & '0';						-- slave address to transmit register to be read
											else
												r_tx_shift	<= unsigned(r_taddr(6 downto 0)) & '1';						-- slave address to read register values
											end if;
										end if;
									else
										r_tx_shift	<= unsigned(x"F" & '0' & r_taddr(9 downto 8)) & NOT w_ctl_TR;
									end if;
				
				when s_RX_START =>	w_status_busy	<= '1';

									w_status_busy	<= '1';

				when s_TX_ADDR	=>	w_status_busy	<= '1';
									r_tx_latched	<= '0';
									r_tx_shift	<= shift_left(r_tx_shift,1);
									r_bit_cnt	<= r_bit_cnt + 1;
									if (w_ctl_TR = '1') then
										if(r_bit_cnt >= 7) then
											r_addr_cnt		<= r_addr_cnt + 1;
											w_tx_complete	<= '0';
											r_status_clrstt	<= '0';
										elsif(r_bit_cnt >= 6) then
											r_status_clrstt	<= '1';
											w_tx_complete	<= '1';
										else
											w_tx_complete	<= '0';
											r_status_clrstt	<= '0';
										end if;
									else												-- master read mode
										if(r_bit_cnt >= 7) then
											r_addr_cnt		<= r_addr_cnt + 1;
											w_tx_complete	<= '0';
											r_status_clrstt	<= '0';

											if (w_read_transmit = '0') then
												w_read_transmit <= '1';					-- set to 1 after write address is sent so read address can be sent next
											else
												w_read_data <= '1';						-- set to 1 after register address is sent so data can be read
											end if;

										elsif(r_bit_cnt >= 6) then
											r_status_clrstt	<= '1';
											w_tx_complete	<= '1';
										else
											w_tx_complete	<= '0';
											r_status_clrstt	<= '0';
										end if;
									end if;

				when s_RX_ADDR	=>	w_status_busy	<= '1';
									r_tx_latched	<= '0';
									r_bit_cnt		<= r_bit_cnt + 1;
									r_rx_bit_cnt	<= r_rx_bit_cnt - 1;
									r_bcount		<= i_bcount(7 downto 0);
									if(r_bit_cnt >= 8) then
										w_rx_complete	<= '0';
										if (r_oaddr(6 downto 0) = std_logic_vector(r_rx_shift(7 downto 1))) then
											r_address_check <= '0';
										else
											r_address_check <= '1';
										end if;
									elsif(r_bit_cnt >= 7) then
										r_addr_cnt		<= r_addr_cnt + 1;
										w_rx_complete	<= '1';
									else
										w_rx_complete	<= '0';
									end if;

				when s_TX_DATA	=>	w_status_busy	<= '1';
									r_tx_latched	<= '0';
									r_tx_shift	<= shift_left(r_tx_shift,1);
									r_bit_cnt	<= r_bit_cnt + 1;
									if(r_bit_cnt >= 7) then
										r_status_bcnt	<= r_status_bcnt + 1;
										w_tx_complete	<= '0';
									elsif(r_bit_cnt >= 6) then
										w_tx_complete	<= '1';
									else
										w_tx_complete	<= '0';
									end if;

									if (w_read_transmit = '1') then
										w_reg_sent <= '1';							-- master read, set to 1 after register address to read from is sent
									end if;
				
				when s_RX_DATA	=>	w_status_busy	<= '1';
									r_tx_latched	<= '0';
									r_bit_cnt	<= r_bit_cnt + 1;
									r_rx_bit_cnt	<= r_rx_bit_cnt - 1;
									if(r_bit_cnt >= 7) then
										w_rx_complete	<= '0';
										r_status_bcnt	<= r_status_bcnt + 1;
									elsif(r_bit_cnt >= 6) then
										w_rx_complete	<= '1';
									else
										w_rx_complete	<= '0';
									end if;

				when s_ACK_NACK	=>	w_status_busy	<= '1';
									r_bit_cnt 		<= x"0";
									r_rx_bit_cnt	<= 7;
									if (w_ctl_ctr = '1') then
										if (w_ctl_TR = '1') then
											if (w_ctl_ta10 = '1') then
												if(to_integer(r_addr_cnt) >= 2) then
													r_tx_shift	<= unsigned(r_txbuf(7 downto 0));
													r_tx_latched	<= '1';
												else
													r_tx_shift	<=  unsigned(r_taddr(7 downto 0));
													r_tx_latched	<= '0';
												end if;
											else
												r_tx_shift	<= unsigned(r_txbuf(7 downto 0));
												r_tx_latched	<= '1';
											end if;
										else
											if (w_read_transmit = '1') then
												r_tx_shift	<= unsigned(r_txbuf(7 downto 0));
												r_tx_latched	<= '1';
											else
												r_tx_latched <= '0';
											end if;
										end if;
									else
										if (w_ctl_TR = '1') then
											if(w_ctl_ta10 = '1') then
											else
											end if;
										else
											if(w_ctl_ta10 = '1') then
											else
											end if;
										end if;
									end if;

				when s_STOP		=>	w_status_busy	<= '1';

				when others		=>	w_status_busy		<= '1';

			end case;

		end if;

	end process;


	CLOCK_PROCESS: process(i_clk, i_reset_n, w_ctl_reset, r_cur_state, i_sda, i_scl)

		variable cnt_int	: integer range 0 to 65535 := 0;
		variable cur		: t_State := s_IDLE;

	begin
		if(i_reset_n = '0'OR w_ctl_reset = '1') then
			cnt_int	:= 0;
			clk_en	<= "00";
			cur		:= s_IDLE;
			r_sda_sample <= '0';
		elsif(r_cur_state /= cur AND w_ctl_ctr = '1') then
			clk_en	<= "00";
			cnt_int	:= 0;
			cur := r_cur_state;
		elsif(rising_edge(i_clk)) then
			cur := r_cur_state;
			r_sda_sample	<= i_sda;
			r_scl_sample	<= i_scl;
			if(r_cur_state = s_ACK_NACK AND clk_en = "01" AND i_sda = '1') then
				if(w_ctl_ctr = '1' AND w_ctl_TR = '0'AND to_integer(r_status_bcnt) /= 0) then
					r_NACK_DETECTED <= '0';
				else
					r_NACK_DETECTED <= '1';
				end if;	
			elsif(r_cur_state = s_IDLE) then
				r_NACK_DETECTED <= '0';
			end if;
			if(clk_en = "10" AND i_sda = '1' AND r_sda_sample = '0' AND i_scl = '1') then
				r_stop_detected <= '1';
			elsif(r_cur_state = s_IDLE) then
				r_stop_detected <= '0';
			end if;
			if(r_brw > 0) then

				if(w_ctl_ctr = '1') then
					if (cnt_int >= r_brw ) then

						cnt_int := 0;
						r_sda_clk	<=	not r_sda_clk;
						clk_en <= "00";

					elsif (cnt_int = (3*r_brw)/4 - 1) then

						cnt_int := cnt_int + 1;
						clk_en <= "11";

					elsif (cnt_int = (2*r_brw)/4 - 1) then

						cnt_int := cnt_int + 1;
						r_sda_clk	<=	not r_sda_clk;
						clk_en <= "10";
						
					elsif (cnt_int = (r_brw)/4 - 1) then

						cnt_int := cnt_int + 1;
						clk_en <= "01";

					else

						cnt_int := cnt_int + 1;

					end if;
				else
					if(r_cur_state = s_IDLE AND i_sda = '0' AND r_sda_sample = '1' AND w_ctl_ctr = '0') then
						clk_en <= "01";
						cnt_int := (r_brw)/4;
						cur := r_cur_state;
						r_sda_clk <= '1';
					elsif(i_scl = '1' AND r_scl_sample = '0') then
						clk_en <= "01";
						cnt_int := (r_brw)/4;
						cur := r_cur_state;
						r_sda_clk <= '1';
					elsif (cnt_int >= r_brw) then

						cnt_int := 0;
						r_sda_clk	<=	not r_sda_clk;
						clk_en <= "00";

					elsif (cnt_int = (3*r_brw)/4 - 1) then

						cnt_int := cnt_int + 1;
						clk_en <= "11";

					elsif (cnt_int = (2*r_brw)/4 - 1) then

						cnt_int := cnt_int + 1;
						r_sda_clk	<=	not r_sda_clk;
						clk_en <= "10";
						
					elsif (cnt_int = (r_brw)/4 - 1) then

						cnt_int := cnt_int + 1;
						clk_en <= "01";


					else

						if(r_cur_state = s_IDLE) then
							r_sda_clk <= '0';
							cnt_int := cnt_int + 1;
						else	
							cnt_int := cnt_int + 1;
						end if;

					end if;
				end if;
			end if;
		end if;
	end process;

	------------------------------------------------------------------------------------------------------------------------------------
	-- 	SIGNAL ASSIGNMENTS
	------------------------------------------------------------------------------------------------------------------------------------

	w_ctl_reset					<=	i_ctl(0);														--Software Reset
	w_ctl_start					<=	i_ctl(1);														--Initiate Start Condition
	w_ctl_stop					<=	i_ctl(2);														--Initiate Stop Condition
	w_ctl_nack					<=	i_ctl(3);														--Send r_NACK
	--w_ctl_TR					<=	i_ctl(4);														--Transmit/Recieve Mode
	w_ctl_ack					<=	i_ctl(5);														--Send ACK
	w_ctl_ctr					<=	i_ctl(6);														--Controller/Target Mode
	w_ctl_mc					<=	i_ctl(7);														--Multi-Controller Mode
	w_ctl_ta10					<=	i_ctl(8);														--Target Address 10-bit Mode
	w_ctl_oa10					<=	i_ctl(9);														--Own Address 10-bit mode
	w_ctl_astop					<=	i_ctl(11 downto 10);											--Automatic Stop Modes

	o_status(0)					<=	w_status_busy;													--BUSY signal
	o_status(1)					<=	r_status_gcr;													--General Call Address Recieved (Yet to be implemented)
	o_status(2)					<=	r_status_scl;													--SCL held low during clock stretching (Yet to be implemented)
	o_status(3)					<=	r_status_clrstt;												--Start including address complete
	o_status(4)					<=	'1' when (w_ctl_ctr = '1') AND (r_tx_ready = '1') else			--TX Shift register is ready for another byte
									'0';
	-- o_status(5)					<=	'1' when (r_tx_latched = '1') AND (r_tx_shift /= x"00") else	--Oncce TX Shift register byte is latched TX Buff will be cleared
									-- '0';
	o_status(5)					<=	r_tx_latched;													--Changed to account for TX of 0x00
	-- o_status(6)					<=	'1' when (r_rxbuf /= x"00" AND r_rx_ready = '1') else			--RX Shift register is ready for another byte
	-- 								'0';
	o_status(6)					<=	r_rx_ready;														--Changed to account for RX of 0x00
	o_status(7)					<=	'0';															--Unused yet
	o_status(15 downto 8)		<=	std_logic_vector(r_status_bcnt);								--Current Byte count
	o_status(16)				<=	r_status_tx_start_detected;										--High when start detected on the bus (Yet to be implemented)
	o_status(17)				<=	r_stop_detected;--r_status_stop_detected;						--High when stop  detected on the bus (Yet to be implemented)
	o_status(18)				<=	r_NACK;--r_status_nack_detected;								--When in controller mode and when high a NACK will be sent
																									--When in target mode and when high a NACK has been recieved
	o_status(19)				<=	w_bcount_en;													--High when current Byte counter is equal with BCOUNT register
	o_status(27 downto 20)		<=	x"00";															--Unused yet
	o_status(29 downto 28)		<= std_logic_vector(r_addr_cnt);									--Number of address sent in a single frame, if greater than 1 the FSM is in 10-bit addressing
	o_status(31 downto 30)		<= "00";															--Unused yet

	r_NACK						<=	'1' when (w_ctl_nack = '1') OR (r_address_check = '1') OR (w_bcount_en = '1') OR (r_stop = '1') OR (r_NACK_DETECTED = '1') else
									'0';

	r_txbuf						<=	i_txbuf; --(7 downto 0);	-- Changed to more efficiently use memory
	o_rxbuf						<=	r_rxbuf;				-- Changed to more efficiently use memory
	r_oaddr						<=	i_oaddr(10 downto 0);
	r_taddr						<=	i_taddr(9 downto 0);
	o_raddr(9 downto 0)			<=	r_raddr;

	w_bcount_en					<=	'1' when (unsigned(r_bcount) <= r_status_bcnt) AND ( w_ctl_astop = "10") else
									'0';

	r_stop						<=	'1' when (w_ctl_stop = '1' OR w_bcount_en = '1' OR r_stop_detected = '1') else
									'0'; 

	o_scl						<=	r_scl_clk;

	o_sda						<=	r_sda;

	o_I2C_mode					<=	r_I2C_mode;

	r_brw						<= to_integer(unsigned(i_brw(15 downto 0)));


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
-- 	END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------