library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AES_pkg.all;

-------------------------------------------------------------------------------
-- Hardware test harness for the AES cores (synthesizable, for use with an ILA).
--
-- Loops forever through the key groups below. For each key:
--   LOAD_KEY   : put the key on cipherkey
--   SETTLE_KEY : hold it KEY_MCP clocks, then pulse key_load (see KEY_MCP)
--   WAIT_KEY   : wait for the core's key_valid (key schedule expanded)
--   SEND     : stream that key's plaintexts back to back, one per clock
--   DRAIN    : wait until every block has come out (out_valid count), so no
--              block is still in the pipeline when the next key is loaded
--
-- What to look for in the ILA:
--   key_load  -> key_valid  : key schedule loaded (1 clock)
--   in_valid  -> out_valid  : block latency (16 clocks)
--   group 1 (4 plaintexts, same key): out_valid high 4 clocks in a row with a
--   new correct ciphertext each clock = one block per clock throughput
--   group 0 -> 1 -> 2 : key changes, each group still gives the right answer
--
-- To swap architectures, change the entity name at the "dut" instance below.
--
-- ILA probes (marked with MARK_DEBUG, so Vivado's "Set Up Debug" finds them):
--   key_idx, pt_idx, key_load, key_valid, in_valid, out_valid, ciphertext
-------------------------------------------------------------------------------

entity AES_testbench is
port(
    i_clk     : in std_logic;
    i_reset_n : in std_logic      -- active low
);
end entity AES_testbench;

architecture harness of AES_testbench is

    ---------------------------------------------------------------------------
    -- Known-answer vectors, grouped by key (expected ciphertext in comments)
    ---------------------------------------------------------------------------
    constant NUM_KEYS : natural := 3;
    constant NUM_PTS  : natural := 6;

    type key_array_t   is array (0 to NUM_KEYS - 1) of std_logic_vector(255 downto 0);
    type block_array_t is array (0 to NUM_PTS - 1) of std_logic_vector(127 downto 0);
    type pt_index_t    is array (0 to NUM_KEYS - 1) of natural range 0 to NUM_PTS - 1;

    constant KEYS : key_array_t := (
        0 => x"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",  -- FIPS 197 App. C.3
        1 => x"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",  -- SP 800-38A F.1.5
        2 => x"c47b0294dbbbee0fec4757f22ffeee3587ca4730c3d33b691df38bab076bc558"   -- AESAVS KeySbox, 256-bit, first entry
    );

    constant PLAINTEXTS : block_array_t := (
        -- key 0
        0 => x"00112233445566778899aabbccddeeff",  -- expect 8ea2b7ca516745bfeafc49904b496089
        -- key 1
        1 => x"6bc1bee22e409f96e93d7e117393172a",  -- expect f3eed1bdb5d2a03c064b5a7e3db181f8
        2 => x"ae2d8a571e03ac9c9eb76fac45af8e51",  -- expect 591ccb10d410ed26dc5ba74a31362870
        3 => x"30c81c46a35ce411e5fbc1191a0a52ef",  -- expect b6ed21b99ca6f4f9f153e7b1beafed1d
        4 => x"f69f2445df4f9b17ad2b417be66c3710",  -- expect 23304b7a39f9f3ff067d8d8f9e24ecc7
        -- key 2
        5 => x"00000000000000000000000000000000"   -- expect 46f2fb342d6f0ab477476fc501242c5f
    );

    -- which plaintexts go with each key
    constant FIRST_PT : pt_index_t := (0 => 0, 1 => 1, 2 => 5);
    constant LAST_PT  : pt_index_t := (0 => 0, 1 => 4, 2 => 5);

    -- The core's key expansion (key_reg -> dut/round_key) is a long
    -- combinational path that only runs on a key load, so the XDC gives it
    -- KEY_MCP clocks with set_multicycle_path. That constraint is only true
    -- if key_reg is stable for KEY_MCP clocks before key_load is sampled,
    -- which SETTLE_KEY guarantees. Keep this equal to -setup in the XDC.
    constant KEY_MCP : natural := 16;

    ---------------------------------------------------------------------------
    -- Harness state
    ---------------------------------------------------------------------------
    type phase_t is (LOAD_KEY, SETTLE_KEY, WAIT_KEY, SEND, DRAIN);
    signal phase : phase_t := LOAD_KEY;

    signal key_idx    : integer range 0 to NUM_KEYS - 1 := 0;
    signal pt_idx     : integer range 0 to NUM_PTS - 1 := 0;
    signal rx_cnt     : integer range 0 to NUM_PTS - 1 := 0;  -- blocks received this group
    signal settle_cnt : integer range 0 to KEY_MCP - 1 := 0;
    signal key_reg    : std_logic_vector(255 downto 0);
    signal pt_reg     : std_logic_vector(127 downto 0);

    signal key_load   : std_logic := '0';
    signal key_valid  : std_logic;
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
    attribute mark_debug of key_idx    : signal is "true";
    attribute mark_debug of pt_idx     : signal is "true";
    attribute mark_debug of key_load   : signal is "true";
    attribute mark_debug of key_valid  : signal is "true";
    attribute mark_debug of in_valid   : signal is "true";
    attribute mark_debug of out_valid  : signal is "true";
    attribute mark_debug of ciphertext : signal is "true";

begin

    ---------------------------------------------------------------------------
    -- Core under test: change "AES" here to pick the architecture
    ---------------------------------------------------------------------------
    dut : entity work.AES
        port map (
            i_clk      => i_clk,
            i_reset_n  => i_reset_n,
            key_load   => key_load,
            key_valid  => key_valid,
            in_valid   => in_valid,
            out_valid  => out_valid,
            plaintext  => pt_reg,
            cipherkey  => key_reg,
            ciphertext => ciphertext
        );

    ---------------------------------------------------------------------------
    -- Vector sequencer
    ---------------------------------------------------------------------------
    sequencer : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset_n = '0' then
                phase    <= LOAD_KEY;
                key_idx  <= 0;
                pt_idx   <= 0;
                rx_cnt   <= 0;
                key_load <= '0';
                in_valid <= '0';
            else
                case phase is
                    when LOAD_KEY =>
                        key_reg    <= KEYS(key_idx);
                        pt_idx     <= FIRST_PT(key_idx);
                        rx_cnt     <= 0;
                        settle_cnt <= 0;
                        phase      <= SETTLE_KEY;

                    when SETTLE_KEY =>
                        -- key_reg changed KEY_MCP clocks before the edge where
                        -- the core samples this key_load
                        if settle_cnt = KEY_MCP - 2 then
                            key_load <= '1';
                            phase    <= WAIT_KEY;
                        else
                            settle_cnt <= settle_cnt + 1;
                        end if;

                    when WAIT_KEY =>
                        key_load <= '0';

                        -- on the first cycle here the core hasn't seen key_load
                        -- yet, so key_valid is still high from the previous key;
                        -- key_load = '1' marks that cycle
                        if key_load = '0' and key_valid = '1' then
                            phase <= SEND;
                        end if;

                    when SEND =>
                        -- one plaintext per clock, in_valid held high
                        pt_reg   <= PLAINTEXTS(pt_idx);
                        in_valid <= '1';

                        if pt_idx = LAST_PT(key_idx) then
                            phase <= DRAIN;
                        else
                            pt_idx <= pt_idx + 1;
                        end if;

                    when DRAIN =>
                        in_valid <= '0';

                        -- the first block takes 16 clocks to come out, longer
                        -- than any group takes to send, so every out_valid
                        -- lands here
                        if out_valid = '1' then
                            if rx_cnt = LAST_PT(key_idx) - FIRST_PT(key_idx) then
                                if key_idx = NUM_KEYS - 1 then
                                    key_idx <= 0;
                                else
                                    key_idx <= key_idx + 1;
                                end if;
                                phase <= LOAD_KEY;
                            else
                                rx_cnt <= rx_cnt + 1;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

end architecture harness;
