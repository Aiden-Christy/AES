library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.decrypt_pkg.all;

entity decrypt is
    port(
    i_clk       : in std_logic;
    i_reset_n   : in std_logic;   -- active low

    key_load    : in  std_logic;
    key_valid   : out std_logic;

    in_valid    : in std_logic;    -- ignored while key_valid = '0'
    out_valid   : out std_logic;

    ciphertext  : in std_logic_vector(127 downto 0);
    cipherkey   : in std_logic_vector(255 downto 0);

    plaintext   : out std_logic_vector(127 downto 0)
);
end entity;


architecture decrypt_arch of decrypt is

    signal pt_array : state_t;
    signal ct_array : state_t;
    signal ct_reg   : state_t;

    -- in_valid delayed by the pipeline depth:
    
    constant LATENCY : natural := 16;
    signal valid_sr  : std_logic_vector(LATENCY - 1 downto 0);

    -- Stored key schedule, shared by every pipeline stage
    signal round_key    : key_t;
    signal key_rdy      : std_logic;
    signal key_hold     : std_logic_vector(255 downto 0);
    signal key_settle   : integer range 0 to LATENCY - 1 := 0;

    type key_phase_t is (IDLE, EXPANDING);
    signal key_phase : key_phase_t;




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
        ct_array <= to_state(ciphertext);

        key_valid <= key_rdy;

        decryption : process (i_clk)
        begin
            if rising_edge(i_clk) then
                ct_reg <= ct_array;

                round1 <=  inv_round(add_round_key(ct_reg, round_key(14)), round_key(13));
                round2 <=  inv_round(round1, round_key(12));
                round3 <=  inv_round(round2, round_key(11));
                round4 <=  inv_round(round3, round_key(10));
                round5 <=  inv_round(round4, round_key(9));
                round6 <=  inv_round(round5, round_key(8));
                round7 <=  inv_round(round6, round_key(7));
                round8 <=  inv_round(round7, round_key(6));
                round9 <=  inv_round(round8, round_key(5));
                round10 <= inv_round(round9, round_key(4));
                round11 <= inv_round(round10, round_key(3));
                round12 <= inv_round(round11, round_key(2));
                round13 <= inv_round(round12, round_key(1));
                pt_array <= add_round_key(inv_sub_bytes(inv_shift_rows(round13)), round_key(0));
            end if;
        end process;

        key_logic : process (i_clk)
        begin   
            if rising_edge(i_clk) then
                if i_reset_n = '0' then
                    key_rdy <= '0';
                    key_phase <= IDLE;
                else
                    case key_phase is
                        when IDLE =>
                            if key_load = '1' then
                                key_rdy <= '0'; 
                                key_hold <= cipherkey;
                                key_settle <= 0;
                                key_phase <= EXPANDING;
                            end if;
                        when EXPANDING =>          -- key_load ignored here
                            if key_settle = LATENCY - 1 then
                                round_key <= key_round(key_hold);
                                key_rdy   <= '1';
                                key_phase <= IDLE;
                            else
                                key_settle <= key_settle + 1;
                            end if;
                    end case;
                end if;
            end if;
        end process;


        reset : process (i_clk)
        begin
            if rising_edge(i_clk) then
                if i_reset_n = '0' then
                    plaintext <= (others => '0');
                    valid_sr   <= (others => '0');
                else
                    plaintext <= from_state(pt_array);
                    valid_sr   <= valid_sr(LATENCY - 2 downto 0) & (in_valid and key_rdy);
                end if;
            end if;
        end process;

        out_valid <= valid_sr(LATENCY - 1);


end architecture;

