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
    -- once a key has been loaded.
    key_load  : in  std_logic;
    key_valid : out std_logic;

    in_valid : in std_logic;    -- ignored while key_valid = '0'
    out_valid: out std_logic;

    plaintext : in std_logic_vector(127 downto 0);
    cipherkey : in std_logic_vector(255 downto 0);

    ciphertext : out std_logic_vector(127 downto 0)
);
end entity AES;

architecture AES_arch of AES is

    signal pt_array : state_t;
    signal ct_array : state_t;

    -- Stored key schedule
    signal round_key : key_t;
    signal key_rdy   : std_logic;


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

        ct_array <= add_round_key(shift_rows(sub_bytes(add_round_key(
                round(
                round(
                round(
                round(
                round(
                round(
                round(
                round(
                round(
                round(
                round(
                round(
                round(pt_array, round_key(0)),
                round_key(1)),  round_key(2)),  round_key(3)),  round_key(4)),
                round_key(5)),  round_key(6)),  round_key(7)),  round_key(8)),
                round_key(9)),  round_key(10)), round_key(11)), round_key(12)),
                round_key(13)))), round_key(14));


        reset : process (i_clk)
        begin
            if rising_edge(i_clk) then
                if i_reset_n = '0' then
                    ciphertext <= (others => '0');
                    out_valid <= '0';
                else
                    ciphertext <= from_state(ct_array);
                    out_valid <= in_valid and key_rdy;
                end if;
            end if;
        end process;


end architecture;
