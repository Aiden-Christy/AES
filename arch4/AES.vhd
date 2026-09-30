library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AES_pkg.all;

-------------------------------------------------------------------------------
-- AES-256, "as small as possible" version.
--
-- The other architectures build all 14 rounds as separate hardware, like a
-- factory with 14 workers standing in a line. This one hires ONE worker and
-- makes them do the job 14 times in a row, handing the result back to
-- themselves each time. It's ~14x slower per block, but ~14x less hardware.
--
-- Timeline for one block (one row = one clock cycle):
--   load    : grab plaintext + key
--   cnt = 0 : round 1  (uses round key k0)
--   cnt = 1 : round 2  (uses round key k1)
--   ...
--   cnt = 12: round 13 (uses round key k12)
--   cnt = 13: round 14 (uses k13 and k14) -> ciphertext is ready
-------------------------------------------------------------------------------

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

    ---------------------------------------------------------------------------
    -- Registers (flip-flops = the circuit's memory between clock ticks)
    ---------------------------------------------------------------------------
    signal state_reg : state_t;              -- the block we're scrambling, mid-way through
    signal rk        : state_t;              -- round key for THIS round
    signal rk_next   : state_t;              -- round key for the NEXT round
    signal cnt       : unsigned(3 downto 0); -- which round we're on (0 to 13)
    signal busy      : std_logic;            -- '1' while a block is being encrypted

    -- rk and rk_next together are the last 8 words of the key schedule. That
    -- is all the key memory we need: every new key word is built from words
    -- that are at most 8 spots back (see key_step in the package).

    ---------------------------------------------------------------------------
    -- Wire (combinational = just logic, recomputed instantly, no memory)
    ---------------------------------------------------------------------------
    signal t         : state_t;              -- state after AddRoundKey + SubBytes + ShiftRows

begin

    ---------------------------------------------------------------------------
    -- The ONE round unit. This is the expensive part (16 S-boxes), and there
    -- is only one copy of it in the whole design.
    --
    -- A normal round is:  AddRoundKey -> SubBytes -> ShiftRows -> MixColumns
    -- The last round is:  AddRoundKey -> SubBytes -> ShiftRows -> AddRoundKey
    --
    -- The first three steps are the same either way, so we do them once here
    -- (t), and the process below picks what happens at the end. That way
    -- round 14 doesn't need its own copy of the S-boxes.
    ---------------------------------------------------------------------------
    t <= shift_rows(sub_bytes(add_round_key(state_reg, rk)));

    ---------------------------------------------------------------------------
    -- Data registers. These have NO reset on purpose: their values don't
    -- matter until a block gets loaded, and on Xilinx FPGAs, flip-flops without
    -- a reset pack together more tightly (= less area).
    ---------------------------------------------------------------------------
    datapath : process (clk)
    begin
        if rising_edge(clk) then
            if busy = '0' then
                -- Waiting: keep loading whatever is on the inputs. It only
                -- "counts" once in_valid starts the control logic below.
                -- The key's top half is round key k0, the bottom half is k1.
                state_reg <= to_state(plaintext);
                rk        <= to_state(cipherkey(255 downto 128));
                rk_next   <= to_state(cipherkey(127 downto 0));
            else
                -- Working: finish the round with MixColumns and feed the
                -- result back into the round unit for next time.
                state_reg <= mix_columns(t);

                -- Slide the key conveyor belt forward one round key:
                -- rk_next moves up to become rk, and key_step builds a brand
                -- new rk_next. The key step flavour flips every round:
                -- counter even -> rotate flavour, odd -> no rotate.
                rk        <= rk_next;
                rk_next   <= key_step(rk, rk_next, rcon_for(cnt), not cnt(0));

                -- Last round: skip MixColumns and add the final round key
                -- (on this cycle rk = k13 and rk_next = k14).
                if cnt = 13 then
                    ciphertext <= from_state(add_round_key(t, rk_next));
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Control registers. busy and out_valid DO need a reset, so the circuit
    -- starts in a known "idle" state when it powers up. cnt doesn't: it gets
    -- set to 0 every time a block starts anyway.
    ---------------------------------------------------------------------------
    control : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                busy      <= '0';
                out_valid <= '0';
            else
                out_valid <= '0';            -- out_valid is a 1-cycle "done!" blip

                if busy = '0' then
                    -- Idle: start when a new block shows up.
                    if in_valid = '1' then
                        busy <= '1';
                        cnt  <= (others => '0');
                    end if;
                elsif cnt = 13 then
                    -- Just finished round 14: announce the result, go idle.
                    out_valid <= '1';
                    busy      <= '0';
                else
                    -- Middle of the job: move on to the next round.
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

end architecture;
