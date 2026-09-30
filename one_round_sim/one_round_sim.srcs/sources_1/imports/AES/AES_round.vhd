library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AES_pkg.all;

entity AES_round is
    port(
        state_in : in state_t;
        round_key : in state_t;

        state_out : out state_t
);
end entity AES_round;

architecture AES_round_arch of AES_round is

    begin
        state_out <= add_round_key(mix_columns(shift_rows(sub_bytes(state_in))), round_key);

end architecture;