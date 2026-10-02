library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AES_pkg.all;

-------------------------------------------------------------------------------
-- Hardware test harness for the AES cores (synthesizable, for use with an ILA).
--
-- Loops forever through the known-answer vectors below:
--   LOAD : put vector[idx] into the key/plaintext registers, pulse in_valid
--   WAIT : wait for the core's out_valid, then idx <= idx + 1
--
-- To swap architectures, change the entity name at the "dut" instance below.
--
-- ILA probes (marked with MARK_DEBUG, so Vivado's "Set Up Debug" finds them):
--   vec_idx, in_valid, out_valid, ciphertext
-------------------------------------------------------------------------------

entity AES_testbench is
port(
    i_clk : in std_logic;
    rst : in std_logic      -- active high
);
end entity AES_testbench;

architecture harness of AES_testbench is

    ---------------------------------------------------------------------------
    -- Known-answer vectors (expected ciphertext listed in comments)
    ---------------------------------------------------------------------------
    constant NUM_VECTORS : natural := 6;

    type key_array_t   is array (0 to NUM_VECTORS - 1) of std_logic_vector(255 downto 0);
    type block_array_t is array (0 to NUM_VECTORS - 1) of std_logic_vector(127 downto 0);

    constant KEYS : key_array_t := (
        0 => x"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",  -- FIPS 197 App. C.3
        1 => x"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",  -- SP 800-38A F.1.5, block 1
        2 => x"c47b0294dbbbee0fec4757f22ffeee3587ca4730c3d33b691df38bab076bc558",  -- AESAVS KeySbox, 256-bit, first entry
        3 => x"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",  -- SP 800-38A F.1.5, block 2
        4 => x"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",  -- SP 800-38A F.1.5, block 3
        5 => x"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"   -- SP 800-38A F.1.5, block 4
    );

    constant PLAINTEXTS : block_array_t := (
        0 => x"00112233445566778899aabbccddeeff",  -- expect 8ea2b7ca516745bfeafc49904b496089
        1 => x"6bc1bee22e409f96e93d7e117393172a",  -- expect f3eed1bdb5d2a03c064b5a7e3db181f8
        2 => x"00000000000000000000000000000000",  -- expect 46f2fb342d6f0ab477476fc501242c5f
        3 => x"ae2d8a571e03ac9c9eb76fac45af8e51",  -- expect 591ccb10d410ed26dc5ba74a31362870
        4 => x"30c81c46a35ce411e5fbc1191a0a52ef",  -- expect b6ed21b99ca6f4f9f153e7b1beafed1d
        5 => x"f69f2445df4f9b17ad2b417be66c3710"   -- expect 23304b7a39f9f3ff067d8d8f9e24ecc7
    );

    ---------------------------------------------------------------------------
    -- Harness state
    ---------------------------------------------------------------------------
    type phase_t is (LOAD, WAIT_DONE);
    signal phase : phase_t := LOAD;

    signal vec_idx    : integer range 0 to NUM_VECTORS - 1 := 0;
    signal key_reg    : std_logic_vector(255 downto 0);
    signal pt_reg     : std_logic_vector(127 downto 0);

    signal in_valid   : std_logic := '0';
    signal out_valid  : std_logic;
    signal ciphertext : std_logic_vector(127 downto 0);

    ---------------------------------------------------------------------------
    -- Anti-trimming: without these, synthesis sees that many key/plaintext
    -- bits are the same in every vector, turns them into constants, and folds
    -- them into the cipher logic. Keep the registers and the core boundary.
    ---------------------------------------------------------------------------
    attribute dont_touch : string;
    attribute dont_touch of key_reg : signal is "true";
    attribute dont_touch of pt_reg  : signal is "true";

    attribute keep_hierarchy : string;
    attribute keep_hierarchy of dut : label is "yes";

    attribute mark_debug : string;
    attribute mark_debug of vec_idx    : signal is "true";
    attribute mark_debug of in_valid   : signal is "true";
    attribute mark_debug of out_valid  : signal is "true";
    attribute mark_debug of ciphertext : signal is "true";

begin

    ---------------------------------------------------------------------------
    -- Core under test: change "AES" here to pick the architecture
    ---------------------------------------------------------------------------
    dut : entity work.AES
        port map (
            clk        => clk,
            rst        => rst,
            in_valid   => in_valid,
            out_valid  => out_valid,
            plaintext  => pt_reg,
            cipherkey  => key_reg,
            ciphertext => ciphertext
        );

    ---------------------------------------------------------------------------
    -- Vector sequencer
    ---------------------------------------------------------------------------
    sequencer : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                phase    <= LOAD;
                vec_idx  <= 0;
                in_valid <= '0';
            else
                case phase is
                    when LOAD =>
                        -- inputs and in_valid go up together, so they are
                        -- stable on the edge where the core samples them
                        key_reg  <= KEYS(vec_idx);
                        pt_reg   <= PLAINTEXTS(vec_idx);
                        in_valid <= '1';
                        phase    <= WAIT_DONE;

                    when WAIT_DONE =>
                        in_valid <= '0';

                        if out_valid = '1' then
                            if vec_idx = NUM_VECTORS - 1 then
                                vec_idx <= 0;
                            else
                                vec_idx <= vec_idx + 1;
                            end if;
                            phase <= LOAD;
                        end if;
                end case;
            end if;
        end if;
    end process;

end architecture harness;
