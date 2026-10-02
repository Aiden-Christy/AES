library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AES_pkg.all;

entity AES_tb is
end entity AES_tb;

architecture sim of AES_tb is

    -- FIPS-197 Appendix C.3 known-answer test (AES-256)
    constant plaintext_tv        : std_logic_vector(127 downto 0) := x"00112233445566778899aabbccddeeff";
    constant cipherkey_tv        : std_logic_vector(255 downto 0) := x"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
    constant expected_ciphertext : std_logic_vector(127 downto 0) := x"8ea2b7ca516745bfeafc49904b496089";

    constant clk_period : time := 31.25 ns;

    signal clk        : std_logic := '0';
    signal rst_n      : std_logic := '0';   -- active low
    signal in_valid   : std_logic := '0';
    signal out_valid  : std_logic;
    signal plaintext  : std_logic_vector(127 downto 0) := (others => '0');
    signal cipherkey  : std_logic_vector(255 downto 0) := (others => '0');
    signal ciphertext : std_logic_vector(127 downto 0);

begin

    dut : entity work.AES
        port map (
            i_clk      => clk,
            i_reset_n  => rst_n,
            in_valid   => in_valid,
            out_valid  => out_valid,
            plaintext  => plaintext,
            cipherkey  => cipherkey,
            ciphertext => ciphertext
        );

    clk <= not clk after clk_period / 2;

    check : process
    begin
        rst_n <= '0';
        wait for clk_period;

        -- the whole cipher is combinational off plaintext/cipherkey, so it
        -- settles within this same simulation time; the next rising edge
        -- is enough for AES.vhd's "reset" process to latch it into ciphertext
        plaintext <= plaintext_tv;
        cipherkey <= cipherkey_tv;
        in_valid  <= '1';
        rst_n     <= '1';
        wait for clk_period * 20;

        if ciphertext = expected_ciphertext then
            report "PASS: AES ciphertext matches FIPS-197 Appendix C.3 known-answer test";
        else
            report "FAIL: AES ciphertext does not match FIPS-197 Appendix C.3 known-answer test" severity error;
        end if;

        assert false
            report "AES_tb complete -- stopping simulation."
            severity failure;
        wait;
    end process check;

end architecture sim;
