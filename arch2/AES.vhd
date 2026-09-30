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


    begin
        
        pt_array <= to_state(plaintext);
        round_key <= key_round(cipherkey);
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