library ieee;
use ieee.std_logic_1164.all;
use work.AES_pkg.all;

entity AES_round_tb is
end entity AES_round_tb;

architecture sim of AES_round_tb is

    -- FIPS-197 Appendix B worked example (AES-128):
    --   plaintext  = 3243f6a8885a308d313198a2e0370734
    --   cipher key = 2b7e151628aed2a6abf7158809cf4f3c
    --       Both in 4x4 byte grids
    -- round1_state_in/round1_key are round 1's actual inputs (state after
    -- the initial AddRoundKey, and round key 1) -- not the raw plaintext or
    -- cipher key -- since that's what AES_round itself takes in.
    constant round1_state_in_tv : std_logic_vector(127 downto 0) := x"193de3bea0f4e22b9ac68d2ae9f84808";
    constant round1_key_tv      : std_logic_vector(127 downto 0) := x"a0fafe1788542cb123a339392a6c7605";

    -- values found the FIPS 197 appendix with comparitor tables to verify each 
    -- functions output
    constant golden_sub_bytes   : std_logic_vector(127 downto 0) := x"d42711aee0bf98f1b8b45de51e415230";
    constant golden_shift_rows  : std_logic_vector(127 downto 0) := x"d4bf5d30e0b452aeb84111f11e2798e5";
    constant golden_mix_columns : std_logic_vector(127 downto 0) := x"046681e5e0cb199a48f8d37a2806264c";
    constant golden_output      : std_logic_vector(127 downto 0) := x"a49c7ff2689f352b6b5bea43026a5049";

    -- DUT ports
    signal state_in  : state_t;
    signal round_key : state_t;
    signal state_out : state_t;

    -- mirrors of each step inside AES_round, computed straight from the
    -- AES_pkg functions so they can be watched individually in the waveform
    signal after_sub_bytes    : state_t;
    signal after_shift_rows   : state_t;
    signal after_mix_columns  : state_t;

begin

    dut : entity work.AES_round
        port map (
            state_in  => state_in,
            round_key => round_key,
            state_out => state_out
        );

    state_in  <= to_state(round1_state_in_tv);
    round_key <= to_state(round1_key_tv);

    after_sub_bytes   <= sub_bytes(state_in);
    after_shift_rows  <= shift_rows(after_sub_bytes);
    after_mix_columns <= mix_columns(after_shift_rows);

    check : process
    begin
        wait for 10 ns;

        if from_state(after_sub_bytes) = golden_sub_bytes then
            report "PASS: SubBytes matches FIPS-197 round-1 trace";
        else
            report "FAIL: SubBytes does not match FIPS-197 round-1 trace" severity error;
        end if;

        if from_state(after_shift_rows) = golden_shift_rows then
            report "PASS: ShiftRows matches FIPS-197 round-1 trace";
        else
            report "FAIL: ShiftRows does not match FIPS-197 round-1 trace" severity error;
        end if;

        if from_state(after_mix_columns) = golden_mix_columns then
            report "PASS: MixColumns matches FIPS-197 round-1 trace";
        else
            report "FAIL: MixColumns does not match FIPS-197 round-1 trace" severity error;
        end if;

        if from_state(state_out) = golden_output then
            report "PASS: AES_round output matches FIPS-197 round-1 trace";
        else
            report "FAIL: AES_round output does not match FIPS-197 round-1 trace" severity error;
        end if;

        report "AES_round_tb complete.";
        wait;
    end process check;

end architecture sim;
