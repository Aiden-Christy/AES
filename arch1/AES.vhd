library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AES_pkg.all;

entity AES is
port( 
    clk : in  std_logic;
    rst : in std_logic;

    in_valid : in std_logic;
    out_valid: out std_logic;

    plaintext : in std_logic_vector(127 downto 0);
    cipherkey : in std_logic_vector(255 downto 0);

    ciphertext : out std_logic_vector(127 downto 0)
);
end entity AES;

architecture AES_arch of AES is

    signal pt_array : state_t;
    signal ct_array : state_t;

    signal round_key : key_t;


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
    
        encrypt : process (clk)
        begin
            if rising_edge(clk) then
                round_key <= key_round(cipherkey);
    
                round1 <=  round(pt_array, round_key(0));
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

        reset : process (clk)
        begin 
            if rising_edge(clk) then   
                if rst = '1' then   
                    ciphertext <= (others => '0');
                else   
                    ciphertext <= from_state(ct_array);
                end if;
            end if;
        end process;


end architecture;