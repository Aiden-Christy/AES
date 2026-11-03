library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package decrypt_pkg is

    subtype byte_t is std_logic_vector(7 downto 0);
    type word_t is array(0 to 3) of byte_t;
    type state_t is array(0 to 3) of word_t;

    type key_t is array(0 to 14) of state_t;
    
    type sbox_t is array(0 to 255) of byte_t;
    type rcon_table_t is array(1 to 10) of byte_t;

    function to_state(pt : std_logic_vector(127 downto 0)) return state_t;
    function from_state(s : state_t) return std_logic_vector;

    function key_round(key : std_logic_vector(255 downto 0)) return key_t;

    function add_round_key(s : state_t; rk : state_t) return state_t;
    function inv_sub_bytes(s : state_t) return state_t;
    function inv_shift_rows(s : state_t) return state_t;
    function inv_mix_columns(s : state_t) return state_t;
    function inv_round(s : state_t; rk : state_t) return state_t;


end package decrypt_pkg;

package body decrypt_pkg is

    constant inv_sbox : sbox_t := (
        x"52", x"09", x"6a", x"d5", x"30", x"36", x"a5", x"38", x"bf", x"40", x"a3", x"9e", x"81", x"f3", x"d7", x"fb", -- row 0
        x"7c", x"e3", x"39", x"82", x"9b", x"2f", x"ff", x"87", x"34", x"8e", x"43", x"44", x"c4", x"de", x"e9", x"cb", -- row 1
        x"54", x"7b", x"94", x"32", x"a6", x"c2", x"23", x"3d", x"ee", x"4c", x"95", x"0b", x"42", x"fa", x"c3", x"4e", -- row 2
        x"08", x"2e", x"a1", x"66", x"28", x"d9", x"24", x"b2", x"76", x"5b", x"a2", x"49", x"6d", x"8b", x"d1", x"25", -- row 3
        x"72", x"f8", x"f6", x"64", x"86", x"68", x"98", x"16", x"d4", x"a4", x"5c", x"cc", x"5d", x"65", x"b6", x"92", -- row 4
        x"6c", x"70", x"48", x"50", x"fd", x"ed", x"b9", x"da", x"5e", x"15", x"46", x"57", x"a7", x"8d", x"9d", x"84", -- row 5
        x"90", x"d8", x"ab", x"00", x"8c", x"bc", x"d3", x"0a", x"f7", x"e4", x"58", x"05", x"b8", x"b3", x"45", x"06", -- row 6
        x"d0", x"2c", x"1e", x"8f", x"ca", x"3f", x"0f", x"02", x"c1", x"af", x"bd", x"03", x"01", x"13", x"8a", x"6b", -- row 7
        x"3a", x"91", x"11", x"41", x"4f", x"67", x"dc", x"ea", x"97", x"f2", x"cf", x"ce", x"f0", x"b4", x"e6", x"73", -- row 8
        x"96", x"ac", x"74", x"22", x"e7", x"ad", x"35", x"85", x"e2", x"f9", x"37", x"e8", x"1c", x"75", x"df", x"6e", -- row 9
        x"47", x"f1", x"1a", x"71", x"1d", x"29", x"c5", x"89", x"6f", x"b7", x"62", x"0e", x"aa", x"18", x"be", x"1b", -- row a
        x"fc", x"56", x"3e", x"4b", x"c6", x"d2", x"79", x"20", x"9a", x"db", x"c0", x"fe", x"78", x"cd", x"5a", x"f4", -- row b
        x"1f", x"dd", x"a8", x"33", x"88", x"07", x"c7", x"31", x"b1", x"12", x"10", x"59", x"27", x"80", x"ec", x"5f", -- row c
        x"60", x"51", x"7f", x"a9", x"19", x"b5", x"4a", x"0d", x"2d", x"e5", x"7a", x"9f", x"93", x"c9", x"9c", x"ef", -- row d
        x"a0", x"e0", x"3b", x"4d", x"ae", x"2a", x"f5", x"b0", x"c8", x"eb", x"bb", x"3c", x"83", x"53", x"99", x"61", -- row e
        x"17", x"2b", x"04", x"7e", x"ba", x"77", x"d6", x"26", x"e1", x"69", x"14", x"63", x"55", x"21", x"0c", x"7d"  -- row f
    );

    constant sbox : sbox_t := (
        -- sbox(row*16 + col) = S-box output for input byte 0x<row><col>
    -- col:0      1      2      3      4      5      6      7      8      9      a      b      c      d      e      f
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

    function rot_word(w : word_t) return word_t is
        variable result : word_t;
    begin
        result(0) := w(1);
        result(1) := w(2);
        result(2) := w(3);
        result(3) := w(0);
        return result;
    end function;

    function sub_byte(val : byte_t) return byte_t is
    begin
        return sbox(to_integer(unsigned(val)));
    end function;

    function sub_word(w : word_t) return word_t is
        variable result : word_t;
    begin
        for i in 0 to 3 loop
            result(i) := sub_byte(w(i));
        end loop;
        return result;
    end function;


    function key_round(key : std_logic_vector(255 downto 0)) return key_t is
        constant Nk : integer := 8;                    
        constant Nb : integer := 4;                     
        constant Nr : integer := 14;                     
        type word_array_t is array(0 to Nb*(Nr+1) - 1) of word_t;

        variable w      : word_array_t;
        variable temp   : word_t;
        variable key_hi : state_t := to_state(key(255 downto 128));
        variable key_lo : state_t := to_state(key(127 downto 0));
        variable result : key_t;
    begin
        
        for c in 0 to 3 loop
            w(c)     := key_hi(c);
            w(c + 4) := key_lo(c);
        end loop;

        for i in Nk to Nb*(Nr+1) - 1 loop
            temp := w(i - 1);

            if i mod Nk = 0 then
                temp    := sub_word(rot_word(temp));
                temp(0) := temp(0) xor rcon(i / Nk);
            elsif i mod Nk = 4 then
                temp := sub_word(temp);
            end if;

            for b in 0 to 3 loop
                w(i)(b) := w(i - Nk)(b) xor temp(b);
            end loop;
        end loop;

        for r in 0 to Nr loop
            for c in 0 to Nb - 1 loop
                result(r)(c) := w(4*r + c);
            end loop;
        end loop;

        return result;
    end function;

    function inv_sub_byte(val : byte_t) return byte_t is
    begin
        return inv_sbox(to_integer(unsigned(val)));
    end function;

    function inv_sub_bytes(s : state_t) return state_t is
        variable result : state_t;
    begin
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                result(c)(r) := inv_sub_byte(s(c)(r));
            end loop;
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

    function inv_shift_rows(s : state_t) return state_t is  
        variable result : state_t;
    begin 
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                result(c)(r) := s((c - r) mod 4)(r);
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

    -- 09 = 8 + 1 (8 = 2^3)
    function mul09(b : byte_t) return byte_t is  
        variable x2, x4, x8 : byte_t;
    begin 
        x2 := xtime(b);
        x4 := xtime(x2);
        x8 := xtime(x4);
        return x8 xor b;
    end function;

    -- 0b = 8 + 2 + 1 
    function mul0b(b : byte_t) return byte_t is
        variable x2, x4, x8 : byte_t;
    begin
        x2 := xtime(b);
        x4 := xtime(x2);
        x8 := xtime(x4);
        return x8 xor x2 xor b;
    end function;

    -- 0d = 8 + 4 + 1
    function mul0d(b : byte_t) return byte_t is
        variable x2, x4, x8 : byte_t;
    begin
        x2 := xtime(b);
        x4 := xtime(x2);
        x8 := xtime(x4);
        return x8 xor x4 xor b;
    end function;

    -- 0e = 8 + 4 + 2
    function mul0e(b : byte_t) return byte_t is
        variable x2, x4, x8 : byte_t;
    begin
        x2 := xtime(b);
        x4 := xtime(x2);
        x8 := xtime(x4);
        return x8 xor x4 xor x2;
    end function;

    function inv_mix_columns(s : state_t) return state_t is 
        variable result : state_t;
    begin 
        for c in 0 to 3 loop 
            result(c)(0) := mul0e(s(c)(0)) xor mul0b(s(c)(1)) xor mul0d(s(c)(2)) xor mul09(s(c)(3));
            result(c)(1) := mul09(s(c)(0)) xor mul0e(s(c)(1)) xor mul0b(s(c)(2)) xor mul0d(s(c)(3));
            result(c)(2) := mul0d(s(c)(0)) xor mul09(s(c)(1)) xor mul0e(s(c)(2)) xor mul0b(s(c)(3));
            result(c)(3) := mul0b(s(c)(0)) xor mul0d(s(c)(1)) xor mul09(s(c)(2)) xor mul0e(s(c)(3));
        end loop;
        return result;
    end function;

    function inv_round(s : state_t; rk : state_t) return state_t is
        variable result : state_t;
    begin 
        result := inv_mix_columns(add_round_key(inv_sub_bytes(inv_shift_rows(s)), rk));
        return result;
    end function;

end package body decrypt_pkg;