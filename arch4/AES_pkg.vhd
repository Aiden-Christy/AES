library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package AES_pkg is

    subtype byte_t is std_logic_vector(7 downto 0);
    type word_t is array(0 to 3) of byte_t;
    type state_t is array(0 to 3) of word_t;

    type sbox_t is array(0 to 255) of byte_t;
    type rcon_table_t is array(1 to 10) of byte_t;

    function to_state(pt : std_logic_vector(127 downto 0)) return state_t;
    function from_state(s : state_t) return std_logic_vector;

    function sub_byte(val : byte_t) return byte_t;
    function sub_bytes(s : state_t) return state_t;
    function rot_word(w : word_t) return word_t;
    function sub_word(w : word_t) return word_t;
    function shift_rows(s : state_t) return state_t;
    function mix_columns(s : state_t) return state_t;
    function add_round_key(s : state_t; rk : state_t) return state_t;

    function word_xor(a : word_t; b : word_t) return word_t;
    function key_step(rk : state_t; rk_next : state_t; rcon_byte : byte_t; use_rot : std_logic) return state_t;
    function rcon_for(cnt : unsigned(3 downto 0)) return byte_t;

end package AES_pkg;

package body AES_pkg is

    
    constant sbox : sbox_t := (
        -- sbox(row*16 + col) = S-box output for input byte 0x<row><col>
        -- col:     0      1      2      3      4      5      6      7      8      9      a      b      c      d      e      f
        x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76", -- row 0
        x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0", -- row 1
        x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15", -- row 2
        x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75", -- row 3
        x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84", -- row 4
        x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf", -- row 5
        x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8", -- row 6
        x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2", -- row 7
        x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73", -- row 8
        x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db", -- row 9
        x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79", -- row a
        x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08", -- row b
        x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a", -- row c
        x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e", -- row d
        x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df", -- row e
        x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16"  -- row f
    );

    constant rcon : rcon_table_t := (
        x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1b", x"36"
    );

    function to_state(pt : std_logic_vector(127 downto 0)) return state_t is
        variable s : state_t;
    begin
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                s(c)(r) := pt(127 - 8*(r + 4*c) downto 120 - 8*(r + 4*c));
            end loop;
        end loop;
        return s;
    end function;

    function from_state(s : state_t) return std_logic_vector is 
        variable pt : std_logic_vector(127 downto 0);
    begin  
        for c in 0 to 3 loop 
            for r in 0 to 3 loop
                pt(127 - 8*(r + 4*c) downto 120 - 8*(r + 4*c)) := s(c)(r);
            end loop;
        end loop;
        return pt;
    end function;

    function sub_byte(val : byte_t) return byte_t is
    begin
        return sbox(to_integer(unsigned(val)));
    end function;
 
    function sub_bytes(s : state_t) return state_t is
        variable result : state_t;
    begin
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                result(c)(r) := sub_byte(s(c)(r));
            end loop;
        end loop;
        return result;
    end function;

    function rot_word(w : word_t) return word_t is
        variable result : word_t;
    begin
        result(0) := w(1);
        result(1) := w(2);
        result(2) := w(3);
        result(3) := w(0);
        return result;
    end function;

    function sub_word(w : word_t) return word_t is
        variable result : word_t;
    begin
        for i in 0 to 3 loop
            result(i) := sub_byte(w(i));
        end loop;
        return result;
    end function;

    function shift_rows(s : state_t) return state_t is  
        variable result : state_t;
    begin 
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                result(c)(r) := s((c + r) mod 4)(r);
            end loop;
        end loop;
        return result;
    end function;

    function xtime(b : byte_t) return byte_t is
        variable sh : byte_t;
    begin
        sh := b(6 downto 0) & '0';
        if b(7) = '1' then
            return sh xor x"1b";
        else
            return sh;
        end if;
    end function;

    function mix_columns(s : state_t) return state_t is 
        variable result : state_t;
    begin 
        for c in 0 to 3 loop 
            result(c)(0) := xtime(s(c)(0)) xor (xtime(s(c)(1)) xor s(c)(1)) xor s(c)(2) xor s(c)(3);
            result(c)(1) := s(c)(0) xor xtime(s(c)(1)) xor (xtime(s(c)(2)) xor s(c)(2)) xor s(c)(3);
            result(c)(2) := s(c)(0) xor s(c)(1) xor xtime(s(c)(2)) xor (xtime(s(c)(3)) xor s(c)(3));
            result(c)(3) := (xtime(s(c)(0)) xor s(c)(0)) xor s(c)(1) xor s(c)(2) xor xtime(s(c)(3));
        end loop;
        return result;
    end function;

    function add_round_key(s : state_t; rk : state_t) return state_t is
        variable result : state_t;
    begin
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                result(c)(r) := s(c)(r) xor rk(c)(r);
            end loop;
        end loop;
        return result;
    end function;



    -- XOR two 4-byte words together, byte by byte.
    -- (XOR = "flip the bits of a wherever b has a 1")
    function word_xor(a : word_t; b : word_t) return word_t is
        variable result : word_t;
    begin
        for i in 0 to 3 loop
            result(i) := a(i) xor b(i);
        end loop;
        return result;
    end function;


    -- One step of the AES-256 key schedule, done "on the fly".
    --
    -- The big idea: the full key schedule makes all 60 words at once, which
    -- needs a LOT of hardware. But every new word only ever looks back at most
    -- 8 words. So if we just remember the last 8 words (two round keys: rk and
    -- rk_next), we can make the next 4 words each clock cycle - exactly one
    -- round key's worth - and throw away the old ones we don't need anymore.
    --
    -- Think of it like a conveyor belt 8 boxes long: every tick, the 4 oldest
    -- boxes (rk) fall off the front, the other 4 (rk_next) slide forward, and
    -- the 4 brand new boxes this function makes get put on the back.
    --
    -- The rule from the AES standard is:  w[i] = w[i-8] xor temp
    --   - For the FIRST new word, temp is a scrambled copy of the newest word
    --     we have (the last word of rk_next).
    --   - For the other 3 new words, temp is just the word right before it.
    --
    -- How that newest word gets scrambled alternates every step:
    --   - use_rot = '1': rotate the bytes, run them through the S-box, then
    --     XOR in the round constant (rcon_byte).
    --   - use_rot = '0': S-box only.
    function key_step(rk : state_t; rk_next : state_t; rcon_byte : byte_t; use_rot : std_logic) return state_t is
        variable t : word_t;
        variable r : state_t;
    begin
        -- Start with the newest word we have.
        t := rk_next(3);

        -- Rotate it only on the steps that need it. We pick rotated vs. not
        -- BEFORE the S-box so that only ONE sub_word (4 S-boxes) gets built
        -- in hardware, instead of one for each case.
        if use_rot = '1' then
            t := rot_word(t);
        end if;

        -- Run all 4 bytes through the S-box (the AES "substitution" table).
        t := sub_word(t);

        -- On rotate steps, also mix in the round constant. It only touches
        -- the first byte - it's there so every step is a little different.
        if use_rot = '1' then
            t(0) := t(0) xor rcon_byte;
        end if;

        -- Make the 4 new words. Each one is
        -- "the word 8 spots back" XOR "the word right before me".
        r(0) := word_xor(rk(0), t);      -- w[i]   = w[i-8] xor temp
        r(1) := word_xor(rk(1), r(0));   -- w[i+1] = w[i-7] xor w[i]
        r(2) := word_xor(rk(2), r(1));   -- w[i+2] = w[i-6] xor w[i+1]
        r(3) := word_xor(rk(3), r(2));   -- w[i+3] = w[i-5] xor w[i+2]

        return r;
    end function;


    -- Which round constant to use, worked out from the round counter.
    -- The constant only changes every OTHER round (it's only used on the
    -- rotate steps), so we chop off the counter's lowest bit - that's the
    -- same as dividing by 2 - and look it up in the rcon table:
    --   cnt 0,1 -> rcon(1) = 01,  cnt 2,3 -> rcon(2) = 02,  ...  cnt 12,13 -> rcon(7) = 40
    -- This is a tiny lookup instead of an 8-bit register that has to be
    -- loaded and shifted.
    function rcon_for(cnt : unsigned(3 downto 0)) return byte_t is
    begin
        return rcon(to_integer(cnt(3 downto 1)) + 1);
    end function;

end package body AES_pkg;
