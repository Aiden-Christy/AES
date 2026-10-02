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
    -- once a key has been loaded. Don't load a new key while blocks are
    -- still in the pipeline - they would finish with the new round keys.
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
    signal pt_reg   : state_t;

    -- Stored key schedule, shared by every pipeline stage
    signal round_key : key_t;
    signal key_rdy   : std_logic;

    -- in_valid delayed by the pipeline depth:
    -- pt_reg, round1..round13, ct_array, ciphertext = 16 registers
    constant LATENCY : natural := 16;
    signal valid_sr  : std_logic_vector(LATENCY - 1 downto 0);


    -- Registers
    -- Text Registers
    signal round1  : state_t;
    signal round2  : state_t;
    signal round3  : state_t;
    signal round4  : state_t;
    signal round5  : state_t;
    signal round6  : state_t;
    signal round7  : state_t;
    signal round8  : state_t;
    signal round9  : state_t;
    signal round10 : state_t;
    signal round11 : state_t;
    signal round12 : state_t;
    signal round13 : state_t;


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

        encrypt : process (i_clk)
        begin
            if rising_edge(i_clk) then
                pt_reg <= pt_array;

                round1 <=  round(pt_reg, round_key(0));
                round2 <=  round(round1, round_key(1));
                round3 <=  round(round2, round_key(2));
                round4 <=  round(round3, round_key(3));
                round5 <=  round(round4, round_key(4));
                round6 <=  round(round5, round_key(5));
                round7 <=  round(round6, round_key(6));
                round8 <=  round(round7, round_key(7));
                round9 <=  round(round8, round_key(8));
                round10 <= round(round9, round_key(9));
                round11 <= round(round10, round_key(10));
                round12 <= round(round11, round_key(11));
                round13 <= round(round12, round_key(12));
                ct_array <= add_round_key(shift_rows(sub_bytes(add_round_key(round13, round_key(13)))), round_key(14));
            end if;
        end process;

        reset : process (i_clk)
        begin
            if rising_edge(i_clk) then
                if i_reset_n = '0' then
                    ciphertext <= (others => '0');
                    valid_sr   <= (others => '0');
                else
                    ciphertext <= from_state(ct_array);
                    valid_sr   <= valid_sr(LATENCY - 2 downto 0) & (in_valid and key_rdy);
                end if;
            end if;
        end process;

        out_valid <= valid_sr(LATENCY - 1);

end architecture;
