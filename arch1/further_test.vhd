library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AES_pkg.all;

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
    constant NUM_PTS  : natural := 4;

    
    type block_array_t is array (0 to NUM_PTS - 1) of std_logic_vector(127 downto 0);

    constant KEY : std_logic_vector := x"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4";  -- SP 800-38A F.1.5


    constant PLAINTEXTS : block_array_t := (
        -- key 1
        1 => x"6bc1bee22e409f96e93d7e117393172a",  -- expect f3eed1bdb5d2a03c064b5a7e3db181f8
        2 => x"ae2d8a571e03ac9c9eb76fac45af8e51",  -- expect 591ccb10d410ed26dc5ba74a31362870
        3 => x"30c81c46a35ce411e5fbc1191a0a52ef",  -- expect b6ed21b99ca6f4f9f153e7b1beafed1d
        4 => x"f69f2445df4f9b17ad2b417be66c3710"  -- expect 23304b7a39f9f3ff067d8d8f9e24ecc7
    );


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

    sequencer : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset_n = '0' then
                phase    <= LOAD_KEY;
                pt_idx   <= 0;
                rx_cnt   <= 0;
                key_load <= '0';
                in_valid <= '0';
            else
                case phase is
                    when LOAD_KEY =>
                        key_reg    <= KEY;
                        pt_idx     <= 0;
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

                        if pt_idx = NUM_PTS - 1 then
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
                            if rx_cnt = NUM_PTS - 1 then
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
