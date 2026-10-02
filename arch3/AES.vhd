library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AES_pkg.all;

entity AES is
port(
    i_clk     : in std_logic;
    i_reset_n : in std_logic;   -- active low

    -- Key interface: pulse key_load with cipherkey on the inputs. The key
    -- schedule is recomputed and stored on that edge; key_valid stays high
    -- once a key has been loaded. Don't load a new key while a block is
    -- in flight.
    key_load  : in  std_logic;
    key_valid : out std_logic;

    in_valid : in std_logic;    -- ignored while key_valid = '0' or busy
    out_valid: out std_logic;

    plaintext : in std_logic_vector(127 downto 0);
    cipherkey : in std_logic_vector(255 downto 0);

    ciphertext : out std_logic_vector(127 downto 0)
);
end entity AES;

architecture AES_arch of AES is

    signal pt_array : state_t;
    signal ct_array : state_t;

    -- Stored key schedule, used for both passes
    signal round_key : key_t;
    signal key_rdy   : std_logic;


    signal state_reg  : state_t;                         -- block being encrypted
    signal busy       : std_logic;                       -- '1' while a block is in flight
    signal pass       : std_logic;                       -- '0' = pass 1, '1' = pass 2


    -- Round keys for the current pass
    signal rk0, rk1, rk2, rk3, rk4, rk5 : state_t;

    -- Round outputs
    signal s1, s2, s3, s4, s5, s6, s7 : state_t;


    begin
        pt_array <= to_state(plaintext);

        key_valid <= key_rdy;

        -- Recompute the whole key schedule when key_load goes high
        key_expand : process (i_clk)
        begin
            if rising_edge(i_clk) then
                if i_reset_n = '0' then
                    key_rdy <= '0';
                elsif key_load = '1' then
                    round_key <= key_round(cipherkey);
                    key_rdy   <= '1';
                end if;
            end if;
        end process;

        rk0 <= round_key(0) when pass = '0' else round_key(7);
        rk1 <= round_key(1) when pass = '0' else round_key(8);
        rk2 <= round_key(2) when pass = '0' else round_key(9);
        rk3 <= round_key(3) when pass = '0' else round_key(10);
        rk4 <= round_key(4) when pass = '0' else round_key(11);
        rk5 <= round_key(5) when pass = '0' else round_key(12);

        s1 <= round(state_reg, rk0); --
        s2 <= round(s1, rk1);
        s3 <= round(s2, rk2);
        s4 <= round(s3, rk3);
        s5 <= round(s4, rk4);
        s6 <= round(s5, rk5);
        s7 <= round(s6, round_key(6));

        ct_array <= add_round_key(shift_rows(sub_bytes(add_round_key(s6, round_key(13)))), round_key(14));

        reset : process (i_clk)
        begin
            if rising_edge(i_clk) then
                if i_reset_n = '0' then
                    ciphertext <= (others => '0');
                    busy       <= '0';
                    pass       <= '0';
                    out_valid  <= '0';
                else
                    out_valid <= '0';
                    if busy = '0' then
                        if in_valid = '1' and key_rdy = '1' then
                            state_reg <= pt_array;
                            pass      <= '0';
                            busy      <= '1';
                        end if;
                    elsif pass = '0' then
                        state_reg <= s7;
                        pass      <= '1';
                    else
                        ciphertext <= from_state(ct_array);
                        out_valid  <= '1';
                        busy       <= '0';
                    end if;
                end if;
            end if;
        end process;


end architecture;
